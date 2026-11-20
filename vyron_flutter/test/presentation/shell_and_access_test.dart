import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/app.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
import 'package:vyron/data/storage/atomic_state_storage.dart';

Widget _buildApp({VyronAccessSession? initialSession}) {
  final accessStorage = InMemoryAccessStorage(initialSession);
  return ProviderScope(
    overrides: [
      vyronStateStorageProvider.overrideWithValue(InMemoryVyronStateStorage()),
      vyronAccessStorageProvider.overrideWithValue(accessStorage),
      vyronAccessProvider.overrideWith((ref) {
        final notifier = VyronAccessNotifier(
          storage: accessStorage,
          pbkdf2Iterations: 200,
        );
        unawaited(notifier.hydrate());
        return notifier;
      }),
    ],
    child: const VyronBootstrapApp(),
  );
}

Future<void> _submitPasswordAndSettle(
  WidgetTester tester,
  String password,
) async {
  await tester.enterText(
    find.byKey(const Key('vyron-access-password')),
    password,
  );
  await tester.tap(find.byKey(const Key('vyron-access-submit')));
  await tester.pump();
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  });
  await tester.pumpAndSettle();
}

void main() {
  group('Lote 4 — Access Gate, GoRouter e AdaptiveShell', () {
    testWidgets(
      'valida erro de senha e autentica vyron2026 abrindo AdaptiveShell em 1280x800',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        expect(find.text('Bem-vindo de volta'), findsOneWidget);
        expect(find.text('vyron2026'), findsOneWidget);

        await _submitPasswordAndSettle(tester, 'senha-errada');
        expect(find.byKey(const Key('vyron-access-error')), findsOneWidget);

        await _submitPasswordAndSettle(tester, 'vyron2026');
        expect(find.text('Overview'), findsWidgets);
        expect(find.byKey(const Key('vyron-stop-all-btn')), findsOneWidget);
      },
    );

    testWidgets(
      'bloqueio manual redireciona para /access e desbloqueio restaura módulo anterior',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final activeSession = buildAuthenticatedSession(
          VyronAccessSession.initial(),
          DateTime.now().millisecondsSinceEpoch,
        );
        await tester.pumpWidget(_buildApp(initialSession: activeSession));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-nav-finance')));
        await tester.pumpAndSettle();
        expect(find.text('FINANCE'), findsOneWidget);

        await tester.tap(find.byKey(const Key('vyron-sidebar-lock-btn')));
        await tester.pumpAndSettle();

        expect(
          find.text('Sessão bloqueada manualmente pelo proprietário.'),
          findsOneWidget,
        );

        await _submitPasswordAndSettle(tester, 'vyron2026');
        expect(find.text('FINANCE'), findsOneWidget);
      },
    );

    testWidgets(
      'renderiza barra inferior e Drawer em 390x844 sem overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final activeSession = buildAuthenticatedSession(
          VyronAccessSession.initial(),
          DateTime.now().millisecondsSinceEpoch,
        );
        await tester.pumpWidget(_buildApp(initialSession: activeSession));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        await tester.tap(find.byKey(const Key('vyron-open-drawer-btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-nav-settings')), findsOneWidget);
        await tester.tap(find.byKey(const Key('vyron-nav-settings')));
        await tester.pumpAndSettle();

        expect(find.text('SETTINGS'), findsOneWidget);
      },
    );

    testWidgets(
      'Stop All halta sistema, bloqueia retomada com job #104 e libera após reconciliação',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final activeSession = buildAuthenticatedSession(
          VyronAccessSession.initial(),
          DateTime.now().millisecondsSinceEpoch,
        );
        await tester.pumpWidget(_buildApp(initialSession: activeSession));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-stop-all-btn')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('vyron-control-reason')),
          'Auditoria manual do lote',
        );
        await tester.tap(find.byKey(const Key('vyron-control-confirm')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-halted-banner')), findsOneWidget);
        expect(find.text('PARADO'), findsOneWidget);

        await tester.tap(find.byKey(const Key('vyron-halted-banner-resume-btn')));
        await tester.pumpAndSettle();

        expect(
          find.text('Trava de segurança: execução pendente detectada'),
          findsOneWidget,
        );
        final confirmBtnBefore = tester.widget<ElevatedButton>(
          find.byKey(const Key('vyron-control-confirm')),
        );
        expect(confirmBtnBefore.onPressed, isNull);

        await tester.tap(find.text('Reconciliar execuções agora'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('vyron-control-reason')),
          'Execuções conciliadas',
        );
        await tester.tap(find.byKey(const Key('vyron-control-confirm')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-halted-banner')), findsNothing);
        expect(find.text('ATIVO'), findsOneWidget);
      },
    );
  });
}
