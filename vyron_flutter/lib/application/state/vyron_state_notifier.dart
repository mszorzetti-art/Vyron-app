import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/vyron_crypto.dart';
import '../../data/seed_data.dart';
import '../../data/storage/atomic_state_storage.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';

enum ContentSubView { studio, calendar }

@immutable
class VyronAppState {
  const VyronAppState({
    required this.domain,
    this.isHydrated = false,
    this.activeModule = NavModule.overview,
    this.selectedBrandId,
    this.selectedProductId,
    this.selectedContentId,
    this.selectedAutomationId,
    this.contentSubView = ContentSubView.studio,
    this.globalBrandFilter = 'all',
    this.globalPeriodFilter = PeriodFilter.d30,
    this.excludeTestData = true,
  });

  final VyronState domain;
  final bool isHydrated;
  final NavModule activeModule;
  final String? selectedBrandId;
  final String? selectedProductId;
  final String? selectedContentId;
  final String? selectedAutomationId;
  final ContentSubView contentSubView;
  final String globalBrandFilter;
  final PeriodFilter globalPeriodFilter;
  final bool excludeTestData;

  VyronAppState copyWith({
    VyronState? domain,
    bool? isHydrated,
    NavModule? activeModule,
    String? selectedBrandId,
    bool clearSelectedBrandId = false,
    String? selectedProductId,
    bool clearSelectedProductId = false,
    String? selectedContentId,
    bool clearSelectedContentId = false,
    String? selectedAutomationId,
    bool clearSelectedAutomationId = false,
    ContentSubView? contentSubView,
    String? globalBrandFilter,
    PeriodFilter? globalPeriodFilter,
    bool? excludeTestData,
  }) {
    return VyronAppState(
      domain: domain ?? this.domain,
      isHydrated: isHydrated ?? this.isHydrated,
      activeModule: activeModule ?? this.activeModule,
      selectedBrandId: clearSelectedBrandId
          ? null
          : (selectedBrandId ?? this.selectedBrandId),
      selectedProductId: clearSelectedProductId
          ? null
          : (selectedProductId ?? this.selectedProductId),
      selectedContentId: clearSelectedContentId
          ? null
          : (selectedContentId ?? this.selectedContentId),
      selectedAutomationId: clearSelectedAutomationId
          ? null
          : (selectedAutomationId ?? this.selectedAutomationId),
      contentSubView: contentSubView ?? this.contentSubView,
      globalBrandFilter: globalBrandFilter ?? this.globalBrandFilter,
      globalPeriodFilter: globalPeriodFilter ?? this.globalPeriodFilter,
      excludeTestData: excludeTestData ?? this.excludeTestData,
    );
  }
}

@immutable
class BrandCreateInput {
  const BrandCreateInput({
    required this.name,
    required this.slug,
    required this.niche,
    required this.segment,
    required this.market,
    required this.language,
    required this.status,
    required this.accentColor,
    required this.secondaryColor,
    required this.typographyNote,
    required this.tagline,
    required this.description,
    this.timezone,
    this.publishWindow,
    this.archetype,
    this.validationStage,
    this.pillars,
  });

  final String name;
  final String slug;
  final String niche;
  final String segment;
  final String market;
  final String language;
  final BrandStatus status;
  final String accentColor;
  final String secondaryColor;
  final String typographyNote;
  final String tagline;
  final String description;
  final String? timezone;
  final String? publishWindow;
  final BrandArchetype? archetype;
  final ValidationStage? validationStage;
  final List<String>? pillars;
}

@immutable
class BrandUpdatePatch {
  const BrandUpdatePatch({
    this.name,
    this.slug,
    this.niche,
    this.segment,
    this.market,
    this.language,
    this.timezone,
    this.publishWindow,
    this.archetype,
    this.validationStage,
    this.pillars,
    this.status,
    this.accentColor,
    this.secondaryColor,
    this.typographyNote,
    this.tagline,
    this.description,
  });

  final String? name;
  final String? slug;
  final String? niche;
  final String? segment;
  final String? market;
  final String? language;
  final String? timezone;
  final String? publishWindow;
  final BrandArchetype? archetype;
  final ValidationStage? validationStage;
  final List<String>? pillars;
  final BrandStatus? status;
  final String? accentColor;
  final String? secondaryColor;
  final String? typographyNote;
  final String? tagline;
  final String? description;
}

@immutable
class ProductCreateInput {
  const ProductCreateInput({
    required this.brandId,
    required this.name,
    required this.category,
    required this.platform,
    required this.remunerationModel,
    required this.price,
    required this.currency,
    required this.commissionRatePct,
    required this.cpaValue,
    required this.epcValue,
    required this.cookieWindowDays,
    this.opportunityScore,
    required this.demandTrendPct,
    required this.competitionLevel,
    required this.status,
    this.externalId,
    this.linkedBrandIds,
    this.isTest,
    this.dataConfidence,
    this.qualityGrade,
    this.complianceState,
    this.complianceMarket,
  });

  final String brandId;
  final String name;
  final String category;
  final String platform;
  final RemunerationModel remunerationModel;
  final double? price;
  final CurrencyCode currency;
  final double? commissionRatePct;
  final double? cpaValue;
  final double? epcValue;
  final int? cookieWindowDays;
  final int? opportunityScore;
  final double? demandTrendPct;
  final CompetitionLevel competitionLevel;
  final ProductStatus status;
  final String? externalId;
  final List<String>? linkedBrandIds;
  final bool? isTest;
  final DataConfidence? dataConfidence;
  final ProductQualityGrade? qualityGrade;
  final ComplianceState? complianceState;
  final String? complianceMarket;
}

@immutable
class ProductGovernancePatch {
  const ProductGovernancePatch({
    this.qualityGrade,
    this.clearQualityGrade = false,
    this.complianceState,
    this.linkedBrandIds,
  });

  final ProductQualityGrade? qualityGrade;
  final bool clearQualityGrade;
  final ComplianceState? complianceState;
  final List<String>? linkedBrandIds;
}

@immutable
class ContentCreateInput {
  const ContentCreateInput({
    required this.brandId,
    required this.channelId,
    this.productId,
    required this.title,
    this.description,
    required this.format,
    this.category,
    this.visibility,
    this.analysisMethod,
    this.sensitiveTopic,
    this.unclassifiedRiskFlag,
    required this.status,
    required this.scheduledDate,
    this.publishedAt,
    required this.brief,
    required this.angleIdea,
    required this.script,
    this.affiliateLinkUrl,
    this.verifiedDestinationUrl,
    this.linkVerifiedAt,
    this.commercialConditionsVerifiedAt,
    this.offerEndsAt,
    this.affiliateDisclosure,
    this.aiDisclosureRequired,
    this.aiDisclosureText,
    this.relevanceTestPassed,
    this.editorialChecklistPassed,
    this.humanHoursLogged,
    this.dossier,
    required this.references,
    this.metrics,
  });

  final String brandId;
  final String channelId;
  final String? productId;
  final String title;
  final String? description;
  final ContentFormat format;
  final ContentCategory? category;
  final ContentVisibility? visibility;
  final AnalysisMethod? analysisMethod;
  final SensitiveTopic? sensitiveTopic;
  final bool? unclassifiedRiskFlag;
  final ContentStatus status;
  final String scheduledDate;
  final String? publishedAt;
  final String brief;
  final String angleIdea;
  final String script;
  final String? affiliateLinkUrl;
  final String? verifiedDestinationUrl;
  final String? linkVerifiedAt;
  final String? commercialConditionsVerifiedAt;
  final String? offerEndsAt;
  final String? affiliateDisclosure;
  final bool? aiDisclosureRequired;
  final String? aiDisclosureText;
  final bool? relevanceTestPassed;
  final bool? editorialChecklistPassed;
  final double? humanHoursLogged;
  final List<DossierSource>? dossier;
  final List<String> references;
  final ContentMetrics? metrics;
}

@immutable
class ContentUpdatePatch {
  const ContentUpdatePatch({
    this.brandId,
    this.channelId,
    this.productId,
    this.clearProductId = false,
    this.title,
    this.description,
    this.format,
    this.category,
    this.visibility,
    this.analysisMethod,
    this.sensitiveTopic,
    this.unclassifiedRiskFlag,
    this.status,
    this.scheduledDate,
    this.publishedAt,
    this.brief,
    this.angleIdea,
    this.script,
    this.affiliateLinkUrl,
    this.verifiedDestinationUrl,
    this.linkVerifiedAt,
    this.commercialConditionsVerifiedAt,
    this.offerEndsAt,
    this.affiliateDisclosure,
    this.aiDisclosureRequired,
    this.aiDisclosureText,
    this.relevanceTestPassed,
    this.editorialChecklistPassed,
    this.humanHoursLogged,
    this.dossier,
    this.references,
    this.metrics,
  });

  final String? brandId;
  final String? channelId;
  final String? productId;
  final bool clearProductId;
  final String? title;
  final String? description;
  final ContentFormat? format;
  final ContentCategory? category;
  final ContentVisibility? visibility;
  final AnalysisMethod? analysisMethod;
  final SensitiveTopic? sensitiveTopic;
  final bool? unclassifiedRiskFlag;
  final ContentStatus? status;
  final String? scheduledDate;
  final String? publishedAt;
  final String? brief;
  final String? angleIdea;
  final String? script;
  final String? affiliateLinkUrl;
  final String? verifiedDestinationUrl;
  final String? linkVerifiedAt;
  final String? commercialConditionsVerifiedAt;
  final String? offerEndsAt;
  final String? affiliateDisclosure;
  final bool? aiDisclosureRequired;
  final String? aiDisclosureText;
  final bool? relevanceTestPassed;
  final bool? editorialChecklistPassed;
  final double? humanHoursLogged;
  final List<DossierSource>? dossier;
  final List<String>? references;
  final ContentMetrics? metrics;
}

@immutable
class ChannelCreateInput {
  const ChannelCreateInput({
    required this.brandId,
    required this.name,
    required this.handle,
    required this.platform,
    required this.language,
    this.advancedFeaturesUnlocked,
    required this.integrationStatus,
    required this.followers,
    required this.growthPct30d,
    required this.views30d,
    required this.reach30d,
    required this.engagementRatePct,
    this.shortsToLongPct,
    required this.publications30d,
  });

  final String brandId;
  final String name;
  final String handle;
  final ChannelPlatform platform;
  final String language;
  final bool? advancedFeaturesUnlocked;
  final ChannelIntegrationStatus integrationStatus;
  final int followers;
  final double growthPct30d;
  final int views30d;
  final int reach30d;
  final double engagementRatePct;
  final double? shortsToLongPct;
  final int publications30d;
}

@immutable
class FinanceEntryCreateInput {
  const FinanceEntryCreateInput({
    required this.brandId,
    this.productId,
    required this.platform,
    required this.description,
    required this.type,
    required this.stage,
    required this.amount,
    required this.currency,
    this.fxRateToBRL,
    this.fxSource,
    required this.date,
    this.isTest = false,
    this.isProjection = false,
  });

  final String brandId;
  final String? productId;
  final String platform;
  final String description;
  final FinanceEntryType type;
  final CommissionStage stage;
  final double amount;
  final CurrencyCode currency;
  final double? fxRateToBRL;
  final String? fxSource;
  final String date;
  final bool isTest;
  final bool isProjection;
}

@immutable
class OwnerSettingsPatch {
  const OwnerSettingsPatch({
    this.ownerName,
    this.ownerEmail,
    this.roleLabel,
    this.theme,
    this.uiLanguage,
    this.baseCurrency,
    this.globalAutonomyEnabled,
    this.emergencyStopActive,
    this.maxGlobalDailySpendBRL,
    this.requireApprovalForPublish,
    this.requireApprovalForProductStatus,
    this.defaultAuthValidityHours,
    this.evidenceFreshnessMaxHours,
    this.notificationPrefs,
    this.integrations,
  });

  final String? ownerName;
  final String? ownerEmail;
  final String? roleLabel;
  final VyronThemeMode? theme;
  final UiLanguage? uiLanguage;
  final CurrencyCode? baseCurrency;
  final bool? globalAutonomyEnabled;
  final bool? emergencyStopActive;
  final double? maxGlobalDailySpendBRL;
  final bool? requireApprovalForPublish;
  final bool? requireApprovalForProductStatus;
  final int? defaultAuthValidityHours;
  final int? evidenceFreshnessMaxHours;
  final NotificationPrefs? notificationPrefs;
  final List<IntegrationConfig>? integrations;
}

@immutable
class PipelineRunResult {
  const PipelineRunResult({
    required this.ok,
    required this.message,
    this.job,
  });

  final bool ok;
  final String message;
  final JobRun? job;
}

@immutable
class ResumeControlResult {
  const ResumeControlResult({
    required this.ok,
    this.reason,
  });

  final bool ok;
  final String? reason;
}

final vyronStateStorageProvider = Provider<VyronStateStorage>(
  (ref) => AtomicFileVyronStateStorage(),
);

final vyronStateProvider =
    StateNotifierProvider<VyronStateNotifier, VyronAppState>(
  (ref) {
    final notifier = VyronStateNotifier(
      storage: ref.watch(vyronStateStorageProvider),
    );
    unawaited(notifier.hydrate());
    return notifier;
  },
);

class VyronStateNotifier extends StateNotifier<VyronAppState> {
  VyronStateNotifier({
    required VyronStateStorage storage,
    DateTime Function()? nowUtc,
  })  : _storage = storage,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        super(VyronAppState(domain: buildInitialVyronState()));

  final VyronStateStorage _storage;
  final DateTime Function() _nowUtc;
  int _idSeq = 0;

  String _nextSuffix() {
    _idSeq = (_idSeq + 1) % 10000;
    return _idSeq.toString().padLeft(4, '0');
  }

  UiLanguage get _langNow => state.domain.settings.uiLanguage;

  Future<void> hydrate() async {
    final loaded = await _storage.loadState();
    if (!mounted) return;
    state = state.copyWith(
      domain: loaded,
      isHydrated: true,
    );
  }

  void _commitDomain(VyronState nextDomain) {
    state = state.copyWith(domain: nextDomain);
    unawaited(_storage.saveState(nextDomain));
  }

  List<ActivityEvent> _appendActivity(
    VyronState prev, {
    String? brandId,
    required ActivityCategory category,
    required String action,
    required String detail,
    String? justification,
    String? actor,
    ActivitySeverity severity = ActivitySeverity.info,
  }) {
    final now = _nowUtc();
    final ev = ActivityEvent(
      id: 'act-${now.millisecondsSinceEpoch}-${_nextSuffix()}',
      timestamp: now.toIso8601String(),
      brandId: brandId,
      category: category,
      action: action,
      detail: detail,
      justification: justification,
      actor: actor ??
          (prev.settings.uiLanguage == UiLanguage.enUS
              ? 'Owner'
              : 'Proprietário'),
      severity: severity,
    );
    return [ev, ...prev.activities];
  }

  void navigate(
    NavModule module, {
    String? brandId,
    bool setBrandId = false,
    String? productId,
    bool setProductId = false,
    String? contentId,
    bool setContentId = false,
    String? automationId,
    bool setAutomationId = false,
    ContentSubView? contentSubView,
  }) {
    final hasAnyOption = setBrandId ||
        setProductId ||
        setContentId ||
        setAutomationId ||
        contentSubView != null;

    if (hasAnyOption) {
      state = state.copyWith(
        activeModule: module,
        selectedBrandId: setBrandId ? brandId : state.selectedBrandId,
        clearSelectedBrandId: setBrandId && brandId == null,
        selectedProductId: setProductId ? productId : state.selectedProductId,
        clearSelectedProductId: setProductId && productId == null,
        selectedContentId: setContentId ? contentId : state.selectedContentId,
        clearSelectedContentId: setContentId && contentId == null,
        selectedAutomationId:
            setAutomationId ? automationId : state.selectedAutomationId,
        clearSelectedAutomationId: setAutomationId && automationId == null,
        contentSubView: contentSubView ?? state.contentSubView,
      );
    } else {
      state = state.copyWith(
        activeModule: module,
        clearSelectedBrandId: module != NavModule.brands,
        clearSelectedProductId: module != NavModule.products,
        clearSelectedAutomationId: module != NavModule.automations,
      );
    }
  }

  void setGlobalBrandFilter(String brandId) {
    state = state.copyWith(globalBrandFilter: brandId);
  }

  void setGlobalPeriodFilter(PeriodFilter period) {
    state = state.copyWith(globalPeriodFilter: period);
  }

  void setContentSubView(ContentSubView sub) {
    state = state.copyWith(contentSubView: sub);
  }

  void setExcludeTestData(bool exclude) {
    state = state.copyWith(excludeTestData: exclude);
  }

  void toggleTheme() {
    final prev = state.domain;
    _commitDomain(
      prev.copyWith(
        settings: prev.settings.copyWith(
          theme: prev.settings.theme == VyronThemeMode.dark
              ? VyronThemeMode.light
              : VyronThemeMode.dark,
        ),
      ),
    );
  }

  void setTheme(VyronThemeMode theme) {
    final prev = state.domain;
    _commitDomain(
      prev.copyWith(
        settings: prev.settings.copyWith(theme: theme),
      ),
    );
  }

  void setBaseCurrency(CurrencyCode baseCurrency) {
    final prev = state.domain;
    _commitDomain(
      prev.copyWith(
        settings: prev.settings.copyWith(baseCurrency: baseCurrency),
      ),
    );
  }

  void updateSettings(OwnerSettingsPatch patch) {
    final prev = state.domain;
    final nextLang = patch.uiLanguage ?? prev.settings.uiLanguage;
    final en = nextLang == UiLanguage.enUS;
    final nextSettings = prev.settings.copyWith(
      ownerName: patch.ownerName,
      ownerEmail: patch.ownerEmail,
      roleLabel: patch.roleLabel,
      theme: patch.theme,
      uiLanguage: patch.uiLanguage,
      baseCurrency: patch.baseCurrency,
      globalAutonomyEnabled: patch.globalAutonomyEnabled,
      emergencyStopActive: patch.emergencyStopActive,
      maxGlobalDailySpendBRL: patch.maxGlobalDailySpendBRL,
      requireApprovalForPublish: patch.requireApprovalForPublish,
      requireApprovalForProductStatus: patch.requireApprovalForProductStatus,
      defaultAuthValidityHours: patch.defaultAuthValidityHours,
      evidenceFreshnessMaxHours: patch.evidenceFreshnessMaxHours,
      notificationPrefs: patch.notificationPrefs,
      integrations: patch.integrations,
    );

    _commitDomain(
      prev.copyWith(
        settings: nextSettings,
        activities: _appendActivity(
          prev,
          category: ActivityCategory.sistema,
          action: en ? 'Preferences updated' : 'Preferências atualizadas',
          detail: en
              ? 'Operational settings or autonomy policies updated by owner.'
              : 'Configurações operacionais ou políticas de autonomia alteradas pelo proprietário.',
          actor: en ? 'Owner' : 'Proprietário',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  void toggleSystemFlags({
    bool? publishingEnabled,
    bool? phaseBPublicAllowed,
  }) {
    final prev = state.domain;
    final en = prev.settings.uiLanguage == UiLanguage.enUS;
    final nextControl = prev.systemControl.copyWith(
      publishingEnabled: publishingEnabled,
      phaseBPublicAllowed: phaseBPublicAllowed,
      updatedAt: _nowUtc().toIso8601String(),
    );

    _commitDomain(
      prev.copyWith(
        systemControl: nextControl,
        activities: _appendActivity(
          prev,
          category: ActivityCategory.sistema,
          action: en
              ? 'Publishing policies updated'
              : 'Políticas de publicação atualizadas',
          detail: en
              ? 'Automated publishing=${nextControl.publishingEnabled ? 'On' : 'Off'} · Public operation=${nextControl.phaseBPublicAllowed ? 'Allowed' : 'Private'}'
              : 'Publicação automática=${nextControl.publishingEnabled ? 'Ativa' : 'Desligada'} · Operação pública=${nextControl.phaseBPublicAllowed ? 'Liberada' : 'Privada'}',
          actor: en ? 'Owner' : 'Proprietário',
          severity: ActivitySeverity.warning,
        ),
      ),
    );
  }

  Brand createBrand(BrandCreateInput input) {
    final en = _langNow == UiLanguage.enUS;
    final now = _nowUtc();
    final isEurope = input.market.contains('França') ||
        input.market.contains('France') ||
        input.market.contains('Europa') ||
        input.market.contains('EU');

    final newBrand = Brand(
      id: 'brand-${now.millisecondsSinceEpoch.toRadixString(36)}-${_nextSuffix()}',
      name: input.name,
      slug: input.slug,
      niche: input.niche,
      segment: input.segment,
      market: input.market,
      language: input.language,
      timezone: input.timezone ?? (isEurope ? 'Europe/Paris' : 'America/Sao_Paulo'),
      publishWindow: input.publishWindow ?? '18:00-21:00',
      archetype: input.archetype ?? BrandArchetype.hibrida,
      validationStage: input.validationStage ?? ValidationStage.exploracao,
      pillars: input.pillars ??
          (en
              ? const [
                  'Technical Diagnosis',
                  'Practical Comparison',
                  'Transparent Recommendation',
                ]
              : const [
                  'Diagnóstico Técnico',
                  'Comparativo Prático',
                  'Recomendação Transparente',
                ]),
      status: input.status,
      accentColor: input.accentColor,
      secondaryColor: input.secondaryColor,
      typographyNote: input.typographyNote,
      tagline: input.tagline,
      description: input.description,
      createdAt: now.toIso8601String().substring(0, 10),
    );

    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    _commitDomain(
      prev.copyWith(
        brands: [newBrand, ...prev.brands],
        activities: _appendActivity(
          prev,
          brandId: newBrand.id,
          category: ActivityCategory.sistema,
          action: isEn
              ? 'Brand created: ${newBrand.name}'
              : 'Marca criada: ${newBrand.name}',
          detail: '${newBrand.niche} (${newBrand.market} · ${newBrand.timezone})',
          severity: ActivitySeverity.success,
        ),
      ),
    );
    return newBrand;
  }

  void updateBrand(String id, BrandUpdatePatch patch) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    _commitDomain(
      prev.copyWith(
        brands: prev.brands
            .map(
              (b) => b.id == id
                  ? b.copyWith(
                      name: patch.name,
                      slug: patch.slug,
                      niche: patch.niche,
                      segment: patch.segment,
                      market: patch.market,
                      language: patch.language,
                      timezone: patch.timezone,
                      publishWindow: patch.publishWindow,
                      archetype: patch.archetype,
                      validationStage: patch.validationStage,
                      pillars: patch.pillars,
                      status: patch.status,
                      accentColor: patch.accentColor,
                      secondaryColor: patch.secondaryColor,
                      typographyNote: patch.typographyNote,
                      tagline: patch.tagline,
                      description: patch.description,
                    )
                  : b,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: id,
          category: ActivityCategory.sistema,
          action:
              isEn ? 'Brand profile updated' : 'Dados da marca atualizados',
          detail: isEn
              ? 'Identity parameters, IANA timezone, validation stage, or editorial pillars updated.'
              : 'Parâmetros de identidade, fuso IANA, estágio ou pilares atualizados.',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  void changeBrandStatus(
    String id,
    BrandStatus status,
    String justification,
  ) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    Brand? target;
    for (final b in prev.brands) {
      if (b.id == id) {
        target = b;
        break;
      }
    }

    _commitDomain(
      prev.copyWith(
        brands: prev.brands
            .map((b) => b.id == id ? b.copyWith(status: status) : b)
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: id,
          category: ActivityCategory.decisao,
          action: isEn
              ? 'Brand ${target?.name ?? id}: ${status.wire}'
              : 'Marca ${target?.name ?? id}: ${status.wire}',
          detail: isEn
              ? 'Operational status changed to ${status.wire}.'
              : 'Status operacional alterado para ${status.wire}.',
          justification: justification,
          severity: status == BrandStatus.archived
              ? ActivitySeverity.warning
              : ActivitySeverity.info,
        ),
      ),
    );
  }

  Product createProduct(ProductCreateInput input) {
    final lang = _langNow;
    final en = lang == UiLanguage.enUS;
    final now = _nowUtc();
    final nowIso = now.toIso8601String();
    final tempProd = Product(
      id: 'prod-${now.millisecondsSinceEpoch.toRadixString(36)}-${_nextSuffix()}',
      externalId: input.externalId ??
          'CAT-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      brandId: input.brandId,
      linkedBrandIds: input.linkedBrandIds ?? [input.brandId],
      isTest: input.isTest ?? false,
      name: input.name,
      category: input.category,
      platform: input.platform,
      remunerationModel: input.remunerationModel,
      price: input.price,
      currency: input.currency,
      commissionRatePct: input.commissionRatePct,
      cpaValue: input.cpaValue,
      epcValue: input.epcValue,
      cookieWindowDays: input.cookieWindowDays,
      opportunityScore: input.opportunityScore,
      dataConfidence: input.dataConfidence ??
          (input.epcValue == null
              ? DataConfidence.baixa
              : DataConfidence.media),
      qualityGrade: input.qualityGrade ?? ProductQualityGrade.b,
      complianceState: input.complianceState ?? ComplianceState.pending,
      complianceMarket: input.complianceMarket ?? 'Brasil',
      demandTrendPct: input.demandTrendPct,
      competitionLevel: input.competitionLevel,
      status: input.status,
      evidence: [
        ProductEvidence(
          id: 'ev-${now.millisecondsSinceEpoch}-${_nextSuffix()}',
          sourceName:
              en ? 'Manual Entry (Owner)' : 'Cadastro Manual (Proprietário)',
          url: 'https://vyron.internal',
          summary: en
              ? 'Product registered in shared catalog (${input.platform}).'
              : 'Produto registrado no catálogo compartilhado (${input.platform}).',
          verifiedAt: nowIso.substring(0, 10),
        ),
      ],
      decisions: const [],
      updatedAt: nowIso,
    );

    final computed = scoreProductV61(tempProd, language: lang);
    final finalScore = input.opportunityScore ?? computed.score;
    final finalProd = finalScore == null
        ? tempProd.copyWith(clearOpportunityScore: true)
        : tempProd.copyWith(opportunityScore: finalScore);

    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    final scoreText = finalProd.opportunityScore != null
        ? '${finalProd.opportunityScore}/100'
        : (isEn ? 'Not provided' : 'Sem dados');

    _commitDomain(
      prev.copyWith(
        products: [finalProd, ...prev.products],
        activities: _appendActivity(
          prev,
          brandId: finalProd.brandId,
          category: ActivityCategory.produto,
          action: isEn
              ? 'Product registered: ${finalProd.name}'
              : 'Produto cadastrado: ${finalProd.name}',
          detail:
              '${isEn ? 'Index' : 'Índice'} $scoreText · ${finalProd.currency.wire} · ${finalProd.platform}',
          severity: ActivitySeverity.info,
        ),
      ),
    );
    return finalProd;
  }

  void changeProductStatus(
    String id,
    ProductStatus nextStatus,
    String justification,
  ) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    Product? target;
    for (final p in prev.products) {
      if (p.id == id) {
        target = p;
        break;
      }
    }
    if (target == null) return;

    final updatedProd = transitionProductStatus(
      target,
      nextStatus,
      justification,
      actor: isEn ? 'Owner' : 'Proprietário',
      timestamp: _nowUtc().toIso8601String(),
    );

    _commitDomain(
      prev.copyWith(
        products: prev.products
            .map((p) => p.id == id ? updatedProd : p)
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.decisao,
          action: isEn
              ? 'Product ${nextStatus.wire}: ${target.name}'
              : 'Produto ${nextStatus.wire}: ${target.name}',
          detail: isEn
              ? 'Status changed from ${target.status.wire} to ${nextStatus.wire}.'
              : 'Status alterado de ${target.status.wire} para ${nextStatus.wire}.',
          justification: justification,
          severity: nextStatus == ProductStatus.approved
              ? ActivitySeverity.success
              : ActivitySeverity.warning,
        ),
      ),
    );
  }

  void updateProductGovernance(String id, ProductGovernancePatch patch) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    Product? target;
    for (final p in prev.products) {
      if (p.id == id) {
        target = p;
        break;
      }
    }
    if (target == null) return;

    final nextQuality = patch.clearQualityGrade
        ? null
        : (patch.qualityGrade ?? target.qualityGrade);
    final nextCompliance = patch.complianceState ?? target.complianceState;

    _commitDomain(
      prev.copyWith(
        products: prev.products
            .map(
              (p) => p.id == id
                  ? p.copyWith(
                      qualityGrade: patch.qualityGrade,
                      clearQualityGrade: patch.clearQualityGrade,
                      complianceState: patch.complianceState,
                      linkedBrandIds: patch.linkedBrandIds,
                      updatedAt: _nowUtc().toIso8601String(),
                    )
                  : p,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.produto,
          action: isEn
              ? 'Governance updated: ${target.name}'
              : 'Governança atualizada: ${target.name}',
          detail: isEn
              ? 'Quality=${nextQuality?.wire ?? 'N/A'} · Compliance=${nextCompliance.wire}'
              : 'Qualidade=${nextQuality?.wire ?? 'N/D'} · Conformidade=${nextCompliance.wire}',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  ContentItem generateContentFromProduct(
    String productId,
    String channelId,
    ContentFormat format,
  ) {
    final en = _langNow == UiLanguage.enUS;
    final nowIso = _nowUtc().toIso8601String();
    Product? prod;
    for (final p in state.domain.products) {
      if (p.id == productId) {
        prod = p;
        break;
      }
    }

    final title = prod != null
        ? (en ? 'Technical Review: ${prod.name}' : 'Análise Técnica: ${prod.name}')
        : (en ? 'New Product Content Plan' : 'Nova Pauta de Produto');

    return createContent(
      ContentCreateInput(
        brandId: prod?.brandId ?? state.domain.brands.first.id,
        channelId: channelId,
        productId: productId,
        title: title,
        description: prod != null
            ? (en
                ? 'Rigorous evaluation of ${prod.name} with market evidence and transparent disclosure.'
                : 'Avaliação criteriosa de ${prod.name} com evidências de mercado e divulgação transparente.')
            : (en
                ? 'Content plan generated from catalog.'
                : 'Pauta gerada a partir do catálogo.'),
        format: format,
        category: ContentCategory.comercialContextual,
        visibility: ContentVisibility.privateVis,
        analysisMethod: AnalysisMethod.analiseDocumental,
        status: ContentStatus.brief,
        scheduledDate: '2026-11-26',
        brief: prod != null
            ? (en
                ? 'Explore the value proposition of ${prod.name} (${prod.platform}, commission ${prod.commissionRatePct ?? 'N/A'}%).'
                : 'Explorar proposta de valor de ${prod.name} (${prod.platform}, comissão ${prod.commissionRatePct ?? 'N/D'}%).')
            : (en
                ? 'Content plan created from catalog.'
                : 'Planejamento criado a partir do catálogo.'),
        angleIdea: en
            ? 'Technical demonstration with verified evidence and objective comparison.'
            : 'Demonstrativo técnico com evidências reais e comparação objetiva.',
        script: en
            ? '1. Real user problem\n2. Specs and boundaries review\n3. Cost-benefit and transparent recommendation.'
            : '1. Problema real do usuário\n2. Análise de especificações e limites\n3. Custo-benefício e recomendação transparente.',
        affiliateLinkUrl: prod != null
            ? 'https://vyron.link/${prod.externalId.toLowerCase()}'
            : '',
        verifiedDestinationUrl:
            prod != null && prod.evidence.isNotEmpty ? prod.evidence.first.url : '',
        linkVerifiedAt:
            prod != null && prod.evidence.isNotEmpty ? nowIso : '',
        commercialConditionsVerifiedAt: prod != null ? nowIso : '',
        affiliateDisclosure: en
            ? 'Advertising / Affiliate links: we may earn a commission at no extra cost.'
            : 'Publicidade / Links de afiliado: podemos receber comissão sem custo extra.',
        references:
            prod?.evidence.map((e) => e.sourceName).toList() ?? const [],
      ),
    );
  }

  ContentItem createContent(ContentCreateInput input) {
    final en = _langNow == UiLanguage.enUS;
    final now = _nowUtc();
    final nowIso = now.toIso8601String();

    final baseItem = ContentItem(
      id: 'cnt-${now.millisecondsSinceEpoch.toRadixString(36)}-${_nextSuffix()}',
      brandId: input.brandId,
      channelId: input.channelId,
      productId: input.productId,
      title: input.title,
      description: input.description ?? input.brief,
      format: input.format,
      category: input.category ?? ContentCategory.comercialContextual,
      visibility: input.visibility ?? ContentVisibility.privateVis,
      analysisMethod: input.analysisMethod ?? AnalysisMethod.analiseDocumental,
      sensitiveTopic: input.sensitiveTopic ?? SensitiveTopic.nenhum,
      unclassifiedRiskFlag: input.unclassifiedRiskFlag ?? false,
      status: input.status,
      scheduledDate: input.scheduledDate,
      publishedAt: input.publishedAt,
      brief: input.brief,
      angleIdea: input.angleIdea,
      script: input.script,
      affiliateLinkUrl: input.affiliateLinkUrl ?? '',
      verifiedDestinationUrl: input.verifiedDestinationUrl ?? '',
      linkVerifiedAt: input.linkVerifiedAt ?? '',
      commercialConditionsVerifiedAt:
          input.commercialConditionsVerifiedAt ?? '',
      offerEndsAt: input.offerEndsAt,
      affiliateDisclosure: input.affiliateDisclosure ??
          (en
              ? 'Content with potential commercial relationship. Transparent disclosure applied.'
              : 'Conteúdo com possível vínculo comercial. Transparência conforme CDC/CONAR.'),
      aiDisclosureRequired: input.aiDisclosureRequired ?? false,
      aiDisclosureText: input.aiDisclosureText ?? '',
      relevanceTestPassed: input.relevanceTestPassed ?? false,
      editorialChecklistPassed: input.editorialChecklistPassed ?? false,
      humanHoursLogged: input.humanHoursLogged ?? 1.0,
      dossier: input.dossier ?? const [],
      references: input.references,
      currentManifestHash: '',
      authorization: null,
      versions: const [],
      metrics: input.metrics,
    );

    final hash = computeContentItemManifestHash(baseItem);
    final newItem = baseItem.copyWith(
      currentManifestHash: hash,
      versions: [
        ContentVersion(
          version: 'v1.0',
          manifestHash: hash,
          author: en ? 'Owner' : 'Proprietário',
          note: en
              ? 'Content plan created in Content Studio.'
              : 'Planejamento criado no Content Studio.',
          timestamp: nowIso,
          scriptSnapshot: baseItem.script,
        ),
      ],
    );

    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    _commitDomain(
      prev.copyWith(
        contents: [newItem, ...prev.contents],
        activities: _appendActivity(
          prev,
          brandId: newItem.brandId,
          category: ActivityCategory.conteudo,
          action: isEn
              ? 'Content created: ${newItem.title}'
              : 'Conteúdo criado: ${newItem.title}',
          detail:
              '${newItem.format.wire} · ${newItem.visibility.wire} · Hash ${hash.substring(0, 10)}...',
          severity: ActivitySeverity.info,
        ),
      ),
    );
    return newItem;
  }

  void updateContent(
    String id,
    ContentUpdatePatch patch, {
    String? versionNote,
  }) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    ContentItem? target;
    for (final c in prev.contents) {
      if (c.id == id) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    final merged = target.copyWith(
      brandId: patch.brandId,
      channelId: patch.channelId,
      productId: patch.productId,
      clearProductId: patch.clearProductId,
      title: patch.title,
      description: patch.description,
      format: patch.format,
      category: patch.category,
      visibility: patch.visibility,
      analysisMethod: patch.analysisMethod,
      sensitiveTopic: patch.sensitiveTopic,
      unclassifiedRiskFlag: patch.unclassifiedRiskFlag,
      status: patch.status,
      scheduledDate: patch.scheduledDate,
      publishedAt: patch.publishedAt,
      brief: patch.brief,
      angleIdea: patch.angleIdea,
      script: patch.script,
      affiliateLinkUrl: patch.affiliateLinkUrl,
      verifiedDestinationUrl: patch.verifiedDestinationUrl,
      linkVerifiedAt: patch.linkVerifiedAt,
      commercialConditionsVerifiedAt: patch.commercialConditionsVerifiedAt,
      offerEndsAt: patch.offerEndsAt,
      affiliateDisclosure: patch.affiliateDisclosure,
      aiDisclosureRequired: patch.aiDisclosureRequired,
      aiDisclosureText: patch.aiDisclosureText,
      relevanceTestPassed: patch.relevanceTestPassed,
      editorialChecklistPassed: patch.editorialChecklistPassed,
      humanHoursLogged: patch.humanHoursLogged,
      dossier: patch.dossier,
      references: patch.references,
      metrics: patch.metrics,
    );

    final newHash = computeContentItemManifestHash(merged);
    final manifestChanged = merged.brandId != target.brandId ||
        merged.channelId != target.channelId ||
        merged.productId != target.productId ||
        merged.title != target.title ||
        merged.description != target.description ||
        merged.format != target.format ||
        merged.category != target.category ||
        merged.visibility != target.visibility ||
        merged.analysisMethod != target.analysisMethod ||
        merged.sensitiveTopic != target.sensitiveTopic ||
        merged.script != target.script ||
        merged.affiliateLinkUrl != target.affiliateLinkUrl ||
        merged.affiliateDisclosure != target.affiliateDisclosure ||
        merged.aiDisclosureRequired != target.aiDisclosureRequired ||
        merged.aiDisclosureText != target.aiDisclosureText;

    final hadAuth = target.authorization != null;
    final nextStatus =
        manifestChanged && target.status == ContentStatus.approved
            ? ContentStatus.inReview
            : merged.status;

    var nextVersions = merged.versions;
    if (versionNote != null || (manifestChanged && hadAuth)) {
      nextVersions = [
        ContentVersion(
          version: 'v${target.versions.length + 1}.0',
          manifestHash: newHash,
          author: isEn ? 'Owner' : 'Proprietário',
          note: versionNote ??
              (isEn
                  ? 'Manifest modified: prior authorization invalidated (zero inheritance).'
                  : 'Manifesto alterado: autorização anterior invalidada (herança zero).'),
          timestamp: _nowUtc().toIso8601String(),
          scriptSnapshot: merged.script,
        ),
        ...target.versions,
      ];
    }

    // Herança zero: qualquer alteração nos campos do manifesto invalida a autorização anterior
    final updatedItem = merged.copyWith(
      status: nextStatus,
      currentManifestHash: newHash,
      clearAuthorization: manifestChanged,
      versions: nextVersions,
    );

    _commitDomain(
      prev.copyWith(
        contents: prev.contents
            .map((c) => c.id == id ? updatedItem : c)
            .toList(),
        activities: manifestChanged && hadAuth
            ? _appendActivity(
                prev,
                brandId: target.brandId,
                category: ActivityCategory.autorizacaoHash,
                action: isEn
                    ? 'Hash invalidated by edit: ${target.title}'
                    : 'Hash invalidado por edição: ${target.title}',
                detail: isEn
                    ? 'New hash ${newHash.substring(0, 12)}... will require a new individual authorization before delivery.'
                    : 'Novo hash ${newHash.substring(0, 12)}... exigirá nova autorização individual antes de envio.',
                severity: ActivitySeverity.warning,
              )
            : prev.activities,
      ),
    );
  }

  void changeContentStatus(
    String id,
    ContentStatus nextStatus,
    String note, {
    FeedbackCategory? feedbackCategory,
  }) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    ContentItem? target;
    for (final c in prev.contents) {
      if (c.id == id) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    final updated = transitionContentStatus(
      target,
      nextStatus,
      note,
      author: isEn ? 'Owner' : 'Proprietário',
      timestamp: _nowUtc().toIso8601String(),
      feedbackCategory: feedbackCategory,
    );

    _commitDomain(
      prev.copyWith(
        contents: prev.contents
            .map((c) => c.id == id ? updated : c)
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.conteudo,
          action: isEn
              ? 'Content ${nextStatus.wire}: ${target.title}'
              : 'Conteúdo ${nextStatus.wire}: ${target.title}',
          detail: isEn
              ? 'Moved from ${target.status.wire} to ${nextStatus.wire}.'
              : 'Movido de ${target.status.wire} para ${nextStatus.wire}.',
          justification: note,
          severity: nextStatus == ContentStatus.published ||
                  nextStatus == ContentStatus.approved
              ? ActivitySeverity.success
              : ActivitySeverity.info,
        ),
      ),
    );
  }

  void authorizeContentVersion(
    String id, {
    required String actor,
    required int validHours,
    String? note,
  }) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    ContentItem? target;
    for (final c in prev.contents) {
      if (c.id == id) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    final now = _nowUtc();
    final hash = computeContentItemManifestHash(target);
    var computedExpiry = now.add(Duration(hours: validHours));
    if (target.offerEndsAt != null && target.offerEndsAt!.isNotEmpty) {
      final parsedOffer = DateTime.tryParse(target.offerEndsAt!)?.toUtc();
      if (parsedOffer != null && parsedOffer.isBefore(computedExpiry)) {
        computedExpiry = parsedOffer;
      }
    }
    final expiresAt = computedExpiry.toIso8601String();
    final normalizedActor =
        actor.trim().isNotEmpty ? actor.trim() : (isEn ? 'Owner' : 'Proprietário');

    final auth = ContentAuthorization(
      type: AuthorizationType.individual,
      authorizedHash: hash,
      actor: normalizedActor,
      authorizedAt: now.toIso8601String(),
      expiresAt: expiresAt,
      rulesVersion: 'v1.0',
      evidenceVerifiedAt: target.linkVerifiedAt.isNotEmpty
          ? target.linkVerifiedAt
          : now.toIso8601String(),
      offerEndsAt: target.offerEndsAt,
    );

    final updated = target.copyWith(
      status: target.status == ContentStatus.published
          ? ContentStatus.published
          : ContentStatus.approved,
      currentManifestHash: hash,
      authorization: auth,
      versions: [
        ContentVersion(
          version: 'v${target.versions.length + 1}.0',
          manifestHash: hash,
          author: auth.actor,
          note: (note != null && note.trim().isNotEmpty)
              ? note.trim()
              : (isEn
                  ? 'Individual authorization bound to hash ${hash.substring(0, 12)}...'
                  : 'Autorização individual vinculada ao hash ${hash.substring(0, 12)}...'),
          feedbackCategory: FeedbackCategory.aprovacao,
          timestamp: now.toIso8601String(),
          scriptSnapshot: target.script,
        ),
        ...target.versions,
      ],
    );

    _commitDomain(
      prev.copyWith(
        contents: prev.contents
            .map((c) => c.id == id ? updated : c)
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.autorizacaoHash,
          action: isEn
              ? 'Authorization issued: ${target.title}'
              : 'Autorização emitida: ${target.title}',
          detail: isEn
              ? "Hash ${hash.substring(0, 12)}... · Visibility '${target.visibility.wire}' · Expires ${expiresAt.substring(0, 16).replaceFirst('T', ' ')}"
              : "Hash ${hash.substring(0, 12)}... · Visibilidade '${target.visibility.wire}' · Expira ${expiresAt.substring(0, 16).replaceFirst('T', ' ')}",
          justification: (note != null && note.isNotEmpty)
              ? note
              : (isEn
                  ? 'Individual human verification across all 6 pre-send checks.'
                  : 'Verificação humana individual das 6 travas pré-envio.'),
          actor: auth.actor,
          severity: ActivitySeverity.success,
        ),
      ),
    );
  }

  void revokeContentAuthorization(String id, String reason) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    ContentItem? target;
    for (final c in prev.contents) {
      if (c.id == id) {
        target = c;
        break;
      }
    }
    if (target == null || target.authorization == null) return;

    final resolvedReason = reason.trim().isNotEmpty
        ? reason.trim()
        : (isEn
            ? 'Manually revoked by owner.'
            : 'Revogada manualmente pelo proprietário.');

    _commitDomain(
      prev.copyWith(
        contents: prev.contents
            .map(
              (c) => c.id == id
                  ? c.copyWith(
                      status: c.status == ContentStatus.approved
                          ? ContentStatus.inReview
                          : c.status,
                      authorization: c.authorization!.copyWith(
                        revoked: true,
                        revokedReason: resolvedReason,
                      ),
                    )
                  : c,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.autorizacaoHash,
          action: isEn
              ? 'Authorization revoked: ${target.title}'
              : 'Autorização revogada: ${target.title}',
          detail: isEn
              ? 'External delivery blocked until a new individual approval is granted.'
              : 'Envio externo bloqueado até nova aprovação individual.',
          justification: reason,
          severity: ActivitySeverity.warning,
        ),
      ),
    );
  }

  void revalidateContentEvidence(String id) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    final nowIso = _nowUtc().toIso8601String();
    ContentItem? target;
    for (final c in prev.contents) {
      if (c.id == id) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    _commitDomain(
      prev.copyWith(
        contents: prev.contents
            .map(
              (c) => c.id == id
                  ? c.copyWith(
                      verifiedDestinationUrl: c.verifiedDestinationUrl.isNotEmpty
                          ? c.verifiedDestinationUrl
                          : (c.affiliateLinkUrl.isNotEmpty
                              ? c.affiliateLinkUrl
                              : 'https://destino-verificado.demo'),
                      linkVerifiedAt: nowIso,
                      commercialConditionsVerifiedAt: nowIso,
                    )
                  : c,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.conteudo,
          action: isEn
              ? 'Evidence & link revalidated: ${target.title}'
              : 'Evidência e link revalidados: ${target.title}',
          detail: isEn
              ? 'Timestamp updated to ${nowIso.substring(0, 16).replaceFirst('T', ' ')}.'
              : 'Timestamp atualizado para ${nowIso.substring(0, 16).replaceFirst('T', ' ')}.',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  void rejectContentWithFeedback(
    String id, {
    required FeedbackCategory category,
    required String note,
  }) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    ContentItem? target;
    for (final c in prev.contents) {
      if (c.id == id) {
        target = c;
        break;
      }
    }
    if (target == null) return;

    final updated = transitionContentStatus(
      target,
      ContentStatus.rejected,
      '[${category.wire}] $note',
      author: isEn ? 'Owner' : 'Proprietário',
      timestamp: _nowUtc().toIso8601String(),
      feedbackCategory: category,
    );

    _commitDomain(
      prev.copyWith(
        contents: prev.contents
            .map((c) => c.id == id ? updated : c)
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target.brandId,
          category: ActivityCategory.decisao,
          action: isEn
              ? 'Content rejected (${category.wire}): ${target.title}'
              : 'Conteúdo rejeitado (${category.wire}): ${target.title}',
          detail: isEn
              ? 'Structured feedback recorded in adaptive history.'
              : 'Feedback estruturado gravado no histórico adaptativo.',
          justification: note,
          severity: ActivitySeverity.warning,
        ),
      ),
    );
  }

  Channel createChannel(ChannelCreateInput input) {
    final now = _nowUtc();
    final ch = Channel(
      id: 'ch-${now.millisecondsSinceEpoch.toRadixString(36)}-${_nextSuffix()}',
      brandId: input.brandId,
      name: input.name,
      handle: input.handle,
      platform: input.platform,
      language: input.language,
      advancedFeaturesUnlocked: input.advancedFeaturesUnlocked ?? false,
      integrationStatus: input.integrationStatus,
      followers: input.followers,
      growthPct30d: input.growthPct30d,
      views30d: input.views30d,
      reach30d: input.reach30d,
      engagementRatePct: input.engagementRatePct,
      shortsToLongPct: input.shortsToLongPct,
      publications30d: input.publications30d,
      lastSyncAt: now.toIso8601String(),
    );

    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    _commitDomain(
      prev.copyWith(
        channels: [ch, ...prev.channels],
        activities: _appendActivity(
          prev,
          brandId: ch.brandId,
          category: ActivityCategory.sistema,
          action: isEn
              ? 'Channel connected (Demo): ${ch.name}'
              : 'Canal conectado (Demo): ${ch.name}',
          detail: '${ch.platform.wire} · ${ch.handle}',
          severity: ActivitySeverity.success,
        ),
      ),
    );
    return ch;
  }

  void syncChannelDemo(String id) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    Channel? target;
    for (final c in prev.channels) {
      if (c.id == id) {
        target = c;
        break;
      }
    }

    _commitDomain(
      prev.copyWith(
        channels: prev.channels
            .map(
              (c) => c.id == id
                  ? c.copyWith(
                      integrationStatus:
                          ChannelIntegrationStatus.configuradoDemo,
                      lastSyncAt: _nowUtc().toIso8601String(),
                    )
                  : c,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          brandId: target?.brandId,
          category: ActivityCategory.sistema,
          action: isEn
              ? 'Demo sync completed: ${target?.name ?? id}'
              : 'Sincronização demonstrativa: ${target?.name ?? id}',
          detail: isEn
              ? 'Read-only metrics updated in prototype environment.'
              : 'Métricas de leitura atualizadas no ambiente de protótipo.',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  void addFinanceEntry(FinanceEntryCreateInput input) {
    final now = _nowUtc();
    final entry = FinanceEntry(
      id: 'fin-${now.millisecondsSinceEpoch.toRadixString(36)}-${_nextSuffix()}',
      brandId: input.brandId,
      productId: input.productId,
      platform: input.platform,
      description: input.description,
      type: input.type,
      stage: input.stage,
      amount: input.amount,
      currency: input.currency,
      fxRateToBRL: input.fxRateToBRL,
      fxSource: input.fxSource,
      date: input.date,
      isTest: input.isTest,
      isProjection: input.isProjection,
    );

    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    _commitDomain(
      prev.copyWith(
        financeEntries: [entry, ...prev.financeEntries],
        activities: _appendActivity(
          prev,
          brandId: entry.brandId,
          category: ActivityCategory.financas,
          action: isEn
              ? 'Financial entry (${entry.stage.wire}): ${entry.description}'
              : 'Registro financeiro (${entry.stage.wire}): ${entry.description}',
          detail:
              '${entry.type.wire} · ${entry.amount.toStringAsFixed(2)} ${entry.currency.wire}',
          severity: entry.stage == CommissionStage.received
              ? ActivitySeverity.success
              : ActivitySeverity.info,
        ),
      ),
    );
  }

  void toggleAgentRun(String id) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    if (prev.systemControl.state == SystemControlStatus.halted ||
        prev.settings.emergencyStopActive) {
      return;
    }

    AutomationAgent? target;
    for (final a in prev.automations) {
      if (a.id == id) {
        target = a;
        break;
      }
    }
    if (target == null) return;

    final now = _nowUtc();
    final nowIso = now.toIso8601String();
    final nextState = target.state == AgentRunState.running
        ? AgentRunState.paused
        : AgentRunState.running;

    _commitDomain(
      prev.copyWith(
        automations: prev.automations
            .map(
              (a) => a.id == id
                  ? a.copyWith(
                      state: nextState,
                      lastRunAt: nowIso,
                      history: [
                        AgentExecutionLog(
                          id: 'exec-${now.millisecondsSinceEpoch}-${_nextSuffix()}',
                          timestamp: nowIso,
                          status: nextState == AgentRunState.running
                              ? AgentExecutionStatus.success
                              : AgentExecutionStatus.paused,
                          durationSec: nextState == AgentRunState.running ? 6 : 0,
                          summary: nextState == AgentRunState.running
                              ? (isEn
                                  ? 'Demo execution started respecting policy limits.'
                                  : 'Execução demonstrativa iniciada respeitando políticas de limite.')
                              : (isEn
                                  ? 'Agent manually paused by owner.'
                                  : 'Agente pausado manualmente pelo proprietário.'),
                          recordsAffected:
                              nextState == AgentRunState.running ? 3 : 0,
                        ),
                        ...a.history,
                      ],
                    )
                  : a,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          category: ActivityCategory.automacao,
          action: isEn
              ? 'Agent ${nextState == AgentRunState.running ? 'started' : 'paused'}: ${target.name}'
              : 'Agente ${nextState == AgentRunState.running ? 'iniciado' : 'pausado'}: ${target.name}',
          detail: isEn
              ? 'State changed from ${target.state.wire} to ${nextState.wire}.'
              : 'Estado alterado de ${target.state.wire} para ${nextState.wire}.',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  void updateAgentLimits(String id, AgentPolicyLimits limits) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    _commitDomain(
      prev.copyWith(
        automations: prev.automations
            .map((a) => a.id == id ? a.copyWith(limits: limits) : a)
            .toList(),
        activities: _appendActivity(
          prev,
          category: ActivityCategory.automacao,
          action: isEn
              ? 'Agent policy and limits updated'
              : 'Política e limites de agente atualizados',
          detail: isEn
              ? 'Human approval: ${limits.requireHumanApproval ? 'Required' : 'Waived'} · Daily limit: ${limits.maxActionsPerDay} actions.'
              : 'Aprovação humana: ${limits.requireHumanApproval ? 'Obrigatória' : 'Dispensada'} · Limite diário: ${limits.maxActionsPerDay} ações.',
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  void approveAgentPending(String id) {
    final prev = state.domain;
    final isEn = prev.settings.uiLanguage == UiLanguage.enUS;
    AutomationAgent? target;
    for (final a in prev.automations) {
      if (a.id == id) {
        target = a;
        break;
      }
    }
    if (target == null) return;

    final now = _nowUtc();
    final nowIso = now.toIso8601String();

    _commitDomain(
      prev.copyWith(
        automations: prev.automations
            .map(
              (a) => a.id == id
                  ? a.copyWith(
                      state: AgentRunState.idle,
                      pendingApprovalCount: 0,
                      clearPendingSummary: true,
                      history: [
                        AgentExecutionLog(
                          id: 'exec-app-${now.millisecondsSinceEpoch}-${_nextSuffix()}',
                          timestamp: nowIso,
                          status: AgentExecutionStatus.success,
                          durationSec: 2,
                          summary: isEn
                              ? 'Pending queue authorized by owner.'
                              : 'Fila pendente autorizada pelo proprietário.',
                          recordsAffected: target!.pendingApprovalCount,
                        ),
                        ...a.history,
                      ],
                    )
                  : a,
            )
            .toList(),
        activities: _appendActivity(
          prev,
          category: ActivityCategory.decisao,
          action: isEn
              ? 'Execution approved: ${target.name}'
              : 'Aprovação de execução: ${target.name}',
          detail: isEn
              ? '${target.pendingApprovalCount} pending action(s) authorized.'
              : '${target.pendingApprovalCount} ação(ões) pendente(s) autorizada(s).',
          justification: isEn
              ? 'Manually validated within operational policy bounds.'
              : 'Validado manualmente nos limites da política operacional.',
          severity: ActivitySeverity.success,
        ),
      ),
    );
  }

  PipelineRunResult runPipelineDemo(
    JobMode mode, {
    JobTaskName taskName = JobTaskName.pipelineRun,
  }) {
    final prev = state.domain;
    final lang = prev.settings.uiLanguage;
    final en = lang == UiLanguage.enUS;

    if (mode == JobMode.commit &&
        prev.systemControl.state == SystemControlStatus.halted) {
      final msg = en
          ? 'Write execution blocked: system controls are currently halted.'
          : 'Execução de gravação bloqueada: os controles do sistema estão interrompidos.';
      _commitDomain(
        prev.copyWith(
          activities: _appendActivity(
            prev,
            category: ActivityCategory.jobRun,
            action: en
                ? 'Blocked write execution in ${taskName.wire}'
                : 'Bloqueio de segurança em ${taskName.wire}',
            detail: msg,
            severity: ActivitySeverity.error,
          ),
        ),
      );
      return PipelineRunResult(ok: false, message: msg);
    }

    final nowIso = _nowUtc().toIso8601String();
    final nextId =
        (prev.jobRuns.isNotEmpty ? prev.jobRuns.first.id : 100) + 1;
    final realProducts = prev.products.where((p) => !p.isTest).toList();
    final job = JobRun(
      id: nextId,
      taskName: taskName,
      mode: mode,
      status: JobRunStatus.succeeded,
      startedAt: nowIso,
      finishedAt: nowIso,
      recordsProcessed: realProducts.length,
      summary: mode == JobMode.dryRun
          ? (en
              ? 'Simulation completed without persistent writes (${realProducts.length} products evaluated per currency).'
              : 'Simulação concluída sem gravação persistente (${realProducts.length} produtos avaliados por moeda).')
          : (en
              ? 'Commit executed updating the evaluation index across ${realProducts.length} real products.'
              : 'Gravação executada recalculando o índice de avaliação em ${realProducts.length} produtos reais.'),
    );

    final updatedProducts = mode == JobMode.commit &&
            (taskName == JobTaskName.productsScore ||
                taskName == JobTaskName.pipelineRun)
        ? prev.products.map((p) {
            final res = scoreProductV61(p, language: lang);
            return res.score == null
                ? p.copyWith(clearOpportunityScore: true)
                : p.copyWith(opportunityScore: res.score);
          }).toList()
        : prev.products;

    _commitDomain(
      prev.copyWith(
        products: updatedProducts,
        jobRuns: [job, ...prev.jobRuns],
        activities: _appendActivity(
          prev,
          category: ActivityCategory.jobRun,
          action: en
              ? 'Batch task: ${taskName.wire} (${mode == JobMode.dryRun ? 'simulation' : 'commit'})'
              : 'Tarefa em lote: ${taskName.wire} (${mode == JobMode.dryRun ? 'simulação' : 'gravação'})',
          detail: job.summary,
          actor: 'batch-executor',
          severity: ActivitySeverity.success,
        ),
      ),
    );

    return PipelineRunResult(ok: true, message: job.summary, job: job);
  }

  int reconcileJobsDemo() {
    final prev = state.domain;
    final lang = prev.settings.uiLanguage;
    final en = lang == UiLanguage.enUS;
    final nowIso = _nowUtc().toIso8601String();
    final res = reconcileOrphanedJobRuns(
      prev.jobRuns,
      nowIso: nowIso,
      olderThanMinutes: 30,
      language: lang,
    );
    final nextId =
        (res.updated.isNotEmpty ? res.updated.first.id : 100) + 1;
    final reconcileRun = JobRun(
      id: nextId,
      taskName: JobTaskName.jobsReconcile,
      mode: JobMode.commit,
      status: JobRunStatus.succeeded,
      startedAt: nowIso,
      finishedAt: nowIso,
      recordsProcessed: res.reconciledIds.length,
      summary: res.reconciledIds.isNotEmpty
          ? (en
              ? 'Reconciled ${res.reconciledIds.length} pending run(s): #${res.reconciledIds.join(', #')}.'
              : 'Reconciliadas ${res.reconciledIds.length} execução(ões) pendente(s): #${res.reconciledIds.join(', #')}.')
          : (en
              ? 'No pending runs found.'
              : 'Nenhuma execução pendente encontrada.'),
    );

    _commitDomain(
      prev.copyWith(
        jobRuns: [reconcileRun, ...res.updated],
        activities: _appendActivity(
          prev,
          category: ActivityCategory.jobRun,
          action: en ? 'Runs reconciliation' : 'Reconciliação de execuções',
          detail: reconcileRun.summary,
          actor: en ? 'Owner' : 'Proprietário',
          severity: res.reconciledIds.isNotEmpty
              ? ActivitySeverity.warning
              : ActivitySeverity.info,
        ),
      ),
    );
    return res.reconciledIds.length;
  }

  int haltSystemControl(String actor, String reason) {
    final prev = state.domain;
    final lang = prev.settings.uiLanguage;
    final en = lang == UiLanguage.enUS;
    final now = _nowUtc();
    final nowIso = now.toIso8601String();
    final res = applyStopAllToAutomations(
      prev.automations,
      timestamp: nowIso,
      language: lang,
    );

    final resolvedActor =
        actor.trim().isNotEmpty ? actor.trim() : (en ? 'Owner' : 'Proprietário');
    final resolvedReason = reason.trim().isNotEmpty
        ? reason.trim()
        : (en ? 'Immediate halt triggered.' : 'Interrupção imediata acionada.');
    final resolvedJustification = reason.trim().isNotEmpty
        ? reason.trim()
        : (en
            ? 'Owner emergency command.'
            : 'Comando de emergência do proprietário.');

    final alertNotif = NotificationItem(
      id: 'not-stop-${now.millisecondsSinceEpoch}-${_nextSuffix()}',
      type: NotificationType.operational,
      title: en
          ? 'Stop All triggered (System Halted)'
          : 'Stop All acionado (Sistema Interrompido)',
      message: en
          ? '${res.stoppedCount} agent(s) paused. Automated writes and external deliveries blocked.'
          : '${res.stoppedCount} agente(s) pausado(s). Execuções de gravação e envios externos bloqueados.',
      timestamp: nowIso,
      read: false,
      targetModule: NavModule.automations,
      actionRequired: false,
    );

    _commitDomain(
      prev.copyWith(
        automations: res.updated,
        notifications: [alertNotif, ...prev.notifications],
        systemControl: prev.systemControl.copyWith(
          state: SystemControlStatus.halted,
          actor: resolvedActor,
          reason: resolvedReason,
          updatedAt: nowIso,
        ),
        settings: prev.settings.copyWith(
          emergencyStopActive: true,
          globalAutonomyEnabled: false,
        ),
        activities: _appendActivity(
          prev,
          category: ActivityCategory.stopAll,
          action: en
              ? 'STOP ALL — System controls halted'
              : 'STOP ALL — Controles do sistema interrompidos',
          detail: en
              ? '${res.stoppedCount} agent(s) halted. Safety lock active in the audit log.'
              : '${res.stoppedCount} agente(s) interrompido(s). Bloqueio de segurança ativo no registro de auditoria.',
          justification: resolvedJustification,
          actor: resolvedActor,
          severity: ActivitySeverity.error,
        ),
      ),
    );
    return res.stoppedCount;
  }

  ResumeControlResult resumeSystemControl(String actor, String reason) {
    final prev = state.domain;
    final lang = prev.settings.uiLanguage;
    final en = lang == UiLanguage.enUS;
    final resolvedActor =
        actor.trim().isNotEmpty ? actor.trim() : (en ? 'Owner' : 'Proprietário');

    final gate = canResumeSystemControl(prev.jobRuns, language: lang);
    if (!gate.allowed) {
      _commitDomain(
        prev.copyWith(
          activities: _appendActivity(
            prev,
            category: ActivityCategory.stopAll,
            action: en
                ? 'Resume attempt blocked'
                : 'Tentativa de retomada bloqueada',
            detail: gate.reason ??
                (en
                    ? 'Pending runs still exist.'
                    : 'Existem execuções pendentes.'),
            actor: resolvedActor,
            severity: ActivitySeverity.warning,
          ),
        ),
      );
      return ResumeControlResult(ok: false, reason: gate.reason);
    }

    final nowIso = _nowUtc().toIso8601String();
    _commitDomain(
      prev.copyWith(
        systemControl: prev.systemControl.copyWith(
          state: SystemControlStatus.active,
          actor: resolvedActor,
          reason: reason.trim().isNotEmpty
              ? reason.trim()
              : (en
                  ? 'System resumed after verification.'
                  : 'Sistema retomado após verificação.'),
          updatedAt: nowIso,
        ),
        settings: prev.settings.copyWith(
          emergencyStopActive: false,
          globalAutonomyEnabled: true,
        ),
        activities: _appendActivity(
          prev,
          category: ActivityCategory.stopAll,
          action: en
              ? 'SYSTEM RESUMED — Controls active'
              : 'SISTEMA RETOMADO — Controles ativos',
          detail: en
              ? 'Controlled autonomy and write executions restored after clean reconciliation.'
              : 'Autonomia controlada e execuções liberadas após reconciliação limpa.',
          justification: reason.trim().isNotEmpty
              ? reason.trim()
              : (en
                  ? 'Explicit resume by owner.'
                  : 'Retomada explícita pelo proprietário.'),
          actor: resolvedActor,
          severity: ActivitySeverity.success,
        ),
      ),
    );
    return const ResumeControlResult(ok: true);
  }

  int triggerStopAll() {
    final en = _langNow == UiLanguage.enUS;
    return haltSystemControl(
      en ? 'Owner' : 'Proprietário',
      en
          ? 'Stop All triggered via global bar quick action.'
          : 'Stop All acionado via comando rápido da barra global.',
    );
  }

  ResumeControlResult clearEmergencyStop() {
    final en = _langNow == UiLanguage.enUS;
    return resumeSystemControl(
      en ? 'Owner' : 'Proprietário',
      en ? 'Resume requested by owner.' : 'Liberação solicitada pelo proprietário.',
    );
  }

  void markNotificationRead(String id) {
    final prev = state.domain;
    _commitDomain(
      prev.copyWith(
        notifications: prev.notifications
            .map((n) => n.id == id ? n.copyWith(read: true) : n)
            .toList(),
      ),
    );
  }

  void toggleNotificationRead(String id) {
    final prev = state.domain;
    _commitDomain(
      prev.copyWith(
        notifications: prev.notifications
            .map((n) => n.id == id ? n.copyWith(read: !n.read) : n)
            .toList(),
      ),
    );
  }

  void markAllNotificationsRead() {
    final prev = state.domain;
    _commitDomain(
      prev.copyWith(
        notifications:
            prev.notifications.map((n) => n.copyWith(read: true)).toList(),
      ),
    );
  }

  void simulateNotification() {
    final prev = state.domain;
    final en = prev.settings.uiLanguage == UiLanguage.enUS;
    final now = _nowUtc();
    final samples = en
        ? const [
            (
              type: NotificationType.commissionReceived,
              title: 'New settlement received (Amazon BR)',
              message:
                  'Payout of R\$ 1,840.00 confirmed in Apex Hardware Lab demo statement.',
              targetModule: NavModule.finance,
              targetId: null,
              brandId: 'brand-apex',
              actionRequired: null,
            ),
            (
              type: NotificationType.opportunity,
              title: 'Opportunity detected in DSP Audio',
              message:
                  '+21% surge in searches for compact Thunderbolt interfaces for creators.',
              targetModule: NavModule.products,
              targetId: null,
              brandId: 'brand-kinetix',
              actionRequired: null,
            ),
            (
              type: NotificationType.approvalPending,
              title: 'Script ready for SHA-256 hash approval',
              message:
                  '4K Monitor for Code & Design awaits individual authorization.',
              targetModule: NavModule.content,
              targetId: 'cnt-2',
              brandId: 'brand-apex',
              actionRequired: true,
            ),
          ]
        : const [
            (
              type: NotificationType.commissionReceived,
              title: 'Nova liquidação recebida (Amazon BR)',
              message:
                  'Repasse de R\$ 1.840,00 confirmado no extrato demonstrativo da Apex Hardware Lab.',
              targetModule: NavModule.finance,
              targetId: null,
              brandId: 'brand-apex',
              actionRequired: null,
            ),
            (
              type: NotificationType.opportunity,
              title: 'Oportunidade detectada em Áudio DSP',
              message:
                  'Subida de +21% em buscas por interfaces Thunderbolt compactas para criadores.',
              targetModule: NavModule.products,
              targetId: null,
              brandId: 'brand-kinetix',
              actionRequired: null,
            ),
            (
              type: NotificationType.approvalPending,
              title: 'Roteiro pronto para aprovação por hash SHA-256',
              message:
                  'Monitor 4K para Código e Design aguarda autorização individual no ambiente privado.',
              targetModule: NavModule.content,
              targetId: 'cnt-2',
              brandId: 'brand-apex',
              actionRequired: true,
            ),
          ];

    final pick = samples[prev.notifications.length % samples.length];
    final item = NotificationItem(
      id: 'not-sim-${now.millisecondsSinceEpoch}-${_nextSuffix()}',
      type: pick.type,
      title: pick.title,
      message: pick.message,
      timestamp: now.toIso8601String(),
      read: false,
      targetModule: pick.targetModule,
      targetId: pick.targetId,
      brandId: pick.brandId,
      actionRequired: pick.actionRequired,
    );

    _commitDomain(
      prev.copyWith(
        notifications: [item, ...prev.notifications],
        activities: _appendActivity(
          prev,
          brandId: item.brandId,
          category: ActivityCategory.sistema,
          action: en
              ? 'Simulated notification: ${item.title}'
              : 'Notificação simulada: ${item.title}',
          detail: item.message,
          severity: ActivitySeverity.info,
        ),
      ),
    );
  }

  Future<void> resetDemoData() async {
    await _storage.clearState();
    if (!mounted) return;
    state = VyronAppState(
      domain: buildInitialVyronState(),
      isHydrated: true,
    );
  }
}
