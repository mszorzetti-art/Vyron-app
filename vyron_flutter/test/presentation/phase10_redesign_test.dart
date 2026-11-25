import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/app.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
import 'package:vyron/core/theme/vyron_theme.dart';
import 'package:vyron/core/widgets/vyron_ui.dart';
import 'package:vyron/data/seed_data.dart';
import 'package:vyron/data/storage/atomic_state_storage.dart';
import 'package:vyron/domain/models/operations_settings_models.dart';
import 'package:vyron/domain/models/vyron_enums.dart';
import 'package:vyron/presentation/charts/vyron_charts.dart';

class _CompleterVyronStateStorage implements VyronStateStorage {
  _CompleterVyronStateStorage(this._completer);

  final Completer<VyronState> _completer;
  VyronState? lastSaved;

  @override
  Future<VyronState> loadState() => _completer.future;

  @override
  Future<void> saveState(VyronState state) async {
    lastSaved = state;
  }

  @override
  Future<void> clearState() async {
    lastSaved = null;
  }
}

class _TrackingVyronStateStorage extends InMemoryVyronStateStorage {
  _TrackingVyronStateStorage();

  int saveCalls = 0;
  VyronState? lastSaved;

  @override
  Future<void> saveState(VyronState state) async {
    saveCalls += 1;
    lastSaved = state;
    await super.saveState(state);
  }
}

Widget _buildAuthorizedApp({required VyronStateStorage stateStorage}) {
  final session = buildAuthenticatedSession(
    VyronAccessSession.initial(),
    DateTime.now().millisecondsSinceEpoch,
  );
  final accessStorage = InMemoryAccessStorage(session);
  return ProviderScope(
    overrides: [
      vyronStateStorageProvider.overrideWithValue(stateStorage),
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

void main() {
  group(
    'Fase 10 — Skeleton loading, toggles semânticos e governança visual',
    () {
      testWidgets(
        'AdaptiveShell exibe VyronModuleSkeleton (sem CircularProgressIndicator) durante hidratação',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final completer = Completer<VyronState>();
          final delayedStorage = _CompleterVyronStateStorage(completer);

          await tester.pumpWidget(
            _buildAuthorizedApp(stateStorage: delayedStorage),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));

          expect(
            find.byKey(const Key('vyron-module-skeleton')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('vyron-chart-skeleton')), findsOneWidget);
          expect(find.byKey(const Key('vyron-table-skeleton')), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          completer.complete(buildInitialVyronState());
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('vyron-module-skeleton')), findsNothing);
          expect(find.text('Overview'), findsWidgets);
        },
      );

      testWidgets(
        'Notifications usa toggle ON/OFF para filtro Não lidas e alternância persistida de leitura por item',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final storage = _TrackingVyronStateStorage();
          await tester.pumpWidget(_buildAuthorizedApp(stateStorage: storage));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('vyron-nav-notifications')));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('notifications-unread-toggle')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('notif-read-toggle-not-1')),
            findsOneWidget,
          );

          // Marca not-1 como lida via toggle individual e confirma persistência
          await tester.tap(find.byKey(const Key('notif-read-toggle-not-1')));
          await tester.pumpAndSettle();
          expect(storage.saveCalls, greaterThanOrEqualTo(1));
          final savedAfterRead = storage.lastSaved!.notifications.firstWhere(
            (n) => n.id == 'not-1',
          );
          expect(savedAfterRead.read, isTrue);

          // Ativa toggle Não lidas: not-1 (agora lida) deve sair da lista filtrada
          await tester.tap(
            find.byKey(const Key('notifications-unread-toggle')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('notif-read-toggle-not-1')),
            findsNothing,
          );

          // Desativa toggle Não lidas: not-1 reaparece e pode ser marcada como não lida
          await tester.tap(
            find.byKey(const Key('notifications-unread-toggle')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('notif-read-toggle-not-1')),
            findsOneWidget,
          );

          await tester.tap(find.byKey(const Key('notif-read-toggle-not-1')));
          await tester.pumpAndSettle();
          final savedAfterUnread = storage.lastSaved!.notifications.firstWhere(
            (n) => n.id == 'not-1',
          );
          expect(savedAfterUnread.read, isFalse);
        },
      );

      testWidgets(
        'Automations permite toggle de agente quando ATIVO e bloqueia fail-closed sob Stop All',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final storage = _TrackingVyronStateStorage();
          await tester.pumpWidget(_buildAuthorizedApp(stateStorage: storage));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('vyron-nav-automations')));
          await tester.pumpAndSettle();

          final agentToggle = find.byKey(
            const Key('agent-toggle-ag-product-intel'),
          );
          await tester.ensureVisible(agentToggle);

          final initialAgent = (storage.lastSaved ?? buildInitialVyronState())
              .automations
              .firstWhere((a) => a.id == 'ag-product-intel');
          final initialState = initialAgent.state;

          // Alterna agente com sistema ativo
          await tester.tap(agentToggle);
          await tester.pumpAndSettle();
          final toggledAgent = storage.lastSaved!.automations.firstWhere(
            (a) => a.id == 'ag-product-intel',
          );
          expect(toggledAgent.state, isNot(initialState));

          // Aciona Stop All e confirma que o toggle do agente passa para modo bloqueado (enabled: false)
          final systemControlBtn = find.byKey(
            const Key('automations-system-control-btn'),
          );
          await tester.ensureVisible(systemControlBtn);
          await tester.tap(systemControlBtn);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('vyron-control-reason')),
            'Teste fail-closed Fase 10',
          );
          await tester.tap(find.byKey(const Key('vyron-control-confirm')));
          await tester.pumpAndSettle();

          await tester.ensureVisible(agentToggle);
          final toggleWidget = tester.widget<VyronToggleSwitch>(agentToggle);
          expect(toggleWidget.enabled, isFalse);
          expect(toggleWidget.onChanged, isNull);

          // Tentar tocar no toggle enquanto parado não altera estado persistido do agente
          final stateBeforeLockedTap = storage.lastSaved!.automations
              .firstWhere((a) => a.id == 'ag-product-intel')
              .state;
          await tester.tap(agentToggle);
          await tester.pumpAndSettle();
          final stateAfterLockedTap = storage.lastSaved!.automations
              .firstWhere((a) => a.id == 'ag-product-intel')
              .state;
          expect(stateAfterLockedTap, stateBeforeLockedTap);
        },
      );

      testWidgets(
        'Componentes de Fase 10 renderizam em mobile 390x844 sem overflow ou erros de layout',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          var switchVal = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: VyronTheme.dark(),
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VyronToggleSwitch(
                            key: const Key('mobile-phase10-toggle'),
                            value: switchVal,
                            label: 'Incluir registros de teste',
                            onChanged: (next) =>
                                setState(() => switchVal = next),
                          ),
                          const SizedBox(height: 12),
                          const VyronFeedbackBanner(
                            message: 'Operação auditada em ambiente mobile sem extrapolação horizontal.',
                            tone: VyronMetricTone.cobalt,
                          ),
                          const SizedBox(height: 12),
                          VyronInteractiveTimeSeriesChart(
                            language: UiLanguage.ptBR,
                            points: const [
                              VyronTimeSeriesPoint(
                                id: 'm1',
                                label: '01/11',
                                values: {'rev': 1200},
                              ),
                              VyronTimeSeriesPoint(
                                id: 'm2',
                                label: '08/11',
                                values: {'rev': 2100},
                              ),
                              VyronTimeSeriesPoint(
                                id: 'm3',
                                label: '15/11',
                                values: {'rev': 1850},
                              ),
                            ],
                            series: const [
                              VyronSeriesConfig(
                                id: 'rev',
                                label: 'Confirmado',
                                color: Color(0xFF315FEA),
                                areaFill: true,
                              ),
                            ],
                            formatValue: (v) => 'R\$ ${v.toStringAsFixed(0)}',
                            semanticLabel: 'Série mobile Fase 10',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const Key('mobile-phase10-toggle')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<VyronToggleSwitch>(
                  find.byKey(const Key('mobile-phase10-toggle')),
                )
                .value,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    },
  );
}
