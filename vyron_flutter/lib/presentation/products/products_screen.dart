import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/routing/vyron_router.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/charts/chart_series.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';
import '../charts/vyron_charts.dart';

enum _ProductsViewMode { byCurrency, catalog }

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({
    super.key,
    this.productId,
  });

  final String? productId;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  _ProductsViewMode _viewMode = _ProductsViewMode.byCurrency;
  String _statusFilter = 'all';
  String _search = '';
  final List<String> _compareIds = [];
  CurrencyCode _chartCurrency = CurrencyCode.brl;
  ProductChartMetric _chartMetric = ProductChartMetric.opportunityScore;
  String? _selectedChartProductId;

  void _toggleCompare(String id) {
    setState(() {
      if (_compareIds.contains(id)) {
        _compareIds.remove(id);
      } else if (_compareIds.length < 3) {
        _compareIds.add(id);
      }
    });
  }

  String _formatChartMetricValue(
    Product p,
    ProductChartMetric metric,
    UiLanguage lang,
  ) {
    final tNotInformed = translate(lang, 'products.notInformed');
    return switch (metric) {
      ProductChartMetric.opportunityScore =>
        p.opportunityScore != null ? '${p.opportunityScore}/100' : tNotInformed,
      ProductChartMetric.epcValue => p.epcValue != null
          ? formatCurrencyForLang(p.epcValue!, p.currency, lang)
          : tNotInformed,
      ProductChartMetric.commissionRatePct => p.commissionRatePct != null
          ? formatPercentForLang(p.commissionRatePct!, lang, 1)
          : tNotInformed,
      ProductChartMetric.demandTrendPct => p.demandTrendPct != null
          ? '${p.demandTrendPct! > 0 ? '+' : ''}${formatPercentForLang(p.demandTrendPct!, lang, 1)}'
          : tNotInformed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final effectiveProductId = widget.productId ?? appState.selectedProductId;

    if (effectiveProductId != null && effectiveProductId.isNotEmpty) {
      return _ProductDetailView(productId: effectiveProductId);
    }

    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final excludeTestData = appState.excludeTestData;
    final globalBrandFilter = appState.globalBrandFilter;

    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    final query = _search.trim().toLowerCase();
    final filteredProducts = domain.products
        .map((p) => localizeProduct(p, lang))
        .where((p) {
      if (excludeTestData && p.isTest) return false;
      if (globalBrandFilter != 'all' &&
          p.brandId != globalBrandFilter &&
          !p.linkedBrandIds.contains(globalBrandFilter)) {
        return false;
      }
      if (_statusFilter != 'all' && p.status.wire != _statusFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final hay =
            '${p.name} ${p.platform} ${p.category} ${p.externalId}'.toLowerCase();
        if (!hay.contains(query)) return false;
      }
      return true;
    }).toList();

    final currencyGroups = groupProductsByCurrency(filteredProducts);

    final chartComparisonRaw = buildProductNativeCurrencyComparison(
      domain.products.map((p) => localizeProduct(p, lang)).toList(),
      _chartCurrency,
      _chartMetric,
      excludeTest: excludeTestData,
      brandId: globalBrandFilter,
    );

    final chartBars = chartComparisonRaw.map((item) {
      final p = item.product;
      final brandNames = p.linkedBrandIds
          .map(
            (id) => domain.brands
                .cast<Brand?>()
                .firstWhere((b) => b?.id == id, orElse: () => null)
                ?.name,
          )
          .whereType<String>()
          .join(', ');
      return VyronComparisonBarItem(
        id: p.id,
        label: p.name,
        sublabel:
            '${p.platform} · ${brandNames.isNotEmpty ? brandNames : p.brandId}',
        value: item.value,
        formattedValue: _formatChartMetricValue(p, _chartMetric, lang),
        badge: labelProductStatus(p.status, lang),
        isMissing: item.missingData,
        color: item.missingData ? VyronColors.amber : VyronColors.electricCobalt,
      );
    }).toList();

    Product? selectedChartProd;
    if (_selectedChartProductId != null) {
      for (final p in domain.products) {
        if (p.id == _selectedChartProductId) {
          selectedChartProd = localizeProduct(p, lang);
          break;
        }
      }
    }

    final compareProducts = _compareIds
        .map(
          (id) => domain.products
              .cast<Product?>()
              .firstWhere((p) => p?.id == id, orElse: () => null),
        )
        .whereType<Product>()
        .map((p) => localizeProduct(p, lang))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: t('products.title'),
          subtitle: t('products.subtitle'),
          actions: [
            VyronToggleSwitch(
              key: const Key('products-test-toggle'),
              value: !excludeTestData,
              compact: true,
              label: t('products.showTestData'),
              onChanged: (v) => notifier.setExcludeTestData(!v),
            ),
            ElevatedButton.icon(
              key: const Key('products-add-btn'),
              onPressed: () => _openCreateProductModal(context, lang),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t('products.addProduct')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // View mode + Status filter + Search
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              label: t('products.viewModeAria'),
              child: VyronSegmentedControl<_ProductsViewMode>(
                options: [
                  VyronSegmentOption(
                    value: _ProductsViewMode.byCurrency,
                    label: t('products.viewByCurrency'),
                  ),
                  VyronSegmentOption(
                    value: _ProductsViewMode.catalog,
                    label: t('products.viewCatalog'),
                  ),
                ],
                value: _viewMode,
                onChanged: (m) => setState(() => _viewMode = m),
              ),
            ),
            SizedBox(
              width: 190,
              child: VyronDropdownField<String>(
                value: _statusFilter,
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(t('common.all')),
                  ),
                  for (final st in ProductStatus.values)
                    DropdownMenuItem(
                      value: st.wire,
                      child: Text(labelProductStatus(st, lang)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _statusFilter = v);
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
              child: TextField(
                key: const Key('products-search-input'),
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: t('products.searchPlaceholder'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interactive Native Currency Chart
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final controls = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        label: t('products.chart.currencyAria'),
                        child: VyronSegmentedControl<CurrencyCode>(
                          options: const [
                            VyronSegmentOption(
                              value: CurrencyCode.brl,
                              label: 'BRL',
                            ),
                            VyronSegmentOption(
                              value: CurrencyCode.usd,
                              label: 'USD',
                            ),
                            VyronSegmentOption(
                              value: CurrencyCode.eur,
                              label: 'EUR',
                            ),
                          ],
                          value: _chartCurrency,
                          onChanged: (c) => setState(() {
                            _chartCurrency = c;
                            _selectedChartProductId = null;
                          }),
                        ),
                      ),
                      Semantics(
                        label: t('products.chart.metricAria'),
                        child: VyronSegmentedControl<ProductChartMetric>(
                          options: [
                            VyronSegmentOption(
                              value: ProductChartMetric.opportunityScore,
                              label: t('products.chart.metricScore'),
                            ),
                            VyronSegmentOption(
                              value: ProductChartMetric.epcValue,
                              label: t('products.chart.metricEpc'),
                            ),
                            VyronSegmentOption(
                              value: ProductChartMetric.commissionRatePct,
                              label: t('products.chart.metricCommission'),
                            ),
                            VyronSegmentOption(
                              value: ProductChartMetric.demandTrendPct,
                              label: t('products.chart.metricTrend'),
                            ),
                          ],
                          value: _chartMetric,
                          onChanged: (m) => setState(() => _chartMetric = m),
                        ),
                      ),
                    ],
                  );

                  if (constraints.maxWidth >= 820) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VyronSectionTitle(
                            title: t('products.chart.title'),
                            subtitle: t('products.chart.subtitle'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        controls,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VyronSectionTitle(
                        title: t('products.chart.title'),
                        subtitle: t('products.chart.subtitle'),
                      ),
                      const SizedBox(height: 10),
                      controls,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              VyronInteractiveComparisonChart(
                language: lang,
                items: chartBars,
                selectedId: _selectedChartProductId,
                onSelect: (bar) => setState(() {
                  _selectedChartProductId = bar?.id;
                }),
              ),
              if (selectedChartProd != null) ...[
                const SizedBox(height: 12),
                _ProductChartDrilldown(
                  product: selectedChartProd,
                  linkedContentsCount: domain.contents
                      .where((c) => c.productId == selectedChartProd!.id)
                      .length,
                  language: lang,
                  onClose: () =>
                      setState(() => _selectedChartProductId = null),
                  onOpenDossier: () => navigateToVyronModule(
                    ref,
                    NavModule.products,
                    productId: selectedChartProd!.id,
                    setProductId: true,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Side-by-side compare panel (2 to 3 products)
        if (compareProducts.length >= 2) ...[
          VyronSurfacePanel(
            key: const Key('products-compare-panel'),
            borderColor: VyronColors.electricCobalt.withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VyronSectionTitle(
                  title: t(
                    'products.comparePanelTitle',
                    {'count': '${compareProducts.length}'},
                  ),
                  trailing: TextButton(
                    key: const Key('products-compare-clear'),
                    onPressed: () => setState(_compareIds.clear),
                    child: Text(t('products.compareClear')),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 46,
                        columnSpacing: 18,
                        horizontalMargin: 8,
                        columns: [
                          DataColumn(
                            label: Text(t('products.compareCriterion')),
                          ),
                          for (final p in compareProducts)
                            DataColumn(
                              label: Text(
                                '${p.name} (${p.currency.wire})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                        rows: [
                          DataRow(
                            cells: [
                              DataCell(Text(t('products.compareScore'))),
                              for (final p in compareProducts)
                                DataCell(
                                  Text(
                                    p.opportunityScore != null
                                        ? '${p.opportunityScore}/100'
                                        : t('products.unknownNull'),
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text(t('products.comparePriceComm'))),
                              for (final p in compareProducts)
                                DataCell(
                                  Text(
                                    '${p.price != null ? formatCurrencyForLang(p.price!, p.currency, lang) : t('common.na')} · ${p.commissionRatePct != null ? formatPercentForLang(p.commissionRatePct!, lang, 1) : t('common.na')}',
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(
                                Text(t('products.compareEpcCookieGrade')),
                              ),
                              for (final p in compareProducts)
                                DataCell(
                                  Text(
                                    '${p.epcValue != null ? formatCurrencyForLang(p.epcValue!, p.currency, lang) : t('products.notInformed')} · ${p.cookieWindowDays != null ? t('common.daysShort', {'days': '${p.cookieWindowDays}'}) : t('common.na')} · ${labelProductGradeBadge(p.qualityGrade, lang)}',
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      color: p.epcValue == null
                                          ? (isDark
                                              ? VyronColors.amberDarkText
                                              : VyronColors.amberLightText)
                                          : palette.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Catalog listings
        if (filteredProducts.isEmpty)
          VyronEmptyState(
            title: t('products.emptyTitle'),
            description: t('products.emptyDesc'),
            actionLabel: t('products.addProduct'),
            onAction: () => _openCreateProductModal(context, lang),
          )
        else if (_viewMode == _ProductsViewMode.byCurrency)
          for (final group in currencyGroups) ...[
            VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t(
                      'products.currencyGroupTitle',
                      {
                        'currency': group.currency.wire,
                        'count': '${group.items.length}',
                      },
                    ),
                    subtitle: t('products.currencyGroupHint'),
                  ),
                  const SizedBox(height: 12),
                  _ProductsCatalogList(
                    products: group.items,
                    brands: domain.brands,
                    currencyHeader: group.currency.wire,
                    language: lang,
                    compareIds: _compareIds,
                    onToggleCompare: _toggleCompare,
                    onAnalyze: (p) => navigateToVyronModule(
                      ref,
                      NavModule.products,
                      productId: p.id,
                      setProductId: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]
        else
          VyronSurfacePanel(
            child: _ProductsCatalogList(
              products: filteredProducts,
              brands: domain.brands,
              currencyHeader: '-',
              language: lang,
              compareIds: _compareIds,
              onToggleCompare: _toggleCompare,
              onAnalyze: (p) => navigateToVyronModule(
                ref,
                NavModule.products,
                productId: p.id,
                setProductId: true,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openCreateProductModal(
    BuildContext context,
    UiLanguage lang,
  ) async {
    final domain = ref.read(vyronStateProvider).domain;
    if (domain.brands.isEmpty) return;

    final created = await showVyronModalDialog<Product>(
      context: context,
      title: translate(lang, 'products.modal.createTitle'),
      subtitle: translate(lang, 'products.modal.createSubtitle'),
      language: lang,
      maxWidth: 560,
      builder: (_) => _CreateProductDialogBody(
        language: lang,
        brands: domain.brands,
        onCreate: (input) =>
            ref.read(vyronStateProvider.notifier).createProduct(input),
      ),
    );

    if (created != null && mounted) {
      navigateToVyronModule(
        ref,
        NavModule.products,
        productId: created.id,
        setProductId: true,
      );
    }
  }
}

class _ProductChartDrilldown extends StatelessWidget {
  const _ProductChartDrilldown({
    required this.product,
    required this.linkedContentsCount,
    required this.language,
    required this.onClose,
    required this.onOpenDossier,
  });

  final Product product;
  final int linkedContentsCount;
  final UiLanguage language;
  final VoidCallback onClose;
  final VoidCallback onOpenDossier;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key, [Map<String, String>? params]) =>
        translate(language, key, params);

    final hasMissing =
        product.epcValue == null || product.opportunityScore == null;

    return Container(
      key: const Key('products-chart-drilldown'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? VyronColors.obsidianBlack : VyronColors.coolWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: VyronColors.electricCobalt.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t('products.chart.drillTitle')} · ${product.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 16),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Text(
                '${product.platform} · ${product.category}',
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
              Text(
                product.opportunityScore != null
                    ? '${t('products.table.score')}: ${product.opportunityScore}/100'
                    : '${t('products.table.score')}: ${t('products.unknownNull')}',
                style: const TextStyle(
                  fontFamily: VyronTypography.mono,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                product.epcValue != null
                    ? 'EPC: ${formatCurrencyForLang(product.epcValue!, product.currency, language)}'
                    : 'EPC: ${t('products.notInformed')}',
                style: TextStyle(
                  fontFamily: VyronTypography.mono,
                  fontSize: 11.5,
                  color: product.epcValue == null
                      ? (isDark
                          ? VyronColors.amberDarkText
                          : VyronColors.amberLightText)
                      : palette.textPrimary,
                ),
              ),
              Text(
                t(
                  'products.chart.drillContents',
                  {'count': '$linkedContentsCount'},
                ),
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
            ],
          ),
          if (hasMissing) ...[
            const SizedBox(height: 8),
            VyronToneBadge(
              label: t('products.chart.drillMissing'),
              tone: VyronMetricTone.amber,
            ),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onOpenDossier,
            child: Text(t('products.chart.openDossier')),
          ),
        ],
      ),
    );
  }
}

class _ProductsCatalogList extends StatelessWidget {
  const _ProductsCatalogList({
    required this.products,
    required this.brands,
    required this.currencyHeader,
    required this.language,
    required this.compareIds,
    required this.onToggleCompare,
    required this.onAnalyze,
  });

  final List<Product> products;
  final List<Brand> brands;
  final String currencyHeader;
  final UiLanguage language;
  final List<String> compareIds;
  final ValueChanged<String> onToggleCompare;
  final ValueChanged<Product> onAnalyze;

  String _brandLabel(Product p) {
    final names = p.linkedBrandIds
        .map(
          (id) => brands
              .cast<Brand?>()
              .firstWhere((b) => b?.id == id, orElse: () => null)
              ?.name,
        )
        .whereType<String>()
        .toList();
    return names.isNotEmpty ? names.join(', ') : p.brandId;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key, [Map<String, String>? params]) =>
        translate(language, key, params);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 74,
                columnSpacing: 14,
                horizontalMargin: 8,
                columns: [
                  DataColumn(label: Text(t('products.table.compareShort'))),
                  DataColumn(label: Text(t('products.table.productCatalog'))),
                  DataColumn(label: Text(t('products.table.brands'))),
                  DataColumn(
                    label: Text(t('products.table.qualityCompliance')),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      t('products.table.price', {'currency': currencyHeader}),
                    ),
                  ),
                  DataColumn(label: Text(t('products.table.commEpc'))),
                  DataColumn(label: Text(t('products.table.cookie'))),
                  DataColumn(
                    numeric: true,
                    label: Text(t('products.table.score')),
                  ),
                  DataColumn(label: Text(t('products.table.state'))),
                  DataColumn(label: Text(t('products.table.action'))),
                ],
                rows: [
                  for (final p in products)
                    DataRow(
                      cells: [
                        DataCell(
                          Checkbox(
                            key: Key('product-compare-${p.id}'),
                            value: compareIds.contains(p.id),
                            onChanged: (_) => onToggleCompare(p.id),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 210),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Text(
                                      '${p.platform} · ${p.externalId}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                    if (p.isTest)
                                      VyronToneBadge(
                                        label: t('products.table.testTag'),
                                        tone: VyronMetricTone.amber,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              _brandLabel(p),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              VyronToneBadge(
                                label:
                                    labelProductGradeBadge(p.qualityGrade, language),
                                tone: p.qualityGrade == ProductQualityGrade.a
                                    ? VyronMetricTone.emerald
                                    : p.qualityGrade == ProductQualityGrade.c
                                        ? VyronMetricTone.crimson
                                        : VyronMetricTone.neutral,
                              ),
                              VyronStatusLabel(
                                status: labelComplianceState(
                                  p.complianceState,
                                  language,
                                ),
                                statusKey: p.complianceState.wire,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            p.price != null
                                ? formatCurrencyForLang(
                                    p.price!,
                                    p.currency,
                                    language,
                                  )
                                : t('common.na'),
                            style: const TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.commissionRatePct != null
                                    ? formatPercentForLang(
                                        p.commissionRatePct!,
                                        language,
                                        1,
                                      )
                                    : (p.cpaValue != null
                                        ? 'CPA ${formatCurrencyForLang(p.cpaValue!, p.currency, language)}'
                                        : t('common.na')),
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 11.5,
                                ),
                              ),
                              Text(
                                p.epcValue != null
                                    ? 'EPC ${formatCurrencyForLang(p.epcValue!, p.currency, language)}'
                                    : 'EPC ${t('products.notInformed')}',
                                style: TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 11,
                                  color: p.epcValue == null
                                      ? (isDark
                                          ? VyronColors.amberDarkText
                                          : VyronColors.amberLightText)
                                      : palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            p.cookieWindowDays != null
                                ? t(
                                    'common.daysShort',
                                    {'days': '${p.cookieWindowDays}'},
                                  )
                                : t('common.na'),
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            p.opportunityScore != null
                                ? '${p.opportunityScore}/100'
                                : t('common.na'),
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: p.opportunityScore != null
                                  ? palette.cobaltText
                                  : (isDark
                                      ? VyronColors.amberDarkText
                                      : VyronColors.amberLightText),
                            ),
                          ),
                        ),
                        DataCell(
                          VyronStatusLabel(
                            status: labelProductStatus(p.status, language),
                            statusKey: p.status.wire,
                          ),
                        ),
                        DataCell(
                          OutlinedButton(
                            key: Key('product-analyze-${p.id}'),
                            onPressed: () => onAnalyze(p),
                            child: Text(t('products.table.analyze')),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }

        // Mobile card layout (< 860px)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in products)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.panelBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            key: Key('product-compare-${p.id}'),
                            value: compareIds.contains(p.id),
                            onChanged: (_) => onToggleCompare(p.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.platform} · ${p.externalId} · ${_brandLabel(p)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p.opportunityScore != null
                              ? '${p.opportunityScore}/100'
                              : t('common.na'),
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.opportunityScore != null
                                ? palette.cobaltText
                                : (isDark
                                    ? VyronColors.amberDarkText
                                    : VyronColors.amberLightText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (p.isTest)
                          VyronToneBadge(
                            label: t('products.table.testTag'),
                            tone: VyronMetricTone.amber,
                          ),
                        VyronToneBadge(
                          label:
                              labelProductGradeBadge(p.qualityGrade, language),
                          tone: p.qualityGrade == ProductQualityGrade.a
                              ? VyronMetricTone.emerald
                              : p.qualityGrade == ProductQualityGrade.c
                                  ? VyronMetricTone.crimson
                                  : VyronMetricTone.neutral,
                        ),
                        VyronStatusLabel(
                          status: labelProductStatus(p.status, language),
                          statusKey: p.status.wire,
                        ),
                        Text(
                          p.price != null
                              ? formatCurrencyForLang(
                                  p.price!,
                                  p.currency,
                                  language,
                                )
                              : t('common.na'),
                          style: const TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          p.epcValue != null
                              ? 'EPC ${formatCurrencyForLang(p.epcValue!, p.currency, language)}'
                              : 'EPC ${t('products.notInformed')}',
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 11.5,
                            color: p.epcValue == null
                                ? (isDark
                                    ? VyronColors.amberDarkText
                                    : VyronColors.amberLightText)
                                : palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        key: Key('product-analyze-${p.id}'),
                        onPressed: () => onAnalyze(p),
                        child: Text(t('products.table.analyze')),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductDetailView extends ConsumerStatefulWidget {
  const _ProductDetailView({required this.productId});

  final String productId;

  @override
  ConsumerState<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<_ProductDetailView> {
  String? _selectedChannelId;
  ContentFormat _contentFormat = ContentFormat.longForm;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    Product? rawProd;
    for (final p in domain.products) {
      if (p.id == widget.productId) {
        rawProd = p;
        break;
      }
    }

    if (rawProd == null) {
      return VyronEmptyState(
        title: t('products.detail.notFoundTitle'),
        description: t('products.detail.notFoundDesc'),
        actionLabel: t('products.detail.back'),
        onAction: () => navigateToVyronModule(
          ref,
          NavModule.products,
          productId: null,
          setProductId: true,
        ),
      );
    }

    final product = localizeProduct(rawProd, lang);
    final scoreInfo = scoreProductV61(product, language: lang);
    final linkedContents =
        domain.contents.where((c) => c.productId == product.id).toList();

    Brand? primaryBrand;
    for (final b in domain.brands) {
      if (b.id == product.brandId) {
        primaryBrand = b;
        break;
      }
    }

    final availableChannels = domain.channels
        .where(
          (ch) =>
              product.linkedBrandIds.contains(ch.brandId) ||
              ch.brandId == product.brandId,
        )
        .toList();
    final fallbackChannels =
        availableChannels.isNotEmpty ? availableChannels : domain.channels;
    final resolvedChannelId = (_selectedChannelId != null &&
            fallbackChannels.any((c) => c.id == _selectedChannelId))
        ? _selectedChannelId!
        : (fallbackChannels.isNotEmpty ? fallbackChannels.first.id : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              key: const Key('product-detail-back'),
              onPressed: () => navigateToVyronModule(
                ref,
                NavModule.products,
                productId: null,
                setProductId: true,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: Text(t('products.detail.back')),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  key: const Key('product-approve-btn'),
                  onPressed: product.status == ProductStatus.approved
                      ? null
                      : () => _openDecisionModal(
                            context,
                            lang,
                            product,
                            ProductStatus.approved,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VyronColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(t('products.detail.approve')),
                ),
                OutlinedButton(
                  key: const Key('product-reject-btn'),
                  onPressed: product.status == ProductStatus.rejected
                      ? null
                      : () => _openDecisionModal(
                            context,
                            lang,
                            product,
                            ProductStatus.rejected,
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? VyronColors.crimsonDarkText
                        : VyronColors.crimsonLightText,
                  ),
                  child: Text(t('products.detail.reject')),
                ),
                OutlinedButton(
                  key: const Key('product-archive-btn'),
                  onPressed: product.status == ProductStatus.archived
                      ? null
                      : () => _openDecisionModal(
                            context,
                            lang,
                            product,
                            ProductStatus.archived,
                          ),
                  child: Text(t('products.detail.archive')),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        VyronPageHeader(
          title: product.name,
          subtitle: t(
            'products.detail.subtitle',
            {
              'platform': product.platform,
              'externalId': product.externalId,
              'currency': product.currency.wire,
              'market': labelComplianceMarket(product.complianceMarket, lang),
            },
          ),
          actions: [
            if (product.isTest)
              VyronToneBadge(
                label: t('products.table.testTag'),
                tone: VyronMetricTone.amber,
              ),
            VyronStatusLabel(
              status: labelProductStatus(product.status, lang),
              statusKey: product.status.wire,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 5 KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1120 ? 5 : (w >= 620 ? 2 : 1);
            final tileW = (w - (cols - 1) * 10) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('products.detail.kpi.score'),
                    value: scoreInfo.score != null
                        ? '${scoreInfo.score}/100'
                        : t('common.na'),
                    helper: scoreInfo.explanation,
                    tone: scoreInfo.score != null
                        ? VyronMetricTone.cobalt
                        : VyronMetricTone.amber,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('products.detail.kpi.price'),
                    value: product.price != null
                        ? formatCurrencyForLang(
                            product.price!,
                            product.currency,
                            lang,
                          )
                        : t('products.notInformed'),
                    helper: t(
                      'products.detail.kpi.comm',
                      {
                        'val': product.commissionRatePct != null
                            ? formatPercentForLang(
                                product.commissionRatePct!,
                                lang,
                                1,
                              )
                            : t('products.notInformed'),
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('products.detail.kpi.epc'),
                    value: product.epcValue != null
                        ? formatCurrencyForLang(
                            product.epcValue!,
                            product.currency,
                            lang,
                          )
                        : t('products.unknownNull'),
                    helper: product.cpaValue != null
                        ? t(
                            'products.detail.kpi.cpa',
                            {
                              'val': formatCurrencyForLang(
                                product.cpaValue!,
                                product.currency,
                                lang,
                              ),
                            },
                          )
                        : t(
                            'products.detail.kpi.confidence',
                            {
                              'val': labelDataConfidence(
                                product.dataConfidence,
                                lang,
                              ),
                            },
                          ),
                    tone: product.epcValue == null
                        ? VyronMetricTone.amber
                        : VyronMetricTone.neutral,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('products.detail.kpi.cookie'),
                    value: product.cookieWindowDays != null
                        ? t(
                            'products.detail.kpi.days',
                            {'days': '${product.cookieWindowDays}'},
                          )
                        : t('products.notInformed'),
                    helper: t(
                      'products.detail.kpi.competition',
                      {
                        'val': labelCompetitionLevel(
                          product.competitionLevel,
                          lang,
                        ),
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('products.detail.kpi.qualityCompliance'),
                    value:
                        '${labelProductGradeBadge(product.qualityGrade, lang)} · ${labelComplianceState(product.complianceState, lang)}',
                    helper: t(
                      'products.detail.kpi.linkedContents',
                      {'count': '${linkedContents.length}'},
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Governance Panel: Quality Grade + Compliance + Shared Brands
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w >= 780 ? 2 : 1;
                  final fieldW = (w - (cols - 1) * 14) / cols;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: fieldW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('products.detail.gov.qualityTitle'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontSize: 12.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t('products.detail.gov.qualityDesc'),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            VyronDropdownField<String>(
                              key: const Key('product-quality-dropdown'),
                              value: product.qualityGrade?.wire ?? 'NONE',
                              items: [
                                DropdownMenuItem(
                                  value: 'NONE',
                                  child: Text(t('common.na')),
                                ),
                                DropdownMenuItem(
                                  value: ProductQualityGrade.a.wire,
                                  child: Text(t('products.detail.gov.gradeA')),
                                ),
                                DropdownMenuItem(
                                  value: ProductQualityGrade.b.wire,
                                  child: Text(t('products.detail.gov.gradeB')),
                                ),
                                DropdownMenuItem(
                                  value: ProductQualityGrade.c.wire,
                                  child: Text(t('products.detail.gov.gradeC')),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                if (v == 'NONE') {
                                  notifier.updateProductGovernance(
                                    product.id,
                                    const ProductGovernancePatch(
                                      clearQualityGrade: true,
                                    ),
                                  );
                                } else {
                                  notifier.updateProductGovernance(
                                    product.id,
                                    ProductGovernancePatch(
                                      qualityGrade:
                                          ProductQualityGrade.fromWire(v),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: fieldW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t(
                                'products.detail.gov.complianceTitle',
                                {
                                  'market': labelComplianceMarket(
                                    product.complianceMarket,
                                    lang,
                                  ),
                                },
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontSize: 12.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t('products.detail.gov.complianceDesc'),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            VyronDropdownField<ComplianceState>(
                              key: const Key('product-compliance-dropdown'),
                              value: product.complianceState,
                              items: [
                                for (final cs in ComplianceState.values)
                                  DropdownMenuItem(
                                    value: cs,
                                    child: Text(labelComplianceState(cs, lang)),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                notifier.updateProductGovernance(
                                  product.id,
                                  ProductGovernancePatch(complianceState: v),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                t('products.detail.gov.brandsTitle'),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 3),
              Text(
                t('products.detail.gov.brandsDesc'),
                style: TextStyle(fontSize: 11.5, color: palette.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in domain.brands)
                    FilterChip(
                      key: Key('product-brand-chip-${b.id}'),
                      label: Text(b.name),
                      selected: product.linkedBrandIds.contains(b.id),
                      onSelected: (selected) {
                        final next = List<String>.from(product.linkedBrandIds);
                        if (selected) {
                          if (!next.contains(b.id)) next.add(b.id);
                        } else if (next.length > 1) {
                          next.remove(b.id);
                        }
                        notifier.updateProductGovernance(
                          product.id,
                          ProductGovernancePatch(linkedBrandIds: next),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Evidence + Generate Content Plan
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            final evidencePanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('products.detail.evidenceTitle'),
                  ),
                  const SizedBox(height: 10),
                  if (product.evidence.isEmpty)
                    Text(
                      t('products.detail.evidenceEmpty'),
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    )
                  else
                    for (final ev in product.evidence)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: palette.panelBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ev.sourceName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  t(
                                    'products.detail.verifiedAt',
                                    {
                                      'date': formatDateForLang(
                                        ev.verifiedAt,
                                        lang,
                                      ),
                                    },
                                  ),
                                  style: TextStyle(
                                    fontFamily: VyronTypography.mono,
                                    fontSize: 10.5,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ev.summary,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            );

            final studioPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t(
                      'products.detail.createContentTitle',
                      {'brand': primaryBrand?.name ?? product.brandId},
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (fallbackChannels.isNotEmpty) ...[
                    VyronDropdownField<String>(
                      labelText: t('products.detail.selectChannelAria'),
                      value: resolvedChannelId,
                      items: [
                        for (final ch in fallbackChannels)
                          DropdownMenuItem(
                            value: ch.id,
                            child: Text('${ch.name} (${ch.platform.wire})'),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedChannelId = v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  VyronDropdownField<ContentFormat>(
                    labelText: t('products.detail.selectFormatAria'),
                    value: _contentFormat,
                    items: [
                      for (final fmt in ContentFormat.values)
                        DropdownMenuItem(
                          value: fmt,
                          child: Text(labelContentFormat(fmt, lang)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _contentFormat = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    key: const Key('product-generate-content-btn'),
                    onPressed: resolvedChannelId.isEmpty
                        ? null
                        : () {
                            final created =
                                notifier.generateContentFromProduct(
                              product.id,
                              resolvedChannelId,
                              _contentFormat,
                            );
                            navigateToVyronModule(
                              ref,
                              NavModule.content,
                              contentId: created.id,
                              setContentId: true,
                              contentSubView: ContentSubView.studio,
                            );
                          },
                    icon: const Icon(Icons.auto_stories_outlined, size: 17),
                    label: Text(t('products.detail.createContentBtn')),
                  ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: evidencePanel),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: studioPanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                evidencePanel,
                const SizedBox(height: 14),
                studioPanel,
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Decisions History
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(title: t('products.detail.decisionsTitle')),
              const SizedBox(height: 10),
              if (product.decisions.isEmpty)
                Text(
                  t('products.detail.decisionsEmpty'),
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                )
              else
                for (final dec in product.decisions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${labelProductStatus(dec.previousStatus, lang)} → ${labelProductStatus(dec.newStatus, lang)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              formatDateTimeForLang(dec.timestamp, lang),
                              style: TextStyle(
                                fontFamily: VyronTypography.mono,
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dec.justification,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t(
                            'products.detail.byActor',
                            {'actor': localizeActor(dec.actor, lang)},
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDecisionModal(
    BuildContext context,
    UiLanguage lang,
    Product product,
    ProductStatus nextStatus,
  ) async {
    await showVyronModalDialog<void>(
      context: context,
      title: translate(
        lang,
        'products.modal.decisionTitle',
        {'status': labelProductStatus(nextStatus, lang)},
      ),
      subtitle: translate(lang, 'products.modal.decisionSubtitle'),
      language: lang,
      maxWidth: 480,
      builder: (_) => _DecisionDialogBody(
        language: lang,
        onConfirm: (justification) {
          ref
              .read(vyronStateProvider.notifier)
              .changeProductStatus(product.id, nextStatus, justification);
        },
      ),
    );
  }
}

class _DecisionDialogBody extends StatefulWidget {
  const _DecisionDialogBody({
    required this.language,
    required this.onConfirm,
  });

  final UiLanguage language;
  final ValueChanged<String> onConfirm;

  @override
  State<_DecisionDialogBody> createState() => _DecisionDialogBodyState();
}

class _DecisionDialogBodyState extends State<_DecisionDialogBody> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = translate(
          widget.language,
          'products.modal.justificationError',
        ),
      );
      return;
    }
    widget.onConfirm(text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    String t(String key) => translate(lang, key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('product-decision-justification'),
          controller: _ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t('products.modal.justificationLabel'),
            hintText: t('products.modal.justificationPlaceholder'),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('common.cancel')),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              key: const Key('product-decision-confirm'),
              onPressed: _submit,
              child: Text(t('products.modal.confirmDecision')),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreateProductDialogBody extends StatefulWidget {
  const _CreateProductDialogBody({
    required this.language,
    required this.brands,
    required this.onCreate,
  });

  final UiLanguage language;
  final List<Brand> brands;
  final Product Function(ProductCreateInput input) onCreate;

  @override
  State<_CreateProductDialogBody> createState() =>
      _CreateProductDialogBodyState();
}

class _CreateProductDialogBodyState extends State<_CreateProductDialogBody> {
  final _nameCtrl = TextEditingController();
  late String _brandId;
  final _categoryCtrl = TextEditingController();
  final _platformCtrl = TextEditingController(text: 'Amazon BR');
  RemunerationModel _model = RemunerationModel.revShare;
  final _priceCtrl = TextEditingController(text: '450');
  CurrencyCode _currency = CurrencyCode.brl;
  final _commCtrl = TextEditingController(text: '8');
  final _epcCtrl = TextEditingController();
  final _cookieCtrl = TextEditingController();
  bool _isTest = false;
  bool _hasNameError = false;

  @override
  void initState() {
    super.initState();
    _brandId = widget.brands.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _platformCtrl.dispose();
    _priceCtrl.dispose();
    _commCtrl.dispose();
    _epcCtrl.dispose();
    _cookieCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _hasNameError = true);
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final comm = double.tryParse(_commCtrl.text.trim().replaceAll(',', '.'));
    final epcText = _epcCtrl.text.trim();
    final epc =
        epcText.isEmpty ? null : double.tryParse(epcText.replaceAll(',', '.'));
    final cookieText = _cookieCtrl.text.trim();
    final cookie = cookieText.isEmpty ? null : int.tryParse(cookieText);

    final created = widget.onCreate(
      ProductCreateInput(
        brandId: _brandId,
        name: name,
        category: _categoryCtrl.text.trim().isEmpty
            ? translate(widget.language, 'products.modal.categoryPlaceholder')
            : _categoryCtrl.text.trim(),
        platform: _platformCtrl.text.trim().isEmpty
            ? 'Amazon BR'
            : _platformCtrl.text.trim(),
        remunerationModel: _model,
        price: price,
        currency: _currency,
        commissionRatePct: comm,
        cpaValue: _model == RemunerationModel.cpa ? price : null,
        epcValue: epc,
        cookieWindowDays: cookie,
        demandTrendPct: 12.0,
        competitionLevel: CompetitionLevel.media,
        status: ProductStatus.candidate,
        isTest: _isTest,
      ),
    );
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    String t(String key) => translate(lang, key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('create-product-name'),
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: t('products.modal.nameReq'),
            hintText: t('products.modal.namePlaceholder'),
            errorText: _hasNameError ? t('products.modal.nameReq') : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: VyronDropdownField<String>(
                labelText: t('products.modal.mainBrand'),
                value: _brandId,
                items: [
                  for (final b in widget.brands)
                    DropdownMenuItem(value: b.id, child: Text(b.name)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _brandId = v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  labelText: t('products.modal.category'),
                  hintText: t('products.modal.categoryPlaceholder'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _platformCtrl,
                decoration: InputDecoration(
                  labelText: t('products.modal.platform'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: VyronDropdownField<RemunerationModel>(
                labelText: t('products.modal.remunerationModel'),
                value: _model,
                items: [
                  for (final m in RemunerationModel.values)
                    DropdownMenuItem(
                      value: m,
                      child: Text(labelProductModel(m, lang)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _model = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t('products.modal.price')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VyronDropdownField<CurrencyCode>(
                labelText: t('products.modal.currency'),
                value: _currency,
                items: const [
                  DropdownMenuItem(
                    value: CurrencyCode.brl,
                    child: Text('BRL'),
                  ),
                  DropdownMenuItem(
                    value: CurrencyCode.usd,
                    child: Text('USD'),
                  ),
                  DropdownMenuItem(
                    value: CurrencyCode.eur,
                    child: Text('EUR'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _currency = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _commCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: t('products.modal.commPct')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('create-product-epc'),
                controller: _epcCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t('products.modal.epcLabel'),
                  hintText: t('products.modal.epcPlaceholder'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('create-product-cookie'),
                controller: _cookieCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t('products.modal.cookieLabel'),
                  hintText: t('products.modal.epcPlaceholder'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _isTest,
          onChanged: (v) => setState(() => _isTest = v ?? false),
          title: Text(
            t('products.modal.isTestCheckbox'),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('common.cancel')),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              key: const Key('create-product-submit'),
              onPressed: _submit,
              child: Text(t('products.modal.saveBtn')),
            ),
          ],
        ),
      ],
    );
  }
}
