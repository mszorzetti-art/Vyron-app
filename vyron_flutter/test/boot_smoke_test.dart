import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/app.dart';
import 'package:vyron/application/state/vyron_access_notifier.dart';
import 'package:vyron/application/state/vyron_state_notifier.dart';
import 'package:vyron/core/security/secure_access_storage.dart';
import 'package:vyron/core/theme/vyron_colors.dart';
import 'package:vyron/core/theme/vyron_theme.dart';
import 'package:vyron/core/widgets/vyron_mark.dart';
import 'package:vyron/data/storage/atomic_state_storage.dart';

Widget _buildTestRoot() {
  return ProviderScope(
    overrides: [
      vyronStateStorageProvider.overrideWithValue(InMemoryVyronStateStorage()),
      vyronAccessStorageProvider.overrideWithValue(InMemoryAccessStorage()),
    ],
    child: const VyronBootstrapApp(),
  );
}

void main() {
  group('Lote 0 — Identidade Visual e Fundação', () {
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
      'renderiza marca VYRON, alterna tema e preserva proporção em 390x844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildTestRoot());
        await tester.pump();

        expect(find.byType(VyronMark), findsOneWidget);
        expect(find.text('VYRON'), findsOneWidget);
        expect(find.text('com.marcuszorzetti.vyron'), findsOneWidget);

        final markSize = tester.getSize(find.byType(VyronMark));
        expect(
          markSize.height / markSize.width,
          closeTo(VyronMark.aspectRatio, 0.01),
        );

        await tester.tap(find.text('Modo Claro'));
        await tester.pumpAndSettle();
        expect(find.text('Modo Escuro'), findsOneWidget);
      },
    );

    testWidgets(
      'renderiza sem overflow em viewport desktop/tablet 1280x800',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildTestRoot());
        await tester.pump();
        expect(find.byType(VyronWordmark), findsOneWidget);
      },
    );
  });
}
