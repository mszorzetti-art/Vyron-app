import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_access_storage.dart';
import 'vyron_access_rules.dart';

@immutable
class VyronAccessControllerState {
  const VyronAccessControllerState({
    required this.session,
    this.isHydrating = true,
    this.isVerifying = false,
  });

  final VyronAccessSession session;
  final bool isHydrating;
  final bool isVerifying;

  bool get isAuthorized => session.isAuthorized;

  VyronAccessControllerState copyWith({
    VyronAccessSession? session,
    bool? isHydrating,
    bool? isVerifying,
  }) {
    return VyronAccessControllerState(
      session: session ?? this.session,
      isHydrating: isHydrating ?? this.isHydrating,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

@immutable
class AccessLoginResult {
  const AccessLoginResult({
    required this.ok,
    required this.wasLocked,
    this.errorCode,
  });

  final bool ok;
  final bool wasLocked;
  final AccessErrorCode? errorCode;
}

@immutable
class AccessPasswordChangeResult {
  const AccessPasswordChangeResult({
    required this.ok,
    this.errorCode,
  });

  final bool ok;
  final AccessErrorCode? errorCode;
}

final vyronAccessStorageProvider = Provider<VyronAccessStorage>(
  (ref) => FlutterSecureAccessStorage(),
);

final vyronAccessProvider =
    StateNotifierProvider<VyronAccessNotifier, VyronAccessControllerState>(
  (ref) {
    final notifier = VyronAccessNotifier(
      storage: ref.watch(vyronAccessStorageProvider),
    );
    unawaited(notifier.hydrate());
    return notifier;
  },
);

class VyronAccessNotifier extends StateNotifier<VyronAccessControllerState> {
  VyronAccessNotifier({
    required VyronAccessStorage storage,
    int Function()? nowMs,
    this.pbkdf2Iterations = defaultPbkdf2Iterations,
  })  : _storage = storage,
        _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch),
        super(
          VyronAccessControllerState(
            session: VyronAccessSession.initial(),
            isHydrating: true,
          ),
        ) {
    _lastTouchMs = _nowMs();
  }

  final VyronAccessStorage _storage;
  final int Function() _nowMs;
  final int pbkdf2Iterations;

  late int _lastTouchMs;

  Future<void> hydrate() async {
    final loaded = await _storage.loadSession();
    final evaluated = evaluatePersistedSession(loaded, _nowMs());
    if (!mounted) return;
    _lastTouchMs = _nowMs();
    state = state.copyWith(
      session: evaluated,
      isHydrating: false,
    );
    await _storage.saveSession(evaluated);
  }

  Future<AccessLoginResult> login(String password) async {
    final current = state.session;
    if (password.trim().isEmpty) {
      return AccessLoginResult(
        ok: false,
        wasLocked: current.locked,
        errorCode: AccessErrorCode.emptyPassword,
      );
    }

    state = state.copyWith(isVerifying: true);
    final valid = await verifyAccessCredentialAsync(password, current.verifier);
    if (!mounted) {
      return AccessLoginResult(ok: false, wasLocked: current.locked);
    }

    if (!valid) {
      state = state.copyWith(isVerifying: false);
      return AccessLoginResult(
        ok: false,
        wasLocked: current.locked,
        errorCode: AccessErrorCode.wrongPassword,
      );
    }

    final upgraded = await upgradeSessionToPbkdf2IfLegacy(
      current,
      password,
      iterations: pbkdf2Iterations,
    );
    if (!mounted) {
      return AccessLoginResult(ok: false, wasLocked: current.locked);
    }

    final now = _nowMs();
    _lastTouchMs = now;
    final authenticatedSession = buildAuthenticatedSession(upgraded, now);
    state = state.copyWith(
      session: authenticatedSession,
      isVerifying: false,
    );
    await _storage.saveSession(authenticatedSession);
    return AccessLoginResult(
      ok: true,
      wasLocked: current.locked,
    );
  }

  void lock([LockReason reason = LockReason.manual]) {
    final prev = state.session;
    if (!prev.authenticated) return;
    final next = prev.copyWith(
      locked: true,
      lockReason: reason,
    );
    state = state.copyWith(session: next);
    unawaited(_storage.saveSession(next));
  }

  void logout() {
    final prev = state.session;
    final next = prev.copyWith(
      authenticated: false,
      locked: false,
      clearLockReason: true,
      clearUnlockedAt: true,
      clearLastActivityAt: true,
      clearSessionExpiresAt: true,
    );
    state = state.copyWith(session: next);
    unawaited(_storage.saveSession(next));
  }

  void setIdleTimeoutMinutes(int minutes) {
    final safeMinutes = clampIdleTimeoutMinutes(minutes);
    final prev = state.session;
    final next = prev.copyWith(
      idleTimeoutMinutes: safeMinutes,
      lastActivityAt:
          prev.authenticated && !prev.locked ? _nowMs() : prev.lastActivityAt,
    );
    state = state.copyWith(session: next);
    unawaited(_storage.saveSession(next));
  }

  Future<AccessPasswordChangeResult> updateAccessPassword(
    String currentPassword,
    String newPassword,
  ) async {
    final prev = state.session;
    state = state.copyWith(isVerifying: true);
    final currentValid =
        await verifyAccessCredentialAsync(currentPassword, prev.verifier);
    if (!mounted) {
      return const AccessPasswordChangeResult(ok: false);
    }

    if (!currentValid) {
      state = state.copyWith(isVerifying: false);
      return const AccessPasswordChangeResult(
        ok: false,
        errorCode: AccessErrorCode.currentWrong,
      );
    }

    final newErr = validateNewPassword(newPassword);
    if (newErr != null) {
      state = state.copyWith(isVerifying: false);
      return AccessPasswordChangeResult(
        ok: false,
        errorCode: newErr,
      );
    }

    final nextVerifier = await createPbkdf2VerifierAsync(
      newPassword,
      iterations: pbkdf2Iterations,
    );
    if (!mounted) {
      return const AccessPasswordChangeResult(ok: false);
    }

    final next = state.session.copyWith(
      verifier: nextVerifier,
      usingDefaultCredential: newPassword == 'vyron2026',
    );
    state = state.copyWith(
      session: next,
      isVerifying: false,
    );
    await _storage.saveSession(next);
    return const AccessPasswordChangeResult(ok: true);
  }

  void recordUserActivity() {
    final prev = state.session;
    if (!prev.authenticated || prev.locked) return;
    final now = _nowMs();
    if (now - _lastTouchMs < 10000) return;
    _lastTouchMs = now;
    final next = prev.copyWith(lastActivityAt: now);
    state = state.copyWith(session: next);
    unawaited(_storage.saveSession(next));
  }

  void checkInactivityAndExpiry() {
    final prev = state.session;
    if (!prev.authenticated || prev.locked) return;
    final now = _nowMs();

    if (prev.sessionExpiresAt != null && now >= prev.sessionExpiresAt!) {
      final expired = prev.copyWith(
        authenticated: false,
        locked: false,
        lockReason: LockReason.expired,
        clearUnlockedAt: true,
        clearLastActivityAt: true,
        clearSessionExpiresAt: true,
      );
      state = state.copyWith(session: expired);
      unawaited(_storage.saveSession(expired));
      return;
    }

    if (shouldAutoLock(
      lastActivityAt: prev.lastActivityAt,
      nowMs: now,
      idleTimeoutMinutes: prev.idleTimeoutMinutes,
    )) {
      final locked = prev.copyWith(
        locked: true,
        lockReason: LockReason.inactivity,
      );
      state = state.copyWith(session: locked);
      unawaited(_storage.saveSession(locked));
    }
  }

  void onAppLifecycleStateChanged(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      checkInactivityAndExpiry();
    }
  }
}
