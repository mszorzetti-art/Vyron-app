import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/app.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/security/vyron_access_rules.dart';
import 'package:vyron/core/theme/vyron_colors.dart';
import 'package:vyron/core/theme/vyron_theme.dart';
import 'package:vyron/core/widgets/vyron_mark.dart';
import 'package:vyron/data/storage/atomic_state_storage.dart';

Widget _buildTestRoot({bool authorized = false}) {
  final session = authorized
      ? buildAuthenticatedSession(
          VyronAccessSession.initial(),
          DateTime.now().millisecondsSinceEpoch,
        )
      : VyronAccessSession.initial();
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
  group('Lote 0 & Lote 4 — Identidade Visual e Bootstrap', () {
    test('preserva exatamente a paleta oficial Graphite & Cobalt', () {
      expect(VyronColors.obsidianBlack.toARGB32(), 0xFF101216);
      expect(VyronColors.graphite.toARGB32(), 0xFF292E36);
      expect(VyronColors.electricCobalt.toARGB32(), 0xFF315FEA);
      expect(VyronColors.titanium.toARGB32(), 0xFFAEB7C2);
      expect(VyronColors.coolWhite.toARGB32(), 0xFFF1F2F3);
    });

    test(
      'configura fontes oficiais DM Sans, Plus Jakarta Sans e JetBrains Mono',
      () {
        final dark = VyronTheme.dark();
        final light = VyronTheme.light();

        expect(dark.scaffoldBackgroundColor, VyronColors.obsidianBlack);
        expect(light.scaffoldBackgroundColor, VyronColors.coolWhite);
        expect(dark.textTheme.bodyLarge?.fontFamily, VyronTypography.sans);
        expect(
          dark.textTheme.headlineMedium?.fontFamily,
          VyronTypography.display,
        );
        expect(dark.textTheme.labelSmall?.fontFamily, VyronTypography.mono);
      },
    );

    testWidgets(
      'renderiza marca VYRON na tela de acesso em 390x844 preservando proporção',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildTestRoot());
        await tester.pumpAndSettle();

        expect(find.byType(VyronMark), findsOneWidget);
        expect(find.text('VYRON'), findsOneWidget);

        final markSize = tester.getSize(find.byType(VyronMark));
        expect(
          markSize.height / markSize.width,
          closeTo(VyronMark.aspectRatio, 0.01),
        );
      },
    );

    testWidgets(
      'alterna tema escuro/claro no shell autenticado sem overflow em 390x844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildTestRoot(authorized: true));
        await tester.pumpAndSettle();

        final toggle = find.byKey(const Key('vyron-theme-toggle-btn'));
        expect(toggle, findsOneWidget);

        await tester.tap(toggle);
        await tester.pumpAndSettle();

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, ThemeMode.light);
      },
    );

    testWidgets('renderiza sem overflow em viewport desktop/tablet 1280x800', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildTestRoot(authorized: true));
      await tester.pumpAndSettle();
      expect(find.byType(VyronWordmark), findsOneWidget);
    });
  });
}
