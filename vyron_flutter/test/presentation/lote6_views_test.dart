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

void main() {
  group('Lote 6 — Overview, Brands & Products', () {
    testWidgets(
      'Overview exibe separação financeira, gráfico interativo, drilldown de marca e Stop All rápido em 1280x800',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        expect(find.text('Overview Operacional'), findsOneWidget);
        expect(find.text('Caixa recebido líquido'), findsOneWidget);
        expect(find.text('Resultado comercial confirmado'), findsOneWidget);
        expect(find.text('Comissões pendentes (não-caixa)'), findsOneWidget);
        expect(find.text('Eficiência operacional'), findsOneWidget);

        final brandBar = find.byKey(const Key('vyron-bar-item-brand-apex'));
        await tester.ensureVisible(brandBar);
        await tester.tap(brandBar);
        await tester.pumpAndSettle();

        expect(find.text('Abrir detalhes da marca'), findsOneWidget);

        final quickHalt = find.byKey(const Key('overview-quick-halt-btn'));
        await tester.ensureVisible(quickHalt);
        await tester.tap(quickHalt);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-halted-banner')), findsOneWidget);
      },
    );

    testWidgets('Overview renderiza sem overflow em viewport mobile 390x844', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildAuthorizedApp());
      await tester.pumpAndSettle();

      expect(find.text('Overview Operacional'), findsOneWidget);
      expect(find.text('Caixa recebido líquido'), findsOneWidget);
    });

    testWidgets(
      'Brands permite filtrar status, comparar, criar nova marca, editar e arquivar/reativar',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-nav-brands')));
        await tester.pumpAndSettle();

        expect(find.text('Gestão de Marcas'), findsOneWidget);

        await tester.tap(find.byKey(const Key('brands-compare-toggle')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('brands-compare-panel')), findsOneWidget);

        await tester.tap(find.text('Pausadas'));
        await tester.pumpAndSettle();
        expect(find.text('Veloce Casa'), findsWidgets);
        expect(find.text('Apex Hardware Lab'), findsNothing);

        await tester.tap(find.byKey(const Key('brands-new-btn')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('create-brand-name')),
          'Vector Optics Lab',
        );
        await tester.enterText(
          find.byKey(const Key('create-brand-niche')),
          'Fotografia técnica',
        );
        await tester.tap(find.byKey(const Key('create-brand-submit')));
        await tester.pumpAndSettle();

        expect(find.text('Vector Optics Lab'), findsWidgets);
        expect(find.byKey(const Key('brand-detail-edit-btn')), findsOneWidget);

        await tester.tap(find.byKey(const Key('brand-detail-edit-btn')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('edit-brand-name')),
          'Vector Optics Pro',
        );
        await tester.tap(find.byKey(const Key('edit-brand-submit')));
        await tester.pumpAndSettle();
        expect(find.text('Vector Optics Pro'), findsWidgets);

        await tester.tap(find.byKey(const Key('brand-detail-archive-btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('brand-detail-reactivate-btn')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Products separa moedas nativas, preserva nulos, compara produtos, exige justificativa e origina pauta no Studio',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildAuthorizedApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vyron-nav-products')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(VyronPageHeader),
            matching: find.text('Products & Intelligence'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Moeda BRL'), findsOneWidget);
        expect(find.textContaining('Moeda USD'), findsOneWidget);
        expect(find.textContaining('Moeda EUR'), findsOneWidget);
        expect(
          find.textContaining('Produto Seed Pipeline Lote 5'),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('products-test-toggle')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Produto Seed Pipeline Lote 5'),
          findsWidgets,
        );

        final cmp1 = find.byKey(const Key('product-compare-prod-keychron-q1'));
        final cmp2 = find.byKey(const Key('product-compare-prod-dell-oled'));
        await tester.ensureVisible(cmp1);
        await tester.tap(cmp1);
        await tester.pumpAndSettle();
        await tester.ensureVisible(cmp2);
        await tester.tap(cmp2);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('products-compare-panel')), findsOneWidget);
        final clearCompareBtn = find.byKey(const Key('products-compare-clear'));
        await tester.ensureVisible(clearCompareBtn);
        await tester.tap(clearCompareBtn);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('products-compare-panel')), findsNothing);

        final analyzeErgo = find.byKey(
          const Key('product-analyze-prod-ergo-chair-x'),
        );
        await tester.ensureVisible(analyzeErgo);
        await tester.tap(analyzeErgo);
        await tester.pumpAndSettle();

        expect(find.textContaining('Herman Miller Embody'), findsWidgets);

        final approveBtn = find.byKey(const Key('product-approve-btn'));
        await tester.ensureVisible(approveBtn);
        await tester.tap(approveBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('product-decision-confirm')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Informe uma justificativa objetiva para registrar no histórico.',
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('product-decision-justification')),
          'EPC validado e cookie de 30 dias favorável.',
        );
        await tester.tap(find.byKey(const Key('product-decision-confirm')));
        await tester.pumpAndSettle();

        final generateBtn = find.byKey(
          const Key('product-generate-content-btn'),
        );
        await tester.ensureVisible(generateBtn);
        await tester.tap(generateBtn);
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
  });
}
