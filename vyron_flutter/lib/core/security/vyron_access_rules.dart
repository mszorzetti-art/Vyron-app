import 'package:flutter/foundation.dart';
import '../crypto/vyron_crypto.dart';

const String _legacyAccessSalt = 'vyron-access-v1:';

/// Precomputed salted SHA-256 digest matching src/utils/vyronAccess.ts (`vyron2026`).
/// Plaintext is never stored in session storage or compared directly at runtime.
/// Used only as initial fallback verifier until upgraded to PBKDF2-HMAC-SHA256 on first login.
const String defaultDemoAccessHash =
    '5d54d0fc3f0bae1a86237ad40fef18177b4540a5666a1bd0c6a3717fbf4d578d';

const int defaultIdleTimeoutMinutes = 15;
const int defaultSessionMaxHours = 12;
const int defaultPbkdf2Iterations = 210000;
const int minPasswordLength = 6;

const List<int> idleTimeoutValues = [5, 15, 30, 60, 0];

enum AccessHashVersion {
  sha256V1('sha256-v1'),
  pbkdf2Sha256V1('pbkdf2-sha256-v1');

  const AccessHashVersion(this.wire);
  final String wire;

  static AccessHashVersion fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => AccessHashVersion.sha256V1,
      );
}

enum LockReason {
  manual('manual'),
  inactivity('inactivity'),
  expired('expired');

  const LockReason(this.wire);
  final String wire;

  static LockReason? fromWire(String? v) {
    if (v == null) return null;
    for (final e in values) {
      if (e.wire == v) return e;
    }
    return null;
  }
}

enum AccessErrorCode {
  emptyPassword,
  wrongPassword,
  currentWrong,
  newTooShort,
}

@immutable
class CredentialVerifier {
  const CredentialVerifier({
    required this.hashVersion,
    required this.credentialHash,
    this.saltHex,
    this.iterations = defaultPbkdf2Iterations,
  });

  const CredentialVerifier.legacyDefault()
      : hashVersion = AccessHashVersion.sha256V1,
        credentialHash = defaultDemoAccessHash,
        saltHex = null,
        iterations = 1;

  final AccessHashVersion hashVersion;
  final String credentialHash;
  final String? saltHex;
  final int iterations;

  bool get isLegacy => hashVersion == AccessHashVersion.sha256V1;

  Map<String, dynamic> toJson() => {
        'hashVersion': hashVersion.wire,
        'credentialHash': credentialHash,
        if (saltHex != null) 'saltHex': saltHex,
        'iterations': iterations,
      };

  factory CredentialVerifier.fromJson(Map<String, dynamic> json) {
    final rawHash = json['credentialHash'] as String?;
    if (rawHash == null || rawHash.length != 64) {
      return const CredentialVerifier.legacyDefault();
    }
    final version = AccessHashVersion.fromWire(json['hashVersion'] as String?);
    final salt = json['saltHex'] as String?;
    final iter = (json['iterations'] as num?)?.toInt() ??
        (version == AccessHashVersion.pbkdf2Sha256V1
            ? defaultPbkdf2Iterations
            : 1);

    if (version == AccessHashVersion.pbkdf2Sha256V1 &&
        (salt == null || salt.isEmpty)) {
      return const CredentialVerifier.legacyDefault();
    }

    return CredentialVerifier(
      hashVersion: version,
      credentialHash: rawHash,
      saltHex: salt,
      iterations: iter,
    );
  }
}

@immutable
class VyronAccessSession {
  const VyronAccessSession({
    required this.authenticated,
    required this.locked,
    required this.lockReason,
    required this.unlockedAt,
    required this.lastActivityAt,
    required this.sessionExpiresAt,
    required this.idleTimeoutMinutes,
    required this.verifier,
    required this.usingDefaultCredential,
  });

  factory VyronAccessSession.initial({
    bool? authenticated,
    bool? locked,
    LockReason? lockReason,
    int? unlockedAt,
    int? lastActivityAt,
    int? sessionExpiresAt,
    int? idleTimeoutMinutes,
    CredentialVerifier? verifier,
    bool? usingDefaultCredential,
  }) {
    return VyronAccessSession(
      authenticated: authenticated ?? false,
      locked: locked ?? false,
      lockReason: lockReason,
      unlockedAt: unlockedAt,
      lastActivityAt: lastActivityAt,
      sessionExpiresAt: sessionExpiresAt,
      idleTimeoutMinutes: idleTimeoutMinutes ?? defaultIdleTimeoutMinutes,
      verifier: verifier ?? const CredentialVerifier.legacyDefault(),
      usingDefaultCredential: usingDefaultCredential ?? true,
    );
  }

  final bool authenticated;
  final bool locked;
  final LockReason? lockReason;
  final int? unlockedAt;
  final int? lastActivityAt;
  final int? sessionExpiresAt;
  final int idleTimeoutMinutes;
  final CredentialVerifier verifier;
  final bool usingDefaultCredential;

  bool get isAuthorized => authenticated && !locked;

  VyronAccessSession copyWith({
    bool? authenticated,
    bool? locked,
    LockReason? lockReason,
    bool clearLockReason = false,
    int? unlockedAt,
    bool clearUnlockedAt = false,
    int? lastActivityAt,
    bool clearLastActivityAt = false,
    int? sessionExpiresAt,
    bool clearSessionExpiresAt = false,
    int? idleTimeoutMinutes,
    CredentialVerifier? verifier,
    bool? usingDefaultCredential,
  }) {
    return VyronAccessSession(
      authenticated: authenticated ?? this.authenticated,
      locked: locked ?? this.locked,
      lockReason: clearLockReason ? null : (lockReason ?? this.lockReason),
      unlockedAt: clearUnlockedAt ? null : (unlockedAt ?? this.unlockedAt),
      lastActivityAt:
          clearLastActivityAt ? null : (lastActivityAt ?? this.lastActivityAt),
      sessionExpiresAt: clearSessionExpiresAt
          ? null
          : (sessionExpiresAt ?? this.sessionExpiresAt),
      idleTimeoutMinutes: idleTimeoutMinutes ?? this.idleTimeoutMinutes,
      verifier: verifier ?? this.verifier,
      usingDefaultCredential:
          usingDefaultCredential ?? this.usingDefaultCredential,
    );
  }

  Map<String, dynamic> toJson() => {
        'authenticated': authenticated,
        'locked': locked,
        'lockReason': lockReason?.wire,
        'unlockedAt': unlockedAt,
        'lastActivityAt': lastActivityAt,
        'sessionExpiresAt': sessionExpiresAt,
        'idleTimeoutMinutes': idleTimeoutMinutes,
        'verifier': verifier.toJson(),
        'usingDefaultCredential': usingDefaultCredential,
      };

  factory VyronAccessSession.fromJson(Map<String, dynamic> json) {
    final verifierJson = json['verifier'];
    final verifier = verifierJson is Map<String, dynamic>
        ? CredentialVerifier.fromJson(verifierJson)
        : (json['credentialHash'] is String &&
                (json['credentialHash'] as String).length == 64)
            ? CredentialVerifier(
                hashVersion: AccessHashVersion.sha256V1,
                credentialHash: json['credentialHash'] as String,
                iterations: 1,
              )
            : const CredentialVerifier.legacyDefault();

    return VyronAccessSession(
      authenticated: json['authenticated'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      lockReason: LockReason.fromWire(json['lockReason'] as String?),
      unlockedAt: (json['unlockedAt'] as num?)?.toInt(),
      lastActivityAt: (json['lastActivityAt'] as num?)?.toInt(),
      sessionExpiresAt: (json['sessionExpiresAt'] as num?)?.toInt(),
      idleTimeoutMinutes:
          (json['idleTimeoutMinutes'] as num?)?.toInt() ??
              defaultIdleTimeoutMinutes,
      verifier: verifier,
      usingDefaultCredential: json['usingDefaultCredential'] as bool? ?? true,
    );
  }
}

/// Legacy salted SHA-256 helper kept exclusively for parity tests & backward verification.
String hashLegacyAccessCredential(String password) =>
    sha256Hex('$_legacyAccessSalt$password');

/// Builds a new hardened PBKDF2-HMAC-SHA256 credential verifier with a 16-byte random salt.
Future<CredentialVerifier> createPbkdf2VerifierAsync(
  String password, {
  int iterations = defaultPbkdf2Iterations,
  String? saltHexOverride,
}) async {
  final saltHex = saltHexOverride ?? generateSecureSaltHex(16);
  final derived = await pbkdf2HmacSha256Async(
    password: password,
    saltBytes: hexToBytes(saltHex),
    iterations: iterations,
    keyLengthBytes: 32,
  );
  return CredentialVerifier(
    hashVersion: AccessHashVersion.pbkdf2Sha256V1,
    credentialHash: derived,
    saltHex: saltHex,
    iterations: iterations,
  );
}

/// Verifies password synchronously against legacy or PBKDF2 verifier.
bool verifyAccessCredentialSync(String password, CredentialVerifier verifier) {
  if (password.isEmpty) return false;
  switch (verifier.hashVersion) {
    case AccessHashVersion.sha256V1:
      return constantTimeEquals(
        hashLegacyAccessCredential(password),
        verifier.credentialHash,
      );
    case AccessHashVersion.pbkdf2Sha256V1:
      if (verifier.saltHex == null || verifier.saltHex!.isEmpty) return false;
      final derived = pbkdf2HmacSha256Sync(
        password: password,
        saltBytes: hexToBytes(verifier.saltHex!),
        iterations: verifier.iterations,
        keyLengthBytes: 32,
      );
      return constantTimeEquals(derived, verifier.credentialHash);
  }
}

/// Verifies password asynchronously using a background Dart Isolate for PBKDF2.
Future<bool> verifyAccessCredentialAsync(
  String password,
  CredentialVerifier verifier,
) async {
  if (password.isEmpty) return false;
  switch (verifier.hashVersion) {
    case AccessHashVersion.sha256V1:
      return constantTimeEquals(
        hashLegacyAccessCredential(password),
        verifier.credentialHash,
      );
    case AccessHashVersion.pbkdf2Sha256V1:
      if (verifier.saltHex == null || verifier.saltHex!.isEmpty) return false;
      final derived = await pbkdf2HmacSha256Async(
        password: password,
        saltBytes: hexToBytes(verifier.saltHex!),
        iterations: verifier.iterations,
        keyLengthBytes: 32,
      );
      return constantTimeEquals(derived, verifier.credentialHash);
  }
}

bool shouldAutoLock({
  required int? lastActivityAt,
  required int nowMs,
  required int idleTimeoutMinutes,
}) {
  if (idleTimeoutMinutes <= 0 || lastActivityAt == null) return false;
  return nowMs - lastActivityAt >= idleTimeoutMinutes * 60000;
}

VyronAccessSession evaluatePersistedSession(
  VyronAccessSession session, [
  int? nowMs,
]) {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  if (!session.authenticated) {
    return session.copyWith(
      authenticated: false,
      locked: false,
      clearLockReason: true,
    );
  }

  if (session.sessionExpiresAt != null && now >= session.sessionExpiresAt!) {
    return session.copyWith(
      authenticated: false,
      locked: false,
      lockReason: LockReason.expired,
      clearUnlockedAt: true,
      clearLastActivityAt: true,
      clearSessionExpiresAt: true,
    );
  }

  if (!session.locked &&
      shouldAutoLock(
        lastActivityAt: session.lastActivityAt,
        nowMs: now,
        idleTimeoutMinutes: session.idleTimeoutMinutes,
      )) {
    return session.copyWith(
      locked: true,
      lockReason: LockReason.inactivity,
    );
  }

  return session;
}

VyronAccessSession buildAuthenticatedSession(
  VyronAccessSession current, [
  int? nowMs,
]) {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final keepExistingExpiry =
      current.sessionExpiresAt != null && current.sessionExpiresAt! > now;
  return current.copyWith(
    authenticated: true,
    locked: false,
    clearLockReason: true,
    unlockedAt: current.unlockedAt ?? now,
    lastActivityAt: now,
    sessionExpiresAt: keepExistingExpiry
        ? current.sessionExpiresAt
        : now + defaultSessionMaxHours * 3600000,
  );
}

/// Performs transparent hash upgrade from legacy SHA-256 to PBKDF2-HMAC-SHA256
/// immediately after successful password verification while keeping `usingDefaultCredential` accurate.
Future<VyronAccessSession> upgradeSessionToPbkdf2IfLegacy(
  VyronAccessSession session,
  String verifiedPlaintextPassword, {
  int iterations = defaultPbkdf2Iterations,
}) async {
  if (!session.verifier.isLegacy) return session;
  final upgradedVerifier = await createPbkdf2VerifierAsync(
    verifiedPlaintextPassword,
    iterations: iterations,
  );
  return session.copyWith(verifier: upgradedVerifier);
}

AccessErrorCode? validateNewPassword(String newPassword) {
  if (newPassword.trim().length < minPasswordLength) {
    return AccessErrorCode.newTooShort;
  }
  return null;
}

int clampIdleTimeoutMinutes(int minutes) => minutes.clamp(0, 240);
