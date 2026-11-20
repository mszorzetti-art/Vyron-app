import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/core/crypto/vyron_crypto.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
import 'package:vyron/domain/models/brand_product_models.dart';

void main() {
  group('Lote 1 — Segurança e Vyron Access', () {
    test('vetores PBKDF2-HMAC-SHA256 batem exatamente com RFC 8018 / Node', () {
      expect(
        pbkdf2HmacSha256Sync(
          password: 'password',
          saltBytes: utf8.encode('salt'),
          iterations: 1,
        ),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );

      expect(
        pbkdf2HmacSha256Sync(
          password: 'password',
          saltBytes: utf8.encode('salt'),
          iterations: 4096,
        ),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );

      expect(
        pbkdf2HmacSha256Sync(
          password: 'vyron2026',
          saltBytes: hexToBytes('000102030405060708090a0b0c0d0e0f'),
          iterations: 1000,
        ),
        '5b4c5e3895d00414c90300df9d3dbc867a4af519dbad7cadd3a1f172782851d7',
      );
    });

    test(
      'verifica credencial legada sha256-v1 e cria/verifica PBKDF2-HMAC-SHA256 em Isolate',
      () async {
        const legacy = CredentialVerifier.legacyDefault();
        expect(verifyAccessCredentialSync('', legacy), isFalse);
        expect(verifyAccessCredentialSync('wrong-pass', legacy), isFalse);
        expect(verifyAccessCredentialSync('vyron2026', legacy), isTrue);

        final pbkdf2Verifier = await createPbkdf2VerifierAsync(
          'minha-chave-privada',
          iterations: 10000,
        );
        expect(pbkdf2Verifier.hashVersion, AccessHashVersion.pbkdf2Sha256V1);
        expect(pbkdf2Verifier.credentialHash, isNot('minha-chave-privada'));
        expect(pbkdf2Verifier.saltHex, isNotNull);
        expect(pbkdf2Verifier.saltHex!.length, 32);

        expect(
          await verifyAccessCredentialAsync(
            'minha-chave-privada',
            pbkdf2Verifier,
          ),
          isTrue,
        );
        expect(
          await verifyAccessCredentialAsync('vyron2026', pbkdf2Verifier),
          isFalse,
        );
      },
    );

    test(
      'upgradeSessionToPbkdf2IfLegacy promove verificador legado preservando usingDefaultCredential',
      () async {
        final initial = VyronAccessSession.initial();
        expect(initial.verifier.isLegacy, isTrue);
        expect(initial.usingDefaultCredential, isTrue);

        final upgraded = await upgradeSessionToPbkdf2IfLegacy(
          initial,
          'vyron2026',
          iterations: 10000,
        );
        expect(upgraded.verifier.isLegacy, isFalse);
        expect(
          upgraded.verifier.hashVersion,
          AccessHashVersion.pbkdf2Sha256V1,
        );
        expect(upgraded.usingDefaultCredential, isTrue);
        expect(
          await verifyAccessCredentialAsync('vyron2026', upgraded.verifier),
          isTrue,
        );

        final decoded = VyronAccessSession.fromJson(upgraded.toJson());
        expect(decoded.verifier.hashVersion, AccessHashVersion.pbkdf2Sha256V1);
        expect(decoded.verifier.saltHex, upgraded.verifier.saltHex);
        expect(decoded.verifier.iterations, 10000);
      },
    );

    test('shouldAutoLock respeita estritamente janela de inatividade', () {
      const t0 = 1700000000000;
      expect(
        shouldAutoLock(
          lastActivityAt: t0,
          nowMs: t0 + 14 * 60000,
          idleTimeoutMinutes: 15,
        ),
        isFalse,
      );
      expect(
        shouldAutoLock(
          lastActivityAt: t0,
          nowMs: t0 + 15 * 60000,
          idleTimeoutMinutes: 15,
        ),
        isTrue,
      );
      expect(
        shouldAutoLock(
          lastActivityAt: t0,
          nowMs: t0 + 120 * 60000,
          idleTimeoutMinutes: 0,
        ),
        isFalse,
      );
    });

    test(
      'evaluatePersistedSession mantém sessão ativa, bloqueia por inatividade e expira após max age',
      () {
        const t0 = 1700000000000;
        final active =
            buildAuthenticatedSession(VyronAccessSession.initial(), t0);

        final reloadedSoon = evaluatePersistedSession(active, t0 + 5 * 60000);
        expect(reloadedSoon.authenticated, isTrue);
        expect(reloadedSoon.locked, isFalse);

        final reloadedIdle = evaluatePersistedSession(active, t0 + 20 * 60000);
        expect(reloadedIdle.authenticated, isTrue);
        expect(reloadedIdle.locked, isTrue);
        expect(reloadedIdle.lockReason, LockReason.inactivity);

        final expired = evaluatePersistedSession(active, t0 + 13 * 3600000);
        expect(expired.authenticated, isFalse);
        expect(expired.locked, isFalse);
        expect(expired.lockReason, LockReason.expired);
      },
    );

    test('validateNewPassword e normalizeOwnerName aplicam política oficial',
        () {
      expect(validateNewPassword('12345'), AccessErrorCode.newTooShort);
      expect(validateNewPassword('   abc  '), AccessErrorCode.newTooShort);
      expect(validateNewPassword('vyron99'), isNull);

      expect(OwnerProfile.name, 'Marcus Zorzetti');
      expect(
        OwnerProfile.normalizeOwnerName('Mateus Zorzetti'),
        'Marcus Zorzetti',
      );
      expect(OwnerProfile.normalizeOwnerName(''), 'Marcus Zorzetti');
      expect(
        OwnerProfile.normalizeOwnerName('Marcus Zorzetti'),
        'Marcus Zorzetti',
      );
    },);
  });
}
