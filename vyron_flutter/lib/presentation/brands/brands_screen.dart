import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/routing/vyron_router.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key, this.brandId});

  final String? brandId;

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  String _statusFilter = 'all';
  bool _compareMode = false;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final effectiveBrandId = widget.brandId ?? appState.selectedBrandId;

    if (effectiveBrandId != null && effectiveBrandId.isNotEmpty) {
      return _BrandDetailView(brandId: effectiveBrandId);
    }

    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final currency = domain.settings.baseCurrency;
    final palette = context.vyronColors;
    final excludeTestData = appState.excludeTestData;
    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    final localizedBrands = domain.brands
        .map((b) => localizeBrand(b, lang))
        .toList();

    final rollups = computeBrandRollups(
      localizedBrands,
      domain.channels,
      domain.products,
      domain.contents,
      domain.financeEntries,
      currency,
      excludeTest: excludeTestData,
    );

    final visibleRollups = rollups.where((r) {
      if (_statusFilter == 'all') return true;
      return r.brand.status.wire == _statusFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: t('brands.title'),
          subtitle: t('brands.subtitle'),
          actions: [
            OutlinedButton.icon(
              key: const Key('brands-compare-toggle'),
              onPressed: () => setState(() => _compareMode = !_compareMode),
              icon: const Icon(Icons.compare_arrows_rounded, size: 16),
              label: Text(
                _compareMode
                    ? t('brands.compareHide')
                    : t('brands.compareShow'),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('brands-new-btn'),
              onPressed: () => _openCreateBrandModal(context, lang),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t('brands.newBrand')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Semantics(
          label: t('brands.filterAria'),
          child: VyronSegmentedControl<String>(
            options: [
              VyronSegmentOption(
                value: 'all',
                label: t('brands.filter.all', {
                  'count': '${domain.brands.length}',
                }),
              ),
              VyronSegmentOption(
                value: BrandStatus.active.wire,
                label: t('brands.filter.active'),
              ),
              VyronSegmentOption(
                value: BrandStatus.paused.wire,
                label: t('brands.filter.paused'),
              ),
              VyronSegmentOption(
                value: BrandStatus.archived.wire,
                label: t('brands.filter.archived'),
              ),
            ],
            value: _statusFilter,
            onChanged: (val) => setState(() => _statusFilter = val),
          ),
        ),
        const SizedBox(height: 16),

        if (_compareMode && visibleRollups.isNotEmpty) ...[
          VyronSurfacePanel(
            key: const Key('brands-compare-panel'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VyronSectionTitle(title: t('brands.compareTitle')),
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
                          DataColumn(label: Text(t('brands.col.brand'))),
                          DataColumn(label: Text(t('brands.col.marketTz'))),
                          DataColumn(label: Text(t('brands.col.stage'))),
                          DataColumn(
                            numeric: true,
                            label: Text(t('brands.col.approvedProd')),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(t('brands.col.views30d')),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(t('brands.col.confirmedComm')),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(t('brands.col.receivedCash')),
                          ),
                        ],
                        rows: [
                          for (final r in visibleRollups)
                            DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: parseVyronHexColor(
                                            r.brand.accentColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        r.brand.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${labelComplianceMarket(r.brand.market, lang)} · ${r.brand.timezone}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    labelValidationStage(
                                      r.brand.validationStage,
                                      lang,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${r.approvedProductsCount}',
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatCompactNumberForLang(
                                      r.totalViews30d,
                                      lang,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatCurrencyForLang(
                                      r.confirmedCommercial,
                                      currency,
                                      lang,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatCurrencyForLang(
                                      r.receivedCash,
                                      currency,
                                      lang,
                                    ),
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      color: palette.textMuted,
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

        if (visibleRollups.isEmpty)
          VyronEmptyState(
            title: t('brands.emptyTitle'),
            description: t('brands.emptyDesc'),
            actionLabel: t('brands.newBrand'),
            onAction: () => _openCreateBrandModal(context, lang),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 840 ? 2 : 1;
              final cardW = (w - (cols - 1) * 14) / cols;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final r in visibleRollups)
                    SizedBox(
                      width: cardW,
                      child: _BrandPortfolioCard(
                        rollup: r,
                        currency: currency,
                        language: lang,
                        onOpenDetails: () => navigateToVyronModule(
                          ref,
                          NavModule.brands,
                          brandId: r.brand.id,
                          setBrandId: true,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _openCreateBrandModal(
    BuildContext context,
    UiLanguage lang,
  ) async {
    final created = await showVyronModalDialog<Brand>(
      context: context,
      title: translate(lang, 'brands.modal.createTitle'),
      subtitle: translate(lang, 'brands.modal.createSubtitle'),
      language: lang,
      maxWidth: 560,
      builder: (dialogContext) => _CreateBrandDialogBody(
        language: lang,
        onCreate: (input) =>
            ref.read(vyronStateProvider.notifier).createBrand(input),
      ),
    );
    if (created != null && mounted) {
      navigateToVyronModule(
        ref,
        NavModule.brands,
        brandId: created.id,
        setBrandId: true,
      );
    }
  }
}

class _BrandPortfolioCard extends StatelessWidget {
  const _BrandPortfolioCard({
    required this.rollup,
    required this.currency,
    required this.language,
    required this.onOpenDetails,
  });

  final BrandRollup rollup;
  final CurrencyCode currency;
  final UiLanguage language;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final brand = rollup.brand;
    final palette = context.vyronColors;
    final accent = parseVyronHexColor(brand.accentColor);
    String t(String key, [Map<String, String>? params]) =>
        translate(language, key, params);

    return VyronSurfacePanel(
      padding: VyronPanelPadding.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            brand.niche,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    VyronStatusLabel(
                      status: labelBrandStatus(brand.status, language),
                      statusKey: brand.status.wire,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${labelComplianceMarket(brand.market, language)} · ${brand.timezone} · ${brand.publishWindow}',
                  style: TextStyle(
                    fontFamily: VyronTypography.mono,
                    fontSize: 11,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  brand.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _CardStatCell(
                        label: t('brands.card.confirmed'),
                        value: formatCurrencyForLang(
                          rollup.confirmedCommercial,
                          currency,
                          language,
                        ),
                      ),
                      _CardStatCell(
                        label: t('brands.card.validation'),
                        value: labelValidationStage(
                          brand.validationStage,
                          language,
                        ),
                      ),
                      _CardStatCell(
                        label: t('brands.card.views'),
                        value: formatCompactNumberForLang(
                          rollup.totalViews30d,
                          language,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VyronToneBadge(
                      label: t('brands.card.pillars', {
                        'count': '${brand.pillars.length}',
                      }),
                      tone: VyronMetricTone.neutral,
                    ),
                    OutlinedButton.icon(
                      key: Key('brand-open-${brand.id}'),
                      onPressed: onOpenDetails,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                      label: Text(t('brands.card.openDetails')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStatCell extends StatelessWidget {
  const _CardStatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: palette.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: VyronTypography.mono,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BrandDetailView extends ConsumerWidget {
  const _BrandDetailView({required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final currency = domain.settings.baseCurrency;
    final palette = context.vyronColors;
    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    Brand? rawBrand;
    for (final b in domain.brands) {
      if (b.id == brandId) {
        rawBrand = b;
        break;
      }
    }

    if (rawBrand == null) {
      return VyronEmptyState(
        title: t('brands.detail.notFoundTitle'),
        description: t('brands.detail.notFoundDesc'),
        actionLabel: t('brands.detail.backToList'),
        onAction: () => navigateToVyronModule(
          ref,
          NavModule.brands,
          brandId: null,
          setBrandId: true,
        ),
      );
    }

    final brand = localizeBrand(rawBrand, lang);
    final brandChannels = domain.channels
        .where((c) => c.brandId == brand.id)
        .toList();
    final brandProducts = domain.products
        .where(
          (p) =>
              (!appState.excludeTestData || !p.isTest) &&
              (p.brandId == brand.id || p.linkedBrandIds.contains(brand.id)),
        )
        .map((p) => localizeProduct(p, lang))
        .toList();
    final brandContents = domain.contents
        .where((c) => c.brandId == brand.id)
        .toList();
    final brandActivities = domain.activities
        .where((a) => a.brandId == brand.id)
        .take(6)
        .map((a) => localizeActivity(a, lang))
        .toList();

    final fin = calculateFinanceSummary(
      domain.financeEntries,
      currency,
      brandId: brand.id,
      excludeTest: appState.excludeTestData,
    );
    final totalViews30d = brandChannels.fold<int>(
      0,
      (acc, c) => acc + c.views30d,
    );
    final publishedCount = brandContents
        .where((c) => c.status == ContentStatus.published)
        .length;

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
              key: const Key('brand-detail-back'),
              onPressed: () => navigateToVyronModule(
                ref,
                NavModule.brands,
                brandId: null,
                setBrandId: true,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: Text(t('brands.detail.backToList')),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('brand-detail-edit-btn'),
                  onPressed: () => _openEditBrandModal(
                    context,
                    lang,
                    brand,
                    (patch) => notifier.updateBrand(brand.id, patch),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(t('brands.detail.editBtn')),
                ),
                if (brand.status != BrandStatus.archived)
                  OutlinedButton(
                    key: const Key('brand-detail-archive-btn'),
                    onPressed: () => notifier.changeBrandStatus(
                      brand.id,
                      BrandStatus.archived,
                      t('brands.detail.archiveReason'),
                    ),
                    child: Text(t('brands.detail.archiveBtn')),
                  )
                else
                  ElevatedButton(
                    key: const Key('brand-detail-reactivate-btn'),
                    onPressed: () => notifier.changeBrandStatus(
                      brand.id,
                      BrandStatus.active,
                      t('brands.detail.reactivateReason'),
                    ),
                    child: Text(t('brands.detail.reactivateBtn')),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        VyronPageHeader(
          title: brand.name,
          subtitle: t('brands.detail.subtitle', {
            'niche': brand.niche,
            'market': labelComplianceMarket(brand.market, lang),
            'lang': brand.language,
            'tz': brand.timezone,
            'archetype': labelBrandArchetype(brand.archetype, lang),
          }),
          actions: [
            VyronStatusLabel(
              status: labelBrandStatus(brand.status, lang),
              statusKey: brand.status.wire,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // KPI Row
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1040 ? 4 : (w >= 560 ? 2 : 1);
            final tileW = (w - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('brands.detail.kpi.confirmed'),
                    value: formatCurrencyForLang(
                      fin.confirmedCommercialResult,
                      currency,
                      lang,
                    ),
                    helper: t('brands.detail.kpi.receivedHelper', {
                      'amount': formatCurrencyForLang(
                        fin.receivedCashIn,
                        currency,
                        lang,
                      ),
                    }),
                    tone: VyronMetricTone.cobalt,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('brands.detail.kpi.pending'),
                    value: formatCurrencyForLang(
                      fin.pendingCommissions,
                      currency,
                      lang,
                    ),
                    helper: t('brands.detail.kpi.pendingHelper'),
                    tone: VyronMetricTone.amber,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('brands.detail.kpi.reach'),
                    value: formatCompactNumberForLang(totalViews30d, lang),
                    helper: t('brands.detail.kpi.channelsHelper', {
                      'count': '${brandChannels.length}',
                    }),
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: VyronMetricBlock(
                    label: t('brands.detail.kpi.stage'),
                    value: labelValidationStage(brand.validationStage, lang),
                    helper: t('brands.detail.kpi.stageHelper', {
                      'products': '${brandProducts.length}',
                      'published': '$publishedCount',
                      'total': '${brandContents.length}',
                    }),
                    tone: VyronMetricTone.emerald,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Identity & Pillars
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(
                title: t('brands.detail.identityTitle'),
                subtitle: brand.tagline,
              ),
              const SizedBox(height: 12),
              Text(
                brand.description,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: palette.textMuted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _IdentityMetaField(
                    label: t('brands.detail.tzWindow'),
                    value: '${brand.timezone} · ${brand.publishWindow}',
                    monospace: true,
                  ),
                  _IdentityMetaField(
                    label: t('brands.detail.archetype'),
                    value: labelBrandArchetype(brand.archetype, lang),
                  ),
                  _IdentityMetaField(
                    label: t('brands.detail.typography'),
                    value: brand.typographyNote,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('brands.detail.palette'),
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ColorSwatchChip(hex: brand.accentColor),
                          const SizedBox(width: 8),
                          _ColorSwatchChip(hex: brand.secondaryColor),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                t('brands.detail.pillarsTitle', {
                  'count': '${brand.pillars.length}',
                }),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pillar in brand.pillars)
                    VyronToneBadge(label: pillar, tone: VyronMetricTone.cobalt),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Channels & Products Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final channelsPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('brands.detail.channelsTitle', {
                      'count': '${brandChannels.length}',
                    }),
                    trailing: TextButton(
                      onPressed: () =>
                          navigateToVyronModule(ref, NavModule.channels),
                      child: Text(t('brands.detail.manageChannels')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final ch in brandChannels)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.panelBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ch.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${ch.platform.wire} · ${ch.handle}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${formatCompactNumberForLang(ch.followers, lang)} seg.',
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              VyronStatusLabel(
                                status: labelChannelIntegrationStatus(
                                  ch.integrationStatus,
                                  lang,
                                ),
                                statusKey: ch.integrationStatus.wire,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

            final productsPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('brands.detail.productsTitle', {
                      'count': '${brandProducts.length}',
                    }),
                    subtitle: t('brands.detail.sharedCatalogNote'),
                    trailing: TextButton(
                      onPressed: () =>
                          navigateToVyronModule(ref, NavModule.products),
                      child: Text(t('brands.detail.openCatalog')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final prod in brandProducts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => navigateToVyronModule(
                          ref,
                          NavModule.products,
                          productId: prod.id,
                          setProductId: true,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: palette.panelBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${prod.platform} · ${prod.currency.wire}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              VyronStatusLabel(
                                status: labelProductStatus(prod.status, lang),
                                statusKey: prod.status.wire,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: channelsPanel),
                  const SizedBox(width: 14),
                  Expanded(child: productsPanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                channelsPanel,
                const SizedBox(height: 14),
                productsPanel,
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Linked Contents & Brand Activity
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(
                title: t('brands.detail.contentsTitle', {
                  'count': '${brandContents.length}',
                }),
              ),
              const SizedBox(height: 10),
              for (final item in brandContents)
                Builder(
                  builder: (context) {
                    final loc = localizeContentDisplay(item, lang);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => navigateToVyronModule(
                          ref,
                          NavModule.content,
                          contentId: item.id,
                          setContentId: true,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: palette.panelBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${labelContentFormat(item.format, lang)} · ${formatDateForLang(item.scheduledDate, lang)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              VyronStatusLabel(
                                status: labelContentStatus(item.status, lang),
                                statusKey: item.status.wire,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(title: t('brands.detail.historyTitle')),
              const SizedBox(height: 10),
              if (brandActivities.isEmpty)
                Text(
                  t('brands.detail.historyEmpty'),
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                )
              else
                for (final act in brandActivities)
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
                                act.action,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              formatDateTimeForLang(act.timestamp, lang),
                              style: TextStyle(
                                fontFamily: VyronTypography.mono,
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          act.detail,
                          style: TextStyle(
                            fontSize: 11.5,
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

  Future<void> _openEditBrandModal(
    BuildContext context,
    UiLanguage lang,
    Brand brand,
    ValueChanged<BrandUpdatePatch> onSave,
  ) async {
    await showVyronModalDialog<void>(
      context: context,
      title: translate(lang, 'brands.modal.editTitle'),
      language: lang,
      maxWidth: 560,
      builder: (_) =>
          _EditBrandDialogBody(language: lang, brand: brand, onSave: onSave),
    );
  }
}

class _IdentityMetaField extends StatelessWidget {
  const _IdentityMetaField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: palette.textMuted)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: monospace ? VyronTypography.mono : VyronTypography.sans,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ColorSwatchChip extends StatelessWidget {
  const _ColorSwatchChip({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: parseVyronHexColor(hex),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            hex,
            style: const TextStyle(
              fontFamily: VyronTypography.mono,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateBrandDialogBody extends StatefulWidget {
  const _CreateBrandDialogBody({
    required this.language,
    required this.onCreate,
  });

  final UiLanguage language;
  final Brand Function(BrandCreateInput input) onCreate;

  @override
  State<_CreateBrandDialogBody> createState() => _CreateBrandDialogBodyState();
}

class _CreateBrandDialogBodyState extends State<_CreateBrandDialogBody> {
  final _nameCtrl = TextEditingController();
  final _nicheCtrl = TextEditingController();
  final _marketCtrl = TextEditingController(text: 'Brasil');
  final _languageCtrl = TextEditingController(text: 'PT-BR');
  final _accentCtrl = TextEditingController(text: '#315FEA');
  late final TextEditingController _pillarsCtrl;
  final _descCtrl = TextEditingController();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pillarsCtrl = TextEditingController(
      text: translate(widget.language, 'brands.modal.defaultPillars'),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicheCtrl.dispose();
    _marketCtrl.dispose();
    _languageCtrl.dispose();
    _accentCtrl.dispose();
    _pillarsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final niche = _nicheCtrl.text.trim();
    if (name.isEmpty || niche.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final pillars = _pillarsCtrl.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final created = widget.onCreate(
      BrandCreateInput(
        name: name,
        slug: slug.isEmpty ? 'brand' : slug,
        niche: niche,
        segment: niche,
        market: _marketCtrl.text.trim().isEmpty
            ? 'Brasil'
            : _marketCtrl.text.trim(),
        language: _languageCtrl.text.trim().isEmpty
            ? 'PT-BR'
            : _languageCtrl.text.trim(),
        status: BrandStatus.active,
        accentColor: _accentCtrl.text.trim().isEmpty
            ? '#315FEA'
            : _accentCtrl.text.trim(),
        secondaryColor: '#292E36',
        typographyNote: 'Plus Jakarta Sans + DM Sans',
        tagline: niche,
        description: _descCtrl.text.trim().isEmpty
            ? niche
            : _descCtrl.text.trim(),
        pillars: pillars.isEmpty ? null : pillars,
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
          key: const Key('create-brand-name'),
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: t('brands.modal.nameReq'),
            hintText: t('brands.modal.namePlaceholder'),
            errorText: _hasError && _nameCtrl.text.trim().isEmpty
                ? t('brands.modal.nameReq')
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('create-brand-niche'),
          controller: _nicheCtrl,
          decoration: InputDecoration(
            labelText: t('brands.modal.nicheReq'),
            hintText: t('brands.modal.nichePlaceholder'),
            errorText: _hasError && _nicheCtrl.text.trim().isEmpty
                ? t('brands.modal.nicheReq')
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _marketCtrl,
                decoration: InputDecoration(
                  labelText: t('brands.modal.market'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _languageCtrl,
                decoration: InputDecoration(
                  labelText: t('brands.modal.language'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accentCtrl,
          decoration: InputDecoration(labelText: t('brands.modal.accentColor')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pillarsCtrl,
          decoration: InputDecoration(
            labelText: t('brands.modal.pillarsLabel'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t('brands.modal.descLabel'),
            hintText: t('brands.modal.descPlaceholder'),
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
              key: const Key('create-brand-submit'),
              onPressed: _submit,
              child: Text(t('brands.modal.createBtn')),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditBrandDialogBody extends StatefulWidget {
  const _EditBrandDialogBody({
    required this.language,
    required this.brand,
    required this.onSave,
  });

  final UiLanguage language;
  final Brand brand;
  final ValueChanged<BrandUpdatePatch> onSave;

  @override
  State<_EditBrandDialogBody> createState() => _EditBrandDialogBodyState();
}

class _EditBrandDialogBodyState extends State<_EditBrandDialogBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _tzCtrl;
  late final TextEditingController _windowCtrl;
  late final TextEditingController _marketCtrl;
  late final TextEditingController _accentCtrl;
  late final TextEditingController _descCtrl;
  late ValidationStage _stage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.brand.name);
    _tzCtrl = TextEditingController(text: widget.brand.timezone);
    _windowCtrl = TextEditingController(text: widget.brand.publishWindow);
    _marketCtrl = TextEditingController(text: widget.brand.market);
    _accentCtrl = TextEditingController(text: widget.brand.accentColor);
    _descCtrl = TextEditingController(text: widget.brand.description);
    _stage = widget.brand.validationStage;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tzCtrl.dispose();
    _windowCtrl.dispose();
    _marketCtrl.dispose();
    _accentCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(
      BrandUpdatePatch(
        name: _nameCtrl.text.trim().isEmpty
            ? widget.brand.name
            : _nameCtrl.text.trim(),
        timezone: _tzCtrl.text.trim().isEmpty
            ? widget.brand.timezone
            : _tzCtrl.text.trim(),
        publishWindow: _windowCtrl.text.trim().isEmpty
            ? widget.brand.publishWindow
            : _windowCtrl.text.trim(),
        market: _marketCtrl.text.trim().isEmpty
            ? widget.brand.market
            : _marketCtrl.text.trim(),
        accentColor: _accentCtrl.text.trim().isEmpty
            ? widget.brand.accentColor
            : _accentCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? widget.brand.description
            : _descCtrl.text.trim(),
        validationStage: _stage,
      ),
    );
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
          key: const Key('edit-brand-name'),
          controller: _nameCtrl,
          decoration: InputDecoration(labelText: t('brands.modal.name')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tzCtrl,
                decoration: InputDecoration(labelText: t('brands.modal.tz')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _windowCtrl,
                decoration: InputDecoration(
                  labelText: t('brands.modal.window'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        VyronDropdownField<ValidationStage>(
          labelText: t('brands.modal.stage'),
          value: _stage,
          items: [
            for (final s in ValidationStage.values)
              DropdownMenuItem<ValidationStage>(
                value: s,
                child: Text(labelValidationStage(s, lang)),
              ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _stage = val);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _marketCtrl,
                decoration: InputDecoration(
                  labelText: t('brands.modal.market'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _accentCtrl,
                decoration: InputDecoration(
                  labelText: t('brands.modal.primaryColor'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: InputDecoration(labelText: t('brands.modal.descLabel')),
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
              key: const Key('edit-brand-submit'),
              onPressed: _save,
              child: Text(t('common.saveChanges')),
            ),
          ],
        ),
      ],
    );
  }
}
