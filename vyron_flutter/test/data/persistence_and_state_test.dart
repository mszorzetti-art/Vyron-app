import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
import 'package:vyron/data/seed_data.dart';
import 'package:vyron/data/storage/atomic_state_storage.dart';
import 'package:vyron/domain/models/brand_product_models.dart';
import 'package:vyron/domain/models/vyron_enums.dart';

void main() {
  group('Lote 3 — Persistência atômica e recuperação SHA-256', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vyron_storage_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'grava arquivo validado por SHA-256, cria .bak e recupera em corrupção',
      () async {
        final storage = AtomicFileVyronStateStorage(
          directoryProvider: () async => tempDir,
        );

        final v1 = buildInitialVyronState().copyWith(
          settings: buildInitialVyronState().settings.copyWith(
                baseCurrency: CurrencyCode.usd,
                ownerName: 'Mateus Zorzetti',
              ),
        );
        await storage.saveState(v1);

        final primary =
            File('${tempDir.path}${Platform.pathSeparator}${AtomicFileVyronStateStorage.defaultFileName}');
        final backup =
            File('${tempDir.path}${Platform.pathSeparator}${AtomicFileVyronStateStorage.defaultFileName}.bak');
        final temp =
            File('${tempDir.path}${Platform.pathSeparator}${AtomicFileVyronStateStorage.defaultFileName}.tmp');

        expect(primary.existsSync(), isTrue);
        expect(temp.existsSync(), isFalse);

        // Segunda gravação promove v1 para .bak e grava v2 como principal
        final v2 = v1.copyWith(
          settings: v1.settings.copyWith(baseCurrency: CurrencyCode.eur),
        );
        await storage.saveState(v2);
        expect(backup.existsSync(), isTrue);

        final loadedV2 = await storage.loadState();
        expect(loadedV2.settings.baseCurrency, CurrencyCode.eur);
        expect(loadedV2.settings.ownerName, OwnerProfile.name);

        // Corrompe arquivo principal -> checksum falha e recupera v1 do .bak
        await primary.writeAsString('{"schemaVersion":2,"sha256":"bad","state":{}}');
        final recoveredFromBackup = await storage.loadState();
        expect(recoveredFromBackup.settings.baseCurrency, CurrencyCode.usd);
        expect(recoveredFromBackup.settings.ownerName, OwnerProfile.name);

        // Corrompe também o backup -> fallback seguro para seed oficial
        await backup.writeAsString('corrupted');
        final fallbackSeed = await storage.loadState();
        expect(fallbackSeed.settings.baseCurrency, CurrencyCode.brl);
        expect(fallbackSeed.brands.length, 4);

        await storage.clearState();
        expect(primary.existsSync(), isFalse);
        expect(backup.existsSync(), isFalse);
      },
    );
  });

  group('Lote 3 — VyronAccessNotifier, upgrade PBKDF2 e auto-lock', () {
    test(
      'realiza login com upgrade transparente SHA-256 -> PBKDF2 e bloqueia por inatividade',
      () async {
        var virtualNow = DateTime.utc(2026, 11, 19, 10, 0).millisecondsSinceEpoch;
        final accessStorage = InMemoryAccessStorage();
        final notifier = VyronAccessNotifier(
          storage: accessStorage,
          nowMs: () => virtualNow,
          pbkdf2Iterations: 200,
        );
        addTearDown(notifier.dispose);

        await notifier.hydrate();
        expect(notifier.state.isHydrating, isFalse);
        expect(notifier.state.isAuthorized, isFalse);
        expect(notifier.state.session.verifier.isLegacy, isTrue);

        final emptyRes = await notifier.login('   ');
        expect(emptyRes.ok, isFalse);
        expect(emptyRes.errorCode, AccessErrorCode.emptyPassword);

        final wrongRes = await notifier.login('errada');
        expect(wrongRes.ok, isFalse);
        expect(wrongRes.errorCode, AccessErrorCode.wrongPassword);

        final okRes = await notifier.login('vyron2026');
        expect(okRes.ok, isTrue);
        expect(notifier.state.isAuthorized, isTrue);
        expect(notifier.state.session.verifier.hashVersion, AccessHashVersion.pbkdf2Sha256V1);
        expect(notifier.state.session.verifier.saltHex, isNotNull);
        expect(notifier.state.session.usingDefaultCredential, isTrue);

        // Alteração de senha com geração de novo salt PBKDF2
        final wrongChange =
            await notifier.updateAccessPassword('errada', 'novaSenha99');
        expect(wrongChange.ok, isFalse);
        expect(wrongChange.errorCode, AccessErrorCode.currentWrong);

        final shortChange =
            await notifier.updateAccessPassword('vyron2026', '123');
        expect(shortChange.ok, isFalse);
        expect(shortChange.errorCode, AccessErrorCode.newTooShort);

        final okChange =
            await notifier.updateAccessPassword('vyron2026', 'vyronStrong2026');
        expect(okChange.ok, isTrue);
        expect(notifier.state.session.usingDefaultCredential, isFalse);

        // Avança 16 minutos em segundo plano e retorna ao app -> auto-lock imediato
        virtualNow += 16 * 60000;
        notifier.onAppLifecycleStateChanged(AppLifecycleState.resumed);
        expect(notifier.state.isAuthorized, isFalse);
        expect(notifier.state.session.locked, isTrue);
        expect(notifier.state.session.lockReason, LockReason.inactivity);

        // Desbloqueio exige nova senha PBKDF2
        final oldFail = await notifier.login('vyron2026');
        expect(oldFail.ok, isFalse);
        final unlockOk = await notifier.login('vyronStrong2026');
        expect(unlockOk.ok, isTrue);
        expect(unlockOk.wasLocked, isTrue);
        expect(notifier.state.isAuthorized, isTrue);

        // Avança além do limite máximo de 12h -> expiração
        virtualNow += 13 * 3600000;
        notifier.checkInactivityAndExpiry();
        expect(notifier.state.session.authenticated, isFalse);
        expect(notifier.state.session.lockReason, LockReason.expired);
      },
    );
  });

  group('Lote 3 — VyronStateNotifier mutações e governança', () {
    test(
      'preserva herança zero, Stop All fail-closed e reset para seed oficial',
      () async {
        final storage = InMemoryVyronStateStorage();
        final fixedNow = DateTime.utc(2026, 11, 19, 12, 0);
        final notifier = VyronStateNotifier(
          storage: storage,
          nowUtc: () => fixedNow,
        );
        addTearDown(notifier.dispose);

        await notifier.hydrate();
        expect(notifier.state.isHydrated, isTrue);

        // Edição de manifesto em peça autorizada (cnt-3) aciona herança zero
        final beforeCnt3 = notifier.state.domain.contents
            .firstWhere((c) => c.id == 'cnt-3');
        expect(beforeCnt3.authorization, isNotNull);

        notifier.updateContent(
          'cnt-3',
          const ContentUpdatePatch(
            title: 'Sound Test Editado: Banana vs Brown',
          ),
        );
        final afterCnt3 = notifier.state.domain.contents
            .firstWhere((c) => c.id == 'cnt-3');
        expect(afterCnt3.authorization, isNull);
        expect(afterCnt3.status, ContentStatus.inReview);
        expect(
          afterCnt3.currentManifestHash,
          isNot(beforeCnt3.currentManifestHash),
        );
        expect(afterCnt3.versions.first.version, 'v2.0');

        // Stop All + tentativa de resume bloqueada por job #104 órfão + reconciliação
        final stopped = notifier.triggerStopAll();
        expect(stopped, 3);
        expect(
          notifier.state.domain.systemControl.state,
          SystemControlStatus.halted,
        );

        final blockedRun = notifier.runPipelineDemo(JobMode.commit);
        expect(blockedRun.ok, isFalse);

        final blockedResume = notifier.clearEmergencyStop();
        expect(blockedResume.ok, isFalse);

        final reconciled = notifier.reconcileJobsDemo();
        expect(reconciled, 1);

        final resumed = notifier.clearEmergencyStop();
        expect(resumed.ok, isTrue);
        expect(
          notifier.state.domain.systemControl.state,
          SystemControlStatus.active,
        );

        // Reset restaura seed original e persiste limpo
        notifier.createBrand(
          const BrandCreateInput(
            name: 'Temp Brand',
            slug: 'temp-brand',
            niche: 'Hardware',
            segment: 'Reviews',
            market: 'Brasil',
            language: 'PT-BR',
            status: BrandStatus.active,
            accentColor: '#315FEA',
            secondaryColor: '#101216',
            typographyNote: 'DM Sans',
            tagline: 'Temp',
            description: 'Temp',
          ),
        );
        expect(notifier.state.domain.brands.length, 5);

        await notifier.resetDemoData();
        expect(notifier.state.domain.brands.length, 4);
      },
    );
  });
}
