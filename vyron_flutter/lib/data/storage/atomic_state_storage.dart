import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/crypto/vyron_crypto.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/operations_settings_models.dart';
import '../seed_data.dart';

/// Contrato de persistência local do estado operacional Vyron.
abstract interface class VyronStateStorage {
  Future<VyronState> loadState();
  Future<void> saveState(VyronState state);
  Future<void> clearState();
}

/// Implementação em memória para testes unitários e de widget.
class InMemoryVyronStateStorage implements VyronStateStorage {
  InMemoryVyronStateStorage([VyronState? initial]) : _state = initial;

  VyronState? _state;

  @override
  Future<VyronState> loadState() async => _state ?? buildInitialVyronState();

  @override
  Future<void> saveState(VyronState state) async {
    _state = state;
  }

  @override
  Future<void> clearState() async {
    _state = null;
  }
}

/// Persistência atômica em disco nativo (Android/iOS) com envelope SHA-256,
/// gravação via arquivo temporário + rename e fallback automático para `.bak`.
class AtomicFileVyronStateStorage implements VyronStateStorage {
  AtomicFileVyronStateStorage({
    Future<Directory> Function()? directoryProvider,
    this.fileName = defaultFileName,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const int schemaVersion = 2;
  static const String defaultFileName = 'vyron_state_v2.json';

  final Future<Directory> Function() _directoryProvider;
  final String fileName;

  Future<void> _writeChain = Future<void>.value();

  Future<File> _primaryFile(Directory dir) async =>
      File('${dir.path}${Platform.pathSeparator}$fileName');

  Future<File> _backupFile(Directory dir) async =>
      File('${dir.path}${Platform.pathSeparator}$fileName.bak');

  Future<File> _tempFile(Directory dir) async =>
      File('${dir.path}${Platform.pathSeparator}$fileName.tmp');

  @override
  Future<VyronState> loadState() async {
    await _writeChain;
    try {
      final dir = await _directoryProvider();
      final primary = await _primaryFile(dir);
      final fromPrimary = await _tryReadValidatedFile(primary);
      if (fromPrimary != null) {
        return fromPrimary;
      }

      final backup = await _backupFile(dir);
      final fromBackup = await _tryReadValidatedFile(backup);
      if (fromBackup != null) {
        return fromBackup;
      }
    } catch (_) {
      // Fallback seguro ao estado seed oficial em caso de falha irrecuperável
    }
    return buildInitialVyronState();
  }

  @override
  Future<void> saveState(VyronState state) {
    _writeChain = _writeChain.catchError((_) {}).then((_) async {
      final dir = await _directoryProvider();
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      final primary = await _primaryFile(dir);
      final backup = await _backupFile(dir);
      final temp = await _tempFile(dir);

      final stateMap = state.toJson();
      final canonicalStateJson = jsonEncode(stateMap);
      final digest = sha256Hex(canonicalStateJson);

      final envelope = jsonEncode(<String, dynamic>{
        'schemaVersion': schemaVersion,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'sha256': digest,
        'state': stateMap,
      });

      await temp.writeAsString(envelope, flush: true);

      if (primary.existsSync()) {
        final validCurrent = await _tryReadValidatedFile(primary);
        if (validCurrent != null) {
          await primary.copy(backup.path);
        }
      }

      if (primary.existsSync() && Platform.isWindows) {
        await primary.delete();
      }
      await temp.rename(primary.path);
    });
    return _writeChain;
  }

  @override
  Future<void> clearState() {
    _writeChain = _writeChain.catchError((_) {}).then((_) async {
      final dir = await _directoryProvider();
      for (final file in [
        await _primaryFile(dir),
        await _backupFile(dir),
        await _tempFile(dir),
      ]) {
        if (file.existsSync()) {
          await file.delete();
        }
      }
    });
    return _writeChain;
  }

  Future<VyronState?> _tryReadValidatedFile(File file) async {
    if (!file.existsSync()) return null;
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      if (decoded['schemaVersion'] != schemaVersion) return null;
      final expectedSha = decoded['sha256'];
      final stateRaw = decoded['state'];
      if (expectedSha is! String || stateRaw is! Map<String, dynamic>) {
        return null;
      }

      final actualSha = sha256Hex(jsonEncode(stateRaw));
      if (!constantTimeEquals(actualSha, expectedSha)) {
        return null;
      }

      final hydrated = VyronState.fromJson(stateRaw);
      return hydrated.copyWith(
        settings: hydrated.settings.copyWith(
          ownerName: OwnerProfile.normalizeOwnerName(
            hydrated.settings.ownerName,
          ),
          ownerEmail: hydrated.settings.ownerEmail.isNotEmpty
              ? hydrated.settings.ownerEmail
              : OwnerProfile.email,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
