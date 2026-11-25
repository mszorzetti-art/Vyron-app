import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'vyron_access_rules.dart';

/// Contrato de armazenamento criptografado para credenciais e sessão Vyron Access.
abstract interface class VyronAccessStorage {
  Future<VyronAccessSession> loadSession();
  Future<void> saveSession(VyronAccessSession session);
  Future<void> clearSession();
}

/// Implementação em memória para testes unitários e de widget.
class InMemoryAccessStorage implements VyronAccessStorage {
  InMemoryAccessStorage([VyronAccessSession? initial]) : _session = initial;

  VyronAccessSession? _session;

  @override
  Future<VyronAccessSession> loadSession() async =>
      _session ?? VyronAccessSession.initial();

  @override
  Future<void> saveSession(VyronAccessSession session) async {
    _session = session;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}

/// Armazenamento nativo protegido via Android EncryptedSharedPreferences/Keystore
/// e iOS Keychain (sem fallback inseguro em texto plano).
class FlutterSecureAccessStorage implements VyronAccessStorage {
  FlutterSecureAccessStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const String sessionStorageKey = 'vyron_access_session_v2';

  final FlutterSecureStorage _storage;

  @override
  Future<VyronAccessSession> loadSession() async {
    try {
      final raw = await _storage.read(key: sessionStorageKey);
      if (raw == null || raw.trim().isEmpty) {
        return VyronAccessSession.initial();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return VyronAccessSession.initial();
      }
      final hydrated = VyronAccessSession.fromJson(decoded);
      return evaluatePersistedSession(hydrated);
    } catch (_) {
      return VyronAccessSession.initial();
    }
  }

  @override
  Future<void> saveSession(VyronAccessSession session) async {
    try {
      await _storage.write(
        key: sessionStorageKey,
        value: jsonEncode(session.toJson()),
      );
    } catch (_) {
      // Mantém estado em memória mesmo em eventual indisponibilidade transitória de keystore
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: sessionStorageKey);
    } catch (_) {
      // Ignora erro de remoção se chave não existir
    }
  }
}
