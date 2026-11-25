import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/app.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
import 'package:vyron/core/widgets/vyron_ui.dart';
import 'package:vyron/data/storage/atomic_state_storage.dart';

Widget _buildAuthorizedApp() {
  final session = buildAuthenticatedSession(
    VyronAccessSession.initial(),
    DateTime.now().millisecondsSinceEpoch,
  );
  final accessStorage = InMemoryAccessStorage(session);
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

Future<void> _goDesktopNav(WidgetTester tester, String navKey) async {
  final item = find.byKey(Key(navKey));
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  group(
    'Lote 8 — Finance, Automations, Activity, Notifications & Settings',
    () {
      testWidgets(
        'Finance separa estágios, alterna teste/moeda, detalha fluxo e registra novo lançamento',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(_buildAuthorizedApp());
          await tester.pumpAndSettle();

          await _goDesktopNav(tester, 'vyron-nav-finance');

          expect(find.text('Financeiro & Conciliação'), findsOneWidget);
          expect(find.byKey(const Key('finance-kpi-pending')), findsOneWidget);
          expect(
            find.byKey(const Key('finance-kpi-confirmed')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('finance-kpi-budget')), findsOneWidget);
          expect(
            find.byKey(const Key('finance-kpi-projections')),
            findsOneWidget,
          );

          // Toggle include test records on and off
          expect(find.text('Registro de teste'), findsNothing);
          await tester.tap(
            find.byKey(const Key('finance-include-test-toggle')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Registro de teste'), findsWidgets);

          await tester.tap(
            find.byKey(const Key('finance-include-test-toggle')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Registro de teste'), findsNothing);

          // Switch base currency to USD
          await tester.tap(find.text('USD'));
          await tester.pumpAndSettle();
          expect(find.text('Convertido (USD)'), findsOneWidget);

          // Create a new finance entry via modal
          await tester.tap(find.byKey(const Key('finance-new-entry-btn')));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byKey(const Key('finance-modal-desc')),
            'Liquidação Lote 8 Amazon BR',
          );
          final financeSubmit = find.byKey(const Key('finance-modal-submit'));
          await tester.ensureVisible(financeSubmit);
          await tester.tap(financeSubmit);
          await tester.pumpAndSettle();

          expect(find.text('Liquidação Lote 8 Amazon BR'), findsWidgets);
        },
      );

      testWidgets(
        'Automations bloqueia gravação quando parado, exige reconciliação para retomar e edita políticas do agente',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(_buildAuthorizedApp());
          await tester.pumpAndSettle();

          await _goDesktopNav(tester, 'vyron-nav-automations');

          expect(
            find.descendant(
              of: find.byType(VyronPageHeader),
              matching: find.text('Automations & Agents'),
            ),
            findsOneWidget,
          );

          // Halt system controls via Stop All modal
          await tester.tap(
            find.byKey(const Key('automations-system-control-btn')),
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('vyron-control-reason')),
            'Parada de segurança Lote 8',
          );
          await tester.tap(find.byKey(const Key('vyron-control-confirm')));
          await tester.pumpAndSettle();

          expect(find.text('Interrompido'), findsWidgets);

          // Switch to Jobs tab and verify fail-closed commit blocking
          await tester.tap(
            find.textContaining('Execuções de tarefas & Stop All'),
          );
          await tester.pumpAndSettle();

          final commitBtn = find.byKey(const Key('job-cmd-commit'));
          await tester.ensureVisible(commitBtn);
          await tester.tap(commitBtn);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('automations-runner-notice')),
            findsOneWidget,
          );
          expect(find.textContaining('bloqueada'), findsWidgets);

          // Reconcile pending run #104, then resume system control
          final reconcileBtn = find.byKey(
            const Key('jobs-inline-reconcile-btn'),
          );
          await tester.ensureVisible(reconcileBtn);
          await tester.tap(reconcileBtn);
          await tester.pumpAndSettle();

          final sysCtrlBtn = find.byKey(
            const Key('automations-system-control-btn'),
          );
          await tester.ensureVisible(sysCtrlBtn);
          await tester.tap(sysCtrlBtn);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('vyron-control-reason')),
            'Reconciliação concluída Lote 8',
          );
          await tester.tap(find.byKey(const Key('vyron-control-confirm')));
          await tester.pumpAndSettle();

          expect(find.text('Ativo'), findsWidgets);

          // Switch back to Agents tab and open detail view
          final agentsTab = find.textContaining('Agentes & Políticas');
          await tester.ensureVisible(agentsTab);
          await tester.tap(agentsTab);
          await tester.pumpAndSettle();

          final detailBtn = find.byKey(
            const Key('agent-detail-ag-product-intel'),
          );
          await tester.ensureVisible(detailBtn);
          await tester.tap(detailBtn);
          await tester.pumpAndSettle();

          expect(find.text('Qualificador Comercial'), findsWidgets);
          expect(
            find.byKey(const Key('automation-approve-btn')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('automation-approve-btn')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('automation-approve-btn')), findsNothing);
        },
      );

      testWidgets(
        'Activity filtra auditoria e Notifications simula alerta e abre módulo alvo',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(_buildAuthorizedApp());
          await tester.pumpAndSettle();

          await _goDesktopNav(tester, 'vyron-nav-activity');
          expect(find.text('Activity & Registro de Auditoria'), findsOneWidget);

          await tester.enterText(
            find.byKey(const Key('activity-search-input')),
            'UltraSharp',
          );
          await tester.pumpAndSettle();
          expect(find.textContaining('UltraSharp'), findsWidgets);

          await _goDesktopNav(tester, 'vyron-nav-notifications');
          expect(
            find.descendant(
              of: find.byType(VyronPageHeader),
              matching: find.text('Notifications'),
            ),
            findsOneWidget,
          );

          await tester.tap(find.byKey(const Key('notifications-simulate-btn')));
          await tester.pumpAndSettle();

          final openTarget = find.byKey(const Key('notif-open-not-1'));
          await tester.ensureVisible(openTarget);
          await tester.tap(openTarget);
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(VyronPageHeader),
              matching: find.text('Content Studio & Aprovação por Hash'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Settings alterna idioma, atualiza senha, bloqueia sessão e renderiza mobile 390x844 sem overflow',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(_buildAuthorizedApp());
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('vyron-open-drawer-btn')));
          await tester.pumpAndSettle();
          final settingsNav = find.byKey(const Key('vyron-nav-settings'));
          await tester.ensureVisible(settingsNav);
          await tester.tap(settingsNav);
          await tester.pumpAndSettle();

          expect(find.text('Settings & Governança'), findsOneWidget);

          // Switch UI language to EN-US and back to PT-BR
          final enBtn = find.text('EN-US');
          await tester.ensureVisible(enBtn);
          await tester.tap(enBtn);
          await tester.pumpAndSettle();
          expect(find.text('Settings & Governance'), findsOneWidget);

          final ptBtn = find.text('PT-BR');
          await tester.ensureVisible(ptBtn);
          await tester.tap(ptBtn);
          await tester.pumpAndSettle();
          expect(find.text('Settings & Governança'), findsOneWidget);

          // Update password via PBKDF2
          final curPwd = find.byKey(const Key('settings-current-pwd'));
          await tester.ensureVisible(curPwd);
          await tester.enterText(curPwd, 'vyron2026');
          await tester.enterText(
            find.byKey(const Key('settings-new-pwd')),
            'vyron-secret-2026',
          );
          final savePwd = find.byKey(const Key('settings-save-pwd-btn'));
          await tester.ensureVisible(savePwd);
          await tester.tap(savePwd);
          await tester.pump();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
          });
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('settings-pwd-feedback')),
            findsOneWidget,
          );

          // Lock session and confirm redirect to AccessScreen
          final lockBtn = find.byKey(const Key('settings-lock-vyron-btn'));
          await tester.ensureVisible(lockBtn);
          await tester.tap(lockBtn);
          await tester.pumpAndSettle();

          expect(
            find.text('Sessão bloqueada manualmente pelo proprietário.'),
            findsOneWidget,
          );
        },
      );
    },
  );
}
