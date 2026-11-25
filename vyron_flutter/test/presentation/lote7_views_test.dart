import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/app.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
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

void main() {
  group('Lote 7 — Content, Channels & Analytics', () {
    testWidgets(
      'Content Studio valida 6 travas, autoriza hash individual, aplica herança zero, rejeita c/ feedback e navega pelo Calendário',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-nav-content')));
        await tester.pumpAndSettle();

        expect(
          find.text('Content Studio & Aprovação por Hash'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('content-hash-panel')), findsOneWidget);
        expect(
          find.byKey(const Key('content-check-hashMatch')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('content-check-systemControlPhase')),
          findsOneWidget,
        );

        // Select cnt-2 (inReview, sem autorização inicial)
        final cnt2Item = find.byKey(const Key('content-queue-cnt-2'));
        await tester.ensureVisible(cnt2Item);
        await tester.tap(cnt2Item);
        await tester.pumpAndSettle();

        expect(find.text('Sem autorização ativa nesta versão'), findsOneWidget);

        // Revalidate evidence and authorize individual hash
        final revalidateBtn = find.byKey(const Key('content-revalidate-btn'));
        await tester.ensureVisible(revalidateBtn);
        await tester.tap(revalidateBtn);
        await tester.pumpAndSettle();

        final authBtn = find.byKey(const Key('content-authorize-btn'));
        await tester.ensureVisible(authBtn);
        await tester.tap(authBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('auth-modal-note')),
          'Revisado e aprovado em teste Lote 7.',
        );
        await tester.tap(find.byKey(const Key('auth-modal-confirm')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('content-revoke-btn')), findsOneWidget);

        // Zero inheritance: editing script must invalidate prior authorization immediately
        final scriptField = find.byKey(const Key('content-script-field'));
        await tester.ensureVisible(scriptField);
        await tester.enterText(
          scriptField,
          'Roteiro editado após autorização.',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('content-revoke-btn')), findsNothing);
        expect(find.text('Sem autorização ativa nesta versão'), findsOneWidget);

        // Reject with structured feedback (requires non-empty note)
        final rejectBtn = find.byKey(const Key('content-reject-btn'));
        await tester.ensureVisible(rejectBtn);
        await tester.tap(rejectBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reject-modal-note')),
          'Faltou fonte nível 1 para afirmação de contraste.',
        );
        await tester.tap(find.byKey(const Key('reject-modal-confirm')));
        await tester.pumpAndSettle();

        // Switch to Editorial Calendar and tap a scheduled item
        final calTab = find.descendant(
          of: find.byKey(const Key('content-subview-switch')),
          matching: find.text('Calendário Editorial'),
        );
        await tester.ensureVisible(calTab);
        await tester.tap(calTab);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('content-calendar-panel')), findsOneWidget);
        expect(find.text('Novembro 2026'), findsOneWidget);

        final calItem = find.byKey(const Key('cal-item-cnt-1'));
        await tester.ensureVisible(calItem);
        await tester.tap(calItem);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('content-hash-panel')), findsOneWidget);
      },
    );

    testWidgets(
      'Content Studio e Calendário renderizam sem overflow em 390x844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-open-drawer-btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('vyron-nav-content')));
        await tester.pumpAndSettle();

        expect(
          find.text('Content Studio & Aprovação por Hash'),
          findsOneWidget,
        );

        await tester.tap(find.text('Calendário Editorial'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('content-calendar-panel')), findsOneWidget);
      },
    );

    testWidgets(
      'Channels filtra plataformas, sincroniza demo, detalha comparação e cria canal',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-nav-channels')));
        await tester.pumpAndSettle();

        expect(find.text('Gestão de Canais'), findsOneWidget);
        expect(find.text('Audiência total agregada'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('channels-platform-filter')),
            matching: find.text('YouTube'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) =>
                w.key == const Key('channel-row-ch-apex-yt') ||
                w.key == const Key('channel-card-ch-apex-yt'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('channel-sync-ch-apex-yt')));
        await tester.pumpAndSettle();

        final bar = find.byKey(const Key('vyron-bar-item-ch-apex-yt'));
        await tester.ensureVisible(bar);
        await tester.tap(bar);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('channels-selected-detail')),
          findsOneWidget,
        );

        final addChannelBtn = find.byKey(const Key('channels-add-btn'));
        await tester.ensureVisible(addChannelBtn);
        await tester.tap(addChannelBtn);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('create-channel-name')),
          'Kinetix Shorts Lab',
        );
        await tester.enterText(
          find.byKey(const Key('create-channel-handle')),
          '@kinetixshorts',
        );
        final createChannelSubmit = find.byKey(
          const Key('create-channel-submit'),
        );
        await tester.ensureVisible(createChannelSubmit);
        await tester.tap(createChannelSubmit);
        await tester.pumpAndSettle();

        expect(find.text('Kinetix Shorts Lab'), findsWidgets);
      },
    );

    testWidgets(
      'Analytics preserva status de estimativa, alterna métricas/idioma e exporta CSV em desktop e mobile',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-nav-analytics')));
        await tester.pumpAndSettle();

        expect(find.text('Analytics & Inteligência'), findsOneWidget);
        expect(
          find.textContaining('Estimativa [Em investigação]'),
          findsWidgets,
        );

        await tester.tap(find.text('CTR (%)'));
        await tester.pumpAndSettle();

        final langSwitch = find.text('Idioma');
        await tester.ensureVisible(langSwitch);
        await tester.tap(langSwitch);
        await tester.pumpAndSettle();
        expect(find.text('EN-US (Inglês)'), findsOneWidget);

        final exportBtn = find.byKey(const Key('analytics-export-btn'));
        await tester.ensureVisible(exportBtn);
        await tester.tap(exportBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('analytics-export-notice')),
          findsOneWidget,
        );
      },
    );
  });
}
