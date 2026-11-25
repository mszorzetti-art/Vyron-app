import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/core/i18n/formatters.dart';
import 'package:vyron/core/theme/vyron_colors.dart';
import 'package:vyron/core/theme/vyron_theme.dart';
import 'package:vyron/domain/charts/chart_series.dart';
import 'package:vyron/domain/models/vyron_enums.dart';
import 'package:vyron/presentation/charts/vyron_charts.dart';

List<VyronSeriesConfig> _sampleSeries() => const [
  VyronSeriesConfig(
    id: 'confirmed',
    label: 'Comercial confirmado',
    color: VyronColors.electricCobalt,
    areaFill: true,
  ),
  VyronSeriesConfig(
    id: 'received',
    label: 'Recebido em caixa',
    color: VyronColors.emerald,
  ),
  VyronSeriesConfig(
    id: 'projection',
    label: 'Projeção isolada',
    color: VyronColors.titanium,
    dashed: true,
    isProjection: true,
  ),
];

List<VyronTimeSeriesPoint> _samplePoints() => const [
  VyronTimeSeriesPoint(
    id: 'pt-1',
    label: '01/11',
    fullDateLabel: '01/11/2026',
    values: {'confirmed': 1200, 'received': 800, 'projection': null},
  ),
  VyronTimeSeriesPoint(
    id: 'pt-2',
    label: '08/11',
    fullDateLabel: '08/11/2026',
    values: {'confirmed': 2400, 'received': 1400, 'projection': null},
  ),
  VyronTimeSeriesPoint(
    id: 'pt-3',
    label: '15/11',
    fullDateLabel: '15/11/2026',
    values: {'confirmed': 3600, 'received': 2100, 'projection': 3600},
  ),
  VyronTimeSeriesPoint(
    id: 'pt-4',
    label: '15/12',
    fullDateLabel: '15/12/2026',
    isProjection: true,
    values: {'confirmed': null, 'received': null, 'projection': 5100},
  ),
];

void main() {
  group('Lote 5 — Geometria pura e cálculo de deltas', () {
    test('TimeSeriesChartGeometry calcula escala Y, snap de índice e evita colisão X', () {
      final points = [
        for (var i = 0; i < 24; i++)
          VyronTimeSeriesPoint(
            id: 'd-$i',
            label: '${(i + 1).toString().padLeft(2, '0')}/11',
            values: {'confirmed': 100.0 * (i + 1)},
          ),
      ];
      final geometry = TimeSeriesChartGeometry(
        size: const Size(640, 240),
        points: points,
        visibleSeries: [_sampleSeries().first],
      );

      expect(geometry.yMin, 0.0);
      expect(geometry.yMax, greaterThan(2400.0));
      expect(geometry.yTicks.length, 5);
      expect(geometry.findNearestIndex(0), 0);
      expect(geometry.findNearestIndex(9999), 23);

      final visibleX = geometry.computeVisibleXIndices();
      expect(visibleX.contains(0), isTrue);
      expect(visibleX.length, lessThan(24));
    });

    test(
      'computePointDeltaText formata delta absoluto e percentual em PT-BR',
      () {
        final delta = computePointDeltaText(
          points: _samplePoints(),
          visibleSeries: _sampleSeries(),
          activeIdx: 1,
          defaultFormatter: (v) =>
              formatCurrencyForLang(v, CurrencyCode.brl, UiLanguage.ptBR),
          language: UiLanguage.ptBR,
        );
        expect(delta, isNotNull);
        expect(delta, contains('+100,0%'));
      },
    );
  });

  group('Lote 5 — Widgets interativos de gráficos', () {
    testWidgets(
      'VyronChartTimeframeToolbar alterna intervalos, datas custom e comparação',
      (tester) async {
        var range = ChartTimeRange.d30;
        var compare = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: VyronTheme.dark(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: VyronChartTimeframeToolbar(
                      language: UiLanguage.ptBR,
                      range: range,
                      onRangeChange: (next) => setState(() => range = next),
                      customStart: '2026-10-28',
                      customEnd: '2026-11-18',
                      onCustomStartChange: (_) {},
                      onCustomEndChange: (_) {},
                      comparePrevious: compare,
                      hasPreviousData: false,
                      onToggleComparePrevious: () =>
                          setState(() => compare = !compare),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('vyron-chart-range-custom')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('vyron-chart-custom-start')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('vyron-chart-custom-end')), findsOneWidget);

        await tester.tap(find.byKey(const Key('vyron-chart-compare-prev')));
        await tester.pumpAndSettle();

        expect(find.text('Comparando período anterior'), findsOneWidget);
        expect(find.textContaining('28/10/2026'), findsWidgets);
      },
    );

    testWidgets(
      'VyronInteractiveTimeSeriesChart suporta pin por toque, tooltip, legendas e Tabela de dados em 1280x800',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        String? selectedId;

        await tester.pumpWidget(
          MaterialApp(
            theme: VyronTheme.dark(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: VyronInteractiveTimeSeriesChart(
                      language: UiLanguage.ptBR,
                      points: _samplePoints(),
                      series: _sampleSeries(),
                      formatValue: (v) => formatCurrencyForLang(
                        v,
                        CurrencyCode.brl,
                        UiLanguage.ptBR,
                      ),
                      semanticLabel: 'Série temporal financeira',
                      selectedPointId: selectedId,
                      onSelectPoint: (pt, _) =>
                          setState(() => selectedId = pt?.id),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-chart-canvas')), findsOneWidget);
        expect(find.textContaining('Passe o cursor ou toque'), findsOneWidget);

        // Toque no segundo ponto (aprox. 1/3 horizontal dentro do canvas)
        final canvasBox = tester.getRect(
          find.byKey(const Key('vyron-chart-canvas')),
        );
        await tester.tapAt(
          Offset(canvasBox.left + canvasBox.width * 0.36, canvasBox.center.dy),
        );
        await tester.pumpAndSettle();

        expect(selectedId, 'pt-2');
        expect(find.byKey(const Key('vyron-chart-tooltip')), findsOneWidget);
        expect(find.textContaining('Ponto selecionado'), findsOneWidget);
        expect(find.byKey(const Key('vyron-chart-clear-pin')), findsOneWidget);

        // Alterna legenda mantendo ao menos 1 série ativa
        await tester.tap(find.byKey(const Key('vyron-chart-legend-received')));
        await tester.pumpAndSettle();

        // Alterna para Tabela de dados e verifica marcação '—' para campos nulos
        await tester.tap(find.byKey(const Key('vyron-chart-table-toggle')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-chart-data-table')), findsOneWidget);
        expect(find.text('—'), findsWidgets);
        expect(find.text('Voltar ao gráfico'), findsOneWidget);

        await tester.tap(find.byKey(const Key('vyron-chart-clear-pin')));
        await tester.pumpAndSettle();
        expect(selectedId, isNull);
      },
    );

    testWidgets(
      'VyronInteractiveTimeSeriesChart suporta scrubbing horizontal em 390x844 sem overflow e estado vazio',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        String? selectedId;

        await tester.pumpWidget(
          MaterialApp(
            theme: VyronTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        VyronInteractiveTimeSeriesChart(
                          language: UiLanguage.ptBR,
                          points: _samplePoints(),
                          series: _sampleSeries(),
                          formatValue: (v) => formatCurrencyForLang(
                            v,
                            CurrencyCode.brl,
                            UiLanguage.ptBR,
                          ),
                          semanticLabel: 'Gráfico mobile',
                          selectedPointId: selectedId,
                          onSelectPoint: (pt, _) =>
                              setState(() => selectedId = pt?.id),
                        ),
                        const SizedBox(height: 16),
                        VyronInteractiveTimeSeriesChart(
                          language: UiLanguage.ptBR,
                          points: const [],
                          series: _sampleSeries(),
                          formatValue: (v) => v.toString(),
                          semanticLabel: 'Gráfico vazio',
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

        expect(find.byKey(const Key('vyron-chart-empty')), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('vyron-chart-canvas')),
          const Offset(180, 0),
        );
        await tester.pumpAndSettle();

        expect(selectedId, isNotNull);
      },
    );

    testWidgets(
      'VyronInteractiveComparisonChart preserva dado ausente e destaca item selecionado',
      (tester) async {
        String? selectedBarId;

        await tester.pumpWidget(
          MaterialApp(
            theme: VyronTheme.dark(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: VyronInteractiveComparisonChart(
                      language: UiLanguage.ptBR,
                      selectedId: selectedBarId,
                      onSelect: (item) =>
                          setState(() => selectedBarId = item?.id),
                      items: const [
                        VyronComparisonBarItem(
                          id: 'prod-1',
                          label: 'Keychron Q1 Pro',
                          sublabel: 'Amazon BR · Índice 89/100',
                          value: 89,
                          formattedValue: '89/100',
                          badge: 'BRL',
                        ),
                        VyronComparisonBarItem(
                          id: 'prod-missing',
                          label: 'Loupedeck CT',
                          value: null,
                          formattedValue: 'Não disponível',
                          isMissing: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Não disponível'), findsOneWidget);
        await tester.tap(find.byKey(const Key('vyron-bar-item-prod-1')));
        await tester.pumpAndSettle();
        expect(selectedBarId, 'prod-1');

        await tester.tap(find.byKey(const Key('vyron-bar-item-prod-1')));
        await tester.pumpAndSettle();
        expect(selectedBarId, isNull);

        // Alterna modo comparação: Barras -> Tabela -> Barras
        await tester.tap(find.byKey(const Key('vyron-comparison-mode-table')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vyron-comparison-table')), findsOneWidget);
        expect(find.text('Keychron Q1 Pro'), findsOneWidget);
        expect(find.text('Não disponível'), findsOneWidget);

        await tester.tap(find.byKey(const Key('vyron-comparison-mode-bar')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vyron-bar-item-prod-1')), findsOneWidget);
      },
    );
  });

  group('Fase 10 — Curvas monótonas Fritsch-Carlson e alternância Linhas / Barras / Tabela', () {
    test('computeMonotoneCubicSegments passa pelos pontos exatos e evita overshoot em platôs e vales', () {
      const points = [
        Offset(0, 100),
        Offset(50, 20),
        Offset(100, 20),
        Offset(150, 120),
      ];
      final segments = computeMonotoneCubicSegments(points);
      expect(segments.length, 3);

      // Pontos exatos de início e fim preservados
      expect(segments.first.p0, const Offset(0, 100));
      expect(segments.last.p1, const Offset(150, 120));

      // Platô [20 -> 20] mantém controle plano sem ultrapassar abaixo de 20
      final plateau = segments[1];
      expect(plateau.cp1.dy, 20.0);
      expect(plateau.cp2.dy, 20.0);

      // Caso limite com 2 pontos gera 1 segmento cúbico linearmente alinhado
      final twoPts = computeMonotoneCubicSegments(const [
        Offset(0, 10),
        Offset(60, 40),
      ]);
      expect(twoPts.length, 1);
      expect(twoPts.single.p0, const Offset(0, 10));
      expect(twoPts.single.p1, const Offset(60, 40));
    });

    testWidgets(
      'VyronInteractiveTimeSeriesChart alterna Linhas -> Barras -> Tabela -> Barras sem distorcer dados',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: VyronTheme.dark(),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: VyronInteractiveTimeSeriesChart(
                  language: UiLanguage.ptBR,
                  points: _samplePoints(),
                  series: _sampleSeries(),
                  formatValue: (v) => formatCurrencyForLang(
                    v,
                    CurrencyCode.brl,
                    UiLanguage.ptBR,
                  ),
                  semanticLabel: 'Série temporal Fase 10',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('vyron-chart-mode-line')), findsOneWidget);
        expect(find.byKey(const Key('vyron-chart-mode-bar')), findsOneWidget);
        expect(
          find.byKey(const Key('vyron-chart-table-toggle')),
          findsOneWidget,
        );

        // Alterna para Gráfico de Barras agrupadas
        await tester.tap(find.byKey(const Key('vyron-chart-mode-bar')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vyron-chart-canvas')), findsOneWidget);

        // Alterna para Tabela de dados e volta ao modo anterior (Barras)
        await tester.tap(find.byKey(const Key('vyron-chart-table-toggle')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vyron-chart-data-table')), findsOneWidget);

        await tester.tap(find.byKey(const Key('vyron-chart-table-toggle')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vyron-chart-canvas')), findsOneWidget);

        // Alterna de volta para Linhas suavizadas
        await tester.tap(find.byKey(const Key('vyron-chart-mode-line')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vyron-chart-canvas')), findsOneWidget);
      },
    );
  });
}
