import React, { createContext, useContext, useEffect, useState } from 'react';
import { INITIAL_VYRON_STATE } from '../data/seedData';
import { OWNER_PROFILE, normalizeOwnerName } from '../data/ownerProfile';
import {
  ActivityCategory,
  ActivityEvent,
  AgentPolicyLimits,
  Brand,
  BrandStatus,
  Channel,
  ComplianceState,
  ContentFormat,
  ContentItem,
  ContentStatus,
  ContentVersion,
  CurrencyCode,
  FinanceEntry,
  JobRun,
  NavModule,
  NotificationItem,
  OwnerSettings,
  PeriodFilter,
  Product,
  ProductQualityGrade,
  ProductStatus,
  ThemeMode,
  VyronState,
} from '../types/vyron';
import {
  MANIFEST_FIELD_KEYS,
  applyStopAllToAutomations,
  canResumeSystemControl,
  computeContentManifestHash,
  reconcileOrphanedJobRuns,
  scoreProductV61,
  transitionContentStatus,
  transitionProductStatus,
} from '../utils/vyronRules';
import { translate } from '../i18n/translate';
import { UiLanguage } from '../i18n/types';

const STORAGE_KEY = 'vyron_prototype_state_v2';

type NewContentInput = Omit<
  ContentItem,
  | 'id'
  | 'versions'
  | 'currentManifestHash'
  | 'authorization'
  | 'description'
  | 'category'
  | 'visibility'
  | 'analysisMethod'
  | 'sensitiveTopic'
  | 'unclassifiedRiskFlag'
  | 'affiliateLinkUrl'
  | 'verifiedDestinationUrl'
  | 'linkVerifiedAt'
  | 'commercialConditionsVerifiedAt'
  | 'affiliateDisclosure'
  | 'aiDisclosureRequired'
  | 'aiDisclosureText'
  | 'relevanceTestPassed'
  | 'editorialChecklistPassed'
  | 'humanHoursLogged'
  | 'dossier'
> &
  Partial<
    Pick<
      ContentItem,
      | 'description'
      | 'category'
      | 'visibility'
      | 'analysisMethod'
      | 'sensitiveTopic'
      | 'unclassifiedRiskFlag'
      | 'affiliateLinkUrl'
      | 'verifiedDestinationUrl'
      | 'linkVerifiedAt'
      | 'commercialConditionsVerifiedAt'
      | 'offerEndsAt'
      | 'affiliateDisclosure'
      | 'aiDisclosureRequired'
      | 'aiDisclosureText'
      | 'relevanceTestPassed'
      | 'editorialChecklistPassed'
      | 'humanHoursLogged'
      | 'dossier'
    >
  >;

interface VyronContextValue {
  state: VyronState;
  activeModule: NavModule;
  selectedBrandId: string | null;
  selectedProductId: string | null;
  selectedContentId: string | null;
  selectedAutomationId: string | null;
  contentSubView: 'studio' | 'calendar';
  globalBrandFilter: string;
  globalPeriodFilter: PeriodFilter;
  excludeTestData: boolean;

  navigate: (
    module: NavModule,
    options?: {
      brandId?: string | null;
      productId?: string | null;
      contentId?: string | null;
      automationId?: string | null;
      contentSubView?: 'studio' | 'calendar';
    }
  ) => void;
  setGlobalBrandFilter: (brandId: string) => void;
  setGlobalPeriodFilter: (period: PeriodFilter) => void;
  setContentSubView: (sub: 'studio' | 'calendar') => void;
  setExcludeTestData: (exclude: boolean) => void;

  // Theme & Settings
  toggleTheme: () => void;
  setTheme: (theme: ThemeMode) => void;
  updateSettings: (patch: Partial<OwnerSettings>) => void;
  setBaseCurrency: (currency: CurrencyCode) => void;
  toggleSystemFlags: (patch: {
    publishingEnabled?: boolean;
    phaseBPublicAllowed?: boolean;
  }) => void;

  // Brands
  createBrand: (
    brand: Omit<Brand, 'id' | 'createdAt' | 'timezone' | 'publishWindow' | 'archetype' | 'validationStage' | 'pillars'> &
      Partial<Pick<Brand, 'timezone' | 'publishWindow' | 'archetype' | 'validationStage' | 'pillars'>>
  ) => Brand;
  updateBrand: (id: string, patch: Partial<Brand>) => void;
  changeBrandStatus: (id: string, status: BrandStatus, justification: string) => void;

  // Products
  createProduct: (
    product: Omit<
      Product,
      | 'id'
      | 'evidence'
      | 'decisions'
      | 'updatedAt'
      | 'externalId'
      | 'linkedBrandIds'
      | 'isTest'
      | 'dataConfidence'
      | 'qualityGrade'
      | 'complianceState'
      | 'complianceMarket'
    > &
      Partial<
        Pick<
          Product,
          | 'externalId'
          | 'linkedBrandIds'
          | 'isTest'
          | 'dataConfidence'
          | 'qualityGrade'
          | 'complianceState'
          | 'complianceMarket'
        >
      >
  ) => Product;
  changeProductStatus: (id: string, nextStatus: ProductStatus, justification: string) => void;
  updateProductGovernance: (
    id: string,
    patch: {
      qualityGrade?: ProductQualityGrade | null;
      complianceState?: ComplianceState;
      linkedBrandIds?: string[];
    }
  ) => void;
  generateContentFromProduct: (
    productId: string,
    channelId: string,
    format: ContentFormat
  ) => ContentItem;

  // Content Studio, Calendar & Hash Authorization
  createContent: (item: NewContentInput) => ContentItem;
  updateContent: (id: string, patch: Partial<ContentItem>, versionNote?: string) => void;
  changeContentStatus: (
    id: string,
    nextStatus: ContentStatus,
    note: string,
    feedbackCategory?: ContentVersion['feedbackCategory']
  ) => void;
  authorizeContentVersion: (
    id: string,
    payload: { actor: string; validHours: number; note?: string }
  ) => void;
  revokeContentAuthorization: (id: string, reason: string) => void;
  revalidateContentEvidence: (id: string) => void;
  rejectContentWithFeedback: (
    id: string,
    payload: { category: NonNullable<ContentVersion['feedbackCategory']>; note: string }
  ) => void;

  // Channels
  createChannel: (
    channel: Omit<Channel, 'id' | 'lastSyncAt' | 'advancedFeaturesUnlocked'> &
      Partial<Pick<Channel, 'advancedFeaturesUnlocked'>>
  ) => Channel;
  syncChannelDemo: (id: string) => void;

  // Finance
  addFinanceEntry: (entry: Omit<FinanceEntry, 'id'>) => void;

  // Automations, Job Runs & Stop All
  toggleAgentRun: (id: string) => void;
  updateAgentLimits: (id: string, limits: AgentPolicyLimits) => void;
  approveAgentPending: (id: string) => void;
  runPipelineDemo: (
    mode: 'dry-run' | 'commit',
    taskName?: JobRun['taskName']
  ) => { ok: boolean; message: string; job?: JobRun };
  reconcileJobsDemo: () => number;
  haltSystemControl: (actor: string, reason: string) => number;
  resumeSystemControl: (actor: string, reason: string) => { ok: boolean; reason?: string };
  triggerStopAll: () => number;
  clearEmergencyStop: () => { ok: boolean; reason?: string };

  // Notifications
  markNotificationRead: (id: string) => void;
  markAllNotificationsRead: () => void;
  simulateNotification: () => void;

  // Demo Reset
  resetDemoData: () => void;
}

const VyronContext = createContext<VyronContextValue | null>(null);

function loadInitialState(): VyronState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as VyronState;
      if (
        parsed &&
        Array.isArray(parsed.brands) &&
        Array.isArray(parsed.jobRuns) &&
        parsed.systemControl &&
        parsed.settings
      ) {
        return {
          ...parsed,
          settings: {
            ...parsed.settings,
            ownerName: normalizeOwnerName(parsed.settings.ownerName),
            ownerEmail: parsed.settings.ownerEmail || OWNER_PROFILE.email,
          },
        };
      }
    }
  } catch {
    // Fallback to clean seed
  }
  return INITIAL_VYRON_STATE;
}

export const VyronProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<VyronState>(loadInitialState);
  const [activeModule, setActiveModule] = useState<NavModule>('overview');
  const [selectedBrandId, setSelectedBrandId] = useState<string | null>(null);
  const [selectedProductId, setSelectedProductId] = useState<string | null>(null);
  const [selectedContentId, setSelectedContentId] = useState<string | null>(null);
  const [selectedAutomationId, setSelectedAutomationId] = useState<string | null>(null);
  const [contentSubView, setContentSubView] = useState<'studio' | 'calendar'>('studio');
  const [globalBrandFilter, setGlobalBrandFilter] = useState<string>('all');
  const [globalPeriodFilter, setGlobalPeriodFilter] = useState<PeriodFilter>('30d');
  const [excludeTestData, setExcludeTestData] = useState<boolean>(true);

  useEffect(() => {
    const root = document.documentElement;
    if (state.settings.theme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, [state.settings.theme]);

  useEffect(() => {
    const lang: UiLanguage = state.settings.uiLanguage === 'EN-US' ? 'EN-US' : 'PT-BR';
    document.documentElement.lang = lang === 'EN-US' ? 'en-US' : 'pt-BR';
    document.title = translate(lang, 'app.title');
  }, [state.settings.uiLanguage]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // Ignore quota errors
    }
  }, [state]);

  const langNow = (): UiLanguage =>
    state.settings.uiLanguage === 'EN-US' ? 'EN-US' : 'PT-BR';

  const appendActivity = (
    prev: VyronState,
    payload: {
      brandId?: string;
      category: ActivityCategory;
      action: string;
      detail: string;
      justification?: string;
      actor?: string;
      severity?: ActivityEvent['severity'];
    }
  ): ActivityEvent[] => {
    const ev: ActivityEvent = {
      id: `act-${Date.now()}-${Math.random().toString(36).slice(2, 5)}`,
      timestamp: new Date().toISOString(),
      brandId: payload.brandId,
      category: payload.category,
      action: payload.action,
      detail: payload.detail,
      justification: payload.justification,
      actor:
        payload.actor ?? (prev.settings.uiLanguage === 'EN-US' ? 'Owner' : 'Proprietário'),
      severity: payload.severity ?? 'info',
    };
    return [ev, ...prev.activities];
  };

  const navigate: VyronContextValue['navigate'] = (module, options) => {
    setActiveModule(module);
    if (options) {
      if ('brandId' in options) setSelectedBrandId(options.brandId ?? null);
      if ('productId' in options) setSelectedProductId(options.productId ?? null);
      if ('contentId' in options) setSelectedContentId(options.contentId ?? null);
      if ('automationId' in options) setSelectedAutomationId(options.automationId ?? null);
      if (options.contentSubView) setContentSubView(options.contentSubView);
    } else {
      if (module !== 'brands') setSelectedBrandId(null);
      if (module !== 'products') setSelectedProductId(null);
      if (module !== 'automations') setSelectedAutomationId(null);
    }
  };

  const toggleTheme = () => {
    setState((prev) => ({
      ...prev,
      settings: {
        ...prev.settings,
        theme: prev.settings.theme === 'dark' ? 'light' : 'dark',
      },
    }));
  };

  const setTheme = (theme: ThemeMode) => {
    setState((prev) => ({
      ...prev,
      settings: { ...prev.settings, theme },
    }));
  };

  const setBaseCurrency = (baseCurrency: CurrencyCode) => {
    setState((prev) => ({
      ...prev,
      settings: { ...prev.settings, baseCurrency },
    }));
  };

  const updateSettings = (patch: Partial<OwnerSettings>) => {
    setState((prev) => {
      const nextLang: UiLanguage =
        (patch.uiLanguage ?? prev.settings.uiLanguage) === 'EN-US' ? 'EN-US' : 'PT-BR';
      const en = nextLang === 'EN-US';
      return {
        ...prev,
        settings: { ...prev.settings, ...patch },
        activities: appendActivity(prev, {
          category: 'Sistema',
          action: en ? 'Preferences updated' : 'Preferências atualizadas',
          detail: en
            ? 'Operational settings or autonomy policies updated by owner.'
            : 'Configurações operacionais ou políticas de autonomia alteradas pelo proprietário.',
          actor: en ? 'Owner' : 'Proprietário',
          severity: 'info',
        }),
      };
    });
  };

  const toggleSystemFlags: VyronContextValue['toggleSystemFlags'] = (patch) => {
    setState((prev) => {
      const en = prev.settings.uiLanguage === 'EN-US';
      const nextControl = {
        ...prev.systemControl,
        ...patch,
        updatedAt: new Date().toISOString(),
      };
      return {
        ...prev,
        systemControl: nextControl,
        activities: appendActivity(prev, {
          category: 'Sistema',
          action: en ? 'Publishing policies updated' : 'Políticas de publicação atualizadas',
          detail: en
            ? `Automated publishing=${nextControl.publishingEnabled ? 'On' : 'Off'} · Public operation=${nextControl.phaseBPublicAllowed ? 'Allowed' : 'Private'}`
            : `Publicação automática=${nextControl.publishingEnabled ? 'Ativa' : 'Desligada'} · Operação pública=${nextControl.phaseBPublicAllowed ? 'Liberada' : 'Privada'}`,
          actor: en ? 'Owner' : 'Proprietário',
          severity: 'warning',
        }),
      };
    });
  };

  const createBrand: VyronContextValue['createBrand'] = (input) => {
    const en = langNow() === 'EN-US';
    const newBrand: Brand = {
      timezone:
        input.market.includes('França') ||
        input.market.includes('France') ||
        input.market.includes('Europa') ||
        input.market.includes('EU')
          ? 'Europe/Paris'
          : 'America/Sao_Paulo',
      publishWindow: '18:00-21:00',
      archetype: 'Híbrida',
      validationStage: '1. Exploração',
      pillars: en
        ? ['Technical Diagnosis', 'Practical Comparison', 'Transparent Recommendation']
        : ['Diagnóstico Técnico', 'Comparativo Prático', 'Recomendação Transparente'],
      ...input,
      id: `brand-${Date.now().toString(36)}`,
      createdAt: new Date().toISOString().slice(0, 10),
    };
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      return {
        ...prev,
        brands: [newBrand, ...prev.brands],
        activities: appendActivity(prev, {
          brandId: newBrand.id,
          category: 'Sistema',
          action: isEn ? `Brand created: ${newBrand.name}` : `Marca criada: ${newBrand.name}`,
          detail: `${newBrand.niche} (${newBrand.market} · ${newBrand.timezone})`,
          severity: 'success',
        }),
      };
    });
    return newBrand;
  };

  const updateBrand: VyronContextValue['updateBrand'] = (id, patch) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      return {
        ...prev,
        brands: prev.brands.map((b) => (b.id === id ? { ...b, ...patch } : b)),
        activities: appendActivity(prev, {
          brandId: id,
          category: 'Sistema',
          action: isEn ? 'Brand profile updated' : 'Dados da marca atualizados',
          detail: isEn
            ? 'Identity parameters, IANA timezone, validation stage, or editorial pillars updated.'
            : 'Parâmetros de identidade, fuso IANA, estágio ou pilares atualizados.',
          severity: 'info',
        }),
      };
    });
  };

  const changeBrandStatus: VyronContextValue['changeBrandStatus'] = (
    id,
    status,
    justification
  ) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.brands.find((b) => b.id === id);
      return {
        ...prev,
        brands: prev.brands.map((b) => (b.id === id ? { ...b, status } : b)),
        activities: appendActivity(prev, {
          brandId: id,
          category: 'Decisão',
          action: isEn
            ? `Brand ${target?.name ?? id}: ${status}`
            : `Marca ${target?.name ?? id}: ${status}`,
          detail: isEn
            ? `Operational status changed to ${status}.`
            : `Status operacional alterado para ${status}.`,
          justification,
          severity: status === 'Archived' ? 'warning' : 'info',
        }),
      };
    });
  };

  const createProduct: VyronContextValue['createProduct'] = (input) => {
    const lang = langNow();
    const en = lang === 'EN-US';
    const tempProd: Product = {
      externalId: input.externalId ?? `CAT-${Date.now().toString(36).toUpperCase()}`,
      linkedBrandIds: input.linkedBrandIds ?? [input.brandId],
      isTest: input.isTest ?? false,
      dataConfidence: input.dataConfidence ?? (input.epcValue === null ? 'Baixa' : 'Média'),
      qualityGrade: input.qualityGrade ?? 'B',
      complianceState: input.complianceState ?? 'PENDING',
      complianceMarket: input.complianceMarket ?? 'Brasil',
      ...input,
      id: `prod-${Date.now().toString(36)}`,
      evidence: [
        {
          id: `ev-${Date.now()}`,
          sourceName: en ? 'Manual Entry (Owner)' : 'Cadastro Manual (Proprietário)',
          url: 'https://vyron.internal',
          summary: en
            ? `Product registered in shared catalog (${input.platform}).`
            : `Produto registrado no catálogo compartilhado (${input.platform}).`,
          verifiedAt: new Date().toISOString().slice(0, 10),
        },
      ],
      decisions: [],
      updatedAt: new Date().toISOString(),
    };

    const computed = scoreProductV61(tempProd, lang);
    const finalProd: Product = {
      ...tempProd,
      opportunityScore:
        input.opportunityScore !== undefined ? input.opportunityScore : computed.score,
    };

    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const scoreText =
        finalProd.opportunityScore !== null
          ? `${finalProd.opportunityScore}/100`
          : isEn
          ? 'Not provided'
          : 'Sem dados';
      return {
        ...prev,
        products: [finalProd, ...prev.products],
        activities: appendActivity(prev, {
          brandId: finalProd.brandId,
          category: 'Produto',
          action: isEn
            ? `Product registered: ${finalProd.name}`
            : `Produto cadastrado: ${finalProd.name}`,
          detail: `${isEn ? 'Index' : 'Índice'} ${scoreText} · ${finalProd.currency} · ${finalProd.platform}`,
          severity: 'info',
        }),
      };
    });
    return finalProd;
  };

  const changeProductStatus: VyronContextValue['changeProductStatus'] = (
    id,
    nextStatus,
    justification
  ) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.products.find((p) => p.id === id);
      if (!target) return prev;
      const updatedProd = transitionProductStatus(
        target,
        nextStatus,
        justification,
        isEn ? 'Owner' : 'Proprietário'
      );
      return {
        ...prev,
        products: prev.products.map((p) => (p.id === id ? updatedProd : p)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Decisão',
          action: isEn
            ? `Product ${nextStatus}: ${target.name}`
            : `Produto ${nextStatus}: ${target.name}`,
          detail: isEn
            ? `Status changed from ${target.status} to ${nextStatus}.`
            : `Status alterado de ${target.status} para ${nextStatus}.`,
          justification,
          severity: nextStatus === 'Approved' ? 'success' : 'warning',
        }),
      };
    });
  };

  const updateProductGovernance: VyronContextValue['updateProductGovernance'] = (id, patch) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.products.find((p) => p.id === id);
      if (!target) return prev;
      return {
        ...prev,
        products: prev.products.map((p) =>
          p.id === id
            ? {
                ...p,
                ...patch,
                updatedAt: new Date().toISOString(),
              }
            : p
        ),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Produto',
          action: isEn
            ? `Governance updated: ${target.name}`
            : `Governança atualizada: ${target.name}`,
          detail: isEn
            ? `Quality=${patch.qualityGrade ?? target.qualityGrade ?? 'N/A'} · Compliance=${patch.complianceState ?? target.complianceState}`
            : `Qualidade=${patch.qualityGrade ?? target.qualityGrade ?? 'N/D'} · Conformidade=${patch.complianceState ?? target.complianceState}`,
          severity: 'info',
        }),
      };
    });
  };

  const generateContentFromProduct: VyronContextValue['generateContentFromProduct'] = (
    productId,
    channelId,
    format
  ) => {
    const en = langNow() === 'EN-US';
    const prod = state.products.find((p) => p.id === productId);
    const title = prod
      ? en
        ? `Technical Review: ${prod.name}`
        : `Análise Técnica: ${prod.name}`
      : en
      ? 'New Product Content Plan'
      : 'Nova Pauta de Produto';
    return createContent({
      brandId: prod?.brandId ?? state.brands[0].id,
      channelId,
      productId,
      title,
      description: prod
        ? en
          ? `Rigorous evaluation of ${prod.name} with market evidence and transparent disclosure.`
          : `Avaliação criteriosa de ${prod.name} com evidências de mercado e divulgação transparente.`
        : en
        ? 'Content plan generated from catalog.'
        : 'Pauta gerada a partir do catálogo.',
      format,
      category: 'Comercial contextual',
      visibility: 'private',
      analysisMethod: 'Análise documental',
      status: 'Brief',
      scheduledDate: '2026-11-26',
      brief: prod
        ? en
          ? `Explore the value proposition of ${prod.name} (${prod.platform}, commission ${prod.commissionRatePct ?? 'N/A'}%).`
          : `Explorar proposta de valor de ${prod.name} (${prod.platform}, comissão ${prod.commissionRatePct ?? 'N/D'}%).`
        : en
        ? 'Content plan created from catalog.'
        : 'Planejamento criado a partir do catálogo.',
      angleIdea: en
        ? 'Technical demonstration with verified evidence and objective comparison.'
        : 'Demonstrativo técnico com evidências reais e comparação objetiva.',
      script: en
        ? '1. Real user problem\n2. Specs and boundaries review\n3. Cost-benefit and transparent recommendation.'
        : '1. Problema real do usuário\n2. Análise de especificações e limites\n3. Custo-benefício e recomendação transparente.',
      affiliateLinkUrl: prod ? `https://vyron.link/${prod.externalId.toLowerCase()}` : '',
      verifiedDestinationUrl: prod?.evidence[0]?.url ?? '',
      linkVerifiedAt: prod?.evidence[0] ? new Date().toISOString() : '',
      commercialConditionsVerifiedAt: prod ? new Date().toISOString() : '',
      affiliateDisclosure: en
        ? 'Advertising / Affiliate links: we may earn a commission at no extra cost.'
        : 'Publicidade / Links de afiliado: podemos receber comissão sem custo extra.',
      references: prod?.evidence.map((e) => e.sourceName) ?? [],
    });
  };

  const createContent: VyronContextValue['createContent'] = (input) => {
    const en = langNow() === 'EN-US';
    const nowIso = new Date().toISOString();
    const baseWithoutHash: Omit<ContentItem, 'id' | 'versions' | 'currentManifestHash' | 'authorization'> = {
      description: input.description ?? input.brief,
      category: input.category ?? 'Comercial contextual',
      visibility: input.visibility ?? 'private',
      analysisMethod: input.analysisMethod ?? 'Análise documental',
      sensitiveTopic: input.sensitiveTopic ?? 'Nenhum',
      unclassifiedRiskFlag: input.unclassifiedRiskFlag ?? false,
      affiliateLinkUrl: input.affiliateLinkUrl ?? '',
      verifiedDestinationUrl: input.verifiedDestinationUrl ?? '',
      linkVerifiedAt: input.linkVerifiedAt ?? '',
      commercialConditionsVerifiedAt: input.commercialConditionsVerifiedAt ?? '',
      offerEndsAt: input.offerEndsAt,
      affiliateDisclosure:
        input.affiliateDisclosure ??
        (en
          ? 'Content with potential commercial relationship. Transparent disclosure applied.'
          : 'Conteúdo com possível vínculo comercial. Transparência conforme CDC/CONAR.'),
      aiDisclosureRequired: input.aiDisclosureRequired ?? false,
      aiDisclosureText: input.aiDisclosureText ?? '',
      relevanceTestPassed: input.relevanceTestPassed ?? false,
      editorialChecklistPassed: input.editorialChecklistPassed ?? false,
      humanHoursLogged: input.humanHoursLogged ?? 1.0,
      dossier: input.dossier ?? [],
      ...input,
    };

    const hash = computeContentManifestHash(baseWithoutHash);
    const newItem: ContentItem = {
      ...baseWithoutHash,
      id: `cnt-${Date.now().toString(36)}`,
      currentManifestHash: hash,
      authorization: null,
      versions: [
        {
          version: 'v1.0',
          manifestHash: hash,
          author: en ? 'Owner' : 'Proprietário',
          note: en
            ? 'Content plan created in Content Studio.'
            : 'Planejamento criado no Content Studio.',
          timestamp: nowIso,
          scriptSnapshot: baseWithoutHash.script,
        },
      ],
    };

    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      return {
        ...prev,
        contents: [newItem, ...prev.contents],
        activities: appendActivity(prev, {
          brandId: newItem.brandId,
          category: 'Conteúdo',
          action: isEn
            ? `Content created: ${newItem.title}`
            : `Conteúdo criado: ${newItem.title}`,
          detail: `${newItem.format} · ${newItem.visibility} · Hash ${hash.slice(0, 10)}...`,
          severity: 'info',
        }),
      };
    });
    return newItem;
  };

  const updateContent: VyronContextValue['updateContent'] = (id, patch, versionNote) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;

      const merged = { ...target, ...patch };
      const newHash = computeContentManifestHash(merged);
      const manifestChanged = MANIFEST_FIELD_KEYS.some(
        (key) => key in patch && patch[key] !== target[key]
      );

      const hadAuth = Boolean(target.authorization);
      const nextStatus: ContentStatus =
        manifestChanged && target.status === 'Approved' ? 'In Review' : merged.status;

      const updatedItem: ContentItem = {
        ...merged,
        status: nextStatus,
        currentManifestHash: newHash,
        // Zero inheritance: any manifest field edit immediately drops prior authorization
        authorization: manifestChanged ? null : merged.authorization,
      };

      if (versionNote || (manifestChanged && hadAuth)) {
        updatedItem.versions = [
          {
            version: `v${target.versions.length + 1}.0`,
            manifestHash: newHash,
            author: isEn ? 'Owner' : 'Proprietário',
            note:
              versionNote ??
              (isEn
                ? 'Manifest modified: prior authorization invalidated (zero inheritance).'
                : 'Manifesto alterado: autorização anterior invalidada (herança zero).'),
            timestamp: new Date().toISOString(),
            scriptSnapshot: updatedItem.script,
          },
          ...target.versions,
        ];
      }

      return {
        ...prev,
        contents: prev.contents.map((c) => (c.id === id ? updatedItem : c)),
        activities:
          manifestChanged && hadAuth
            ? appendActivity(prev, {
                brandId: target.brandId,
                category: 'Autorização Hash',
                action: isEn
                  ? `Hash invalidated by edit: ${target.title}`
                  : `Hash invalidado por edição: ${target.title}`,
                detail: isEn
                  ? `New hash ${newHash.slice(0, 12)}... will require a new individual authorization before delivery.`
                  : `Novo hash ${newHash.slice(0, 12)}... exigirá nova autorização individual antes de envio.`,
                severity: 'warning',
              })
            : prev.activities,
      };
    });
  };

  const changeContentStatus: VyronContextValue['changeContentStatus'] = (
    id,
    nextStatus,
    note,
    feedbackCategory
  ) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;
      const updated = transitionContentStatus(
        target,
        nextStatus,
        note,
        isEn ? 'Owner' : 'Proprietário',
        new Date().toISOString(),
        feedbackCategory
      );
      return {
        ...prev,
        contents: prev.contents.map((c) => (c.id === id ? updated : c)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Conteúdo',
          action: isEn
            ? `Content ${nextStatus}: ${target.title}`
            : `Conteúdo ${nextStatus}: ${target.title}`,
          detail: isEn
            ? `Moved from ${target.status} to ${nextStatus}.`
            : `Movido de ${target.status} para ${nextStatus}.`,
          justification: note,
          severity: nextStatus === 'Published' || nextStatus === 'Approved' ? 'success' : 'info',
        }),
      };
    });
  };

  const authorizeContentVersion: VyronContextValue['authorizeContentVersion'] = (
    id,
    { actor, validHours, note }
  ) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;
      const now = new Date();
      const hash = computeContentManifestHash(target);
      const computedExpiry = new Date(now.getTime() + validHours * 3_600_000);
      let expiresAt = computedExpiry.toISOString();
      if (target.offerEndsAt) {
        const offerMs = Date.parse(target.offerEndsAt);
        if (!Number.isNaN(offerMs) && offerMs < computedExpiry.getTime()) {
          expiresAt = new Date(offerMs).toISOString();
        }
      }

      const auth = {
        type: 'individual' as const,
        authorizedHash: hash,
        actor: actor.trim() || (isEn ? 'Owner' : 'Proprietário'),
        authorizedAt: now.toISOString(),
        expiresAt,
        rulesVersion: 'v1.0',
        evidenceVerifiedAt: target.linkVerifiedAt || now.toISOString(),
        offerEndsAt: target.offerEndsAt,
      };

      const updated: ContentItem = {
        ...target,
        status: target.status === 'Published' ? 'Published' : 'Approved',
        currentManifestHash: hash,
        authorization: auth,
        versions: [
          {
            version: `v${target.versions.length + 1}.0`,
            manifestHash: hash,
            author: auth.actor,
            note:
              note?.trim() ||
              (isEn
                ? `Individual authorization bound to hash ${hash.slice(0, 12)}...`
                : `Autorização individual vinculada ao hash ${hash.slice(0, 12)}...`),
            feedbackCategory: 'Aprovação',
            timestamp: now.toISOString(),
            scriptSnapshot: target.script,
          },
          ...target.versions,
        ],
      };

      return {
        ...prev,
        contents: prev.contents.map((c) => (c.id === id ? updated : c)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Autorização Hash',
          action: isEn
            ? `Authorization issued: ${target.title}`
            : `Autorização emitida: ${target.title}`,
          detail: isEn
            ? `Hash ${hash.slice(0, 12)}... · Visibility '${target.visibility}' · Expires ${expiresAt.slice(0, 16).replace('T', ' ')}`
            : `Hash ${hash.slice(0, 12)}... · Visibilidade '${target.visibility}' · Expira ${expiresAt.slice(0, 16).replace('T', ' ')}`,
          justification:
            note ||
            (isEn
              ? 'Individual human verification across all 6 pre-send checks.'
              : 'Verificação humana individual das 6 travas pré-envio.'),
          actor: auth.actor,
          severity: 'success',
        }),
      };
    });
  };

  const revokeContentAuthorization: VyronContextValue['revokeContentAuthorization'] = (
    id,
    reason
  ) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.contents.find((c) => c.id === id);
      if (!target || !target.authorization) return prev;
      return {
        ...prev,
        contents: prev.contents.map((c) =>
          c.id === id
            ? {
                ...c,
                status: c.status === 'Approved' ? 'In Review' : c.status,
                authorization: {
                  ...c.authorization!,
                  revoked: true,
                  revokedReason:
                    reason.trim() ||
                    (isEn
                      ? 'Manually revoked by owner.'
                      : 'Revogada manualmente pelo proprietário.'),
                },
              }
            : c
        ),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Autorização Hash',
          action: isEn
            ? `Authorization revoked: ${target.title}`
            : `Autorização revogada: ${target.title}`,
          detail: isEn
            ? 'External delivery blocked until a new individual approval is granted.'
            : 'Envio externo bloqueado até nova aprovação individual.',
          justification: reason,
          severity: 'warning',
        }),
      };
    });
  };

  const revalidateContentEvidence: VyronContextValue['revalidateContentEvidence'] = (id) => {
    const nowIso = new Date().toISOString();
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;
      return {
        ...prev,
        contents: prev.contents.map((c) =>
          c.id === id
            ? {
                ...c,
                verifiedDestinationUrl:
                  c.verifiedDestinationUrl || c.affiliateLinkUrl || 'https://destino-verificado.demo',
                linkVerifiedAt: nowIso,
                commercialConditionsVerifiedAt: nowIso,
              }
            : c
        ),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Conteúdo',
          action: isEn
            ? `Evidence & link revalidated: ${target.title}`
            : `Evidência e link revalidados: ${target.title}`,
          detail: isEn
            ? `Timestamp updated to ${nowIso.slice(0, 16).replace('T', ' ')}.`
            : `Timestamp atualizado para ${nowIso.slice(0, 16).replace('T', ' ')}.`,
          severity: 'info',
        }),
      };
    });
  };

  const rejectContentWithFeedback: VyronContextValue['rejectContentWithFeedback'] = (
    id,
    { category, note }
  ) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;
      const updated = transitionContentStatus(
        target,
        'Rejected',
        `[${category}] ${note}`,
        isEn ? 'Owner' : 'Proprietário',
        new Date().toISOString(),
        category
      );
      return {
        ...prev,
        contents: prev.contents.map((c) => (c.id === id ? updated : c)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Decisão',
          action: isEn
            ? `Content rejected (${category}): ${target.title}`
            : `Conteúdo rejeitado (${category}): ${target.title}`,
          detail: isEn
            ? 'Structured feedback recorded in adaptive history.'
            : 'Feedback estruturado gravado no histórico adaptativo.',
          justification: note,
          severity: 'warning',
        }),
      };
    });
  };

  const createChannel: VyronContextValue['createChannel'] = (input) => {
    const ch: Channel = {
      advancedFeaturesUnlocked: input.advancedFeaturesUnlocked ?? false,
      ...input,
      id: `ch-${Date.now().toString(36)}`,
      lastSyncAt: new Date().toISOString(),
    };
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      return {
        ...prev,
        channels: [ch, ...prev.channels],
        activities: appendActivity(prev, {
          brandId: ch.brandId,
          category: 'Sistema',
          action: isEn
            ? `Channel connected (Demo): ${ch.name}`
            : `Canal conectado (Demo): ${ch.name}`,
          detail: `${ch.platform} · ${ch.handle}`,
          severity: 'success',
        }),
      };
    });
    return ch;
  };

  const syncChannelDemo: VyronContextValue['syncChannelDemo'] = (id) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.channels.find((c) => c.id === id);
      return {
        ...prev,
        channels: prev.channels.map((c) =>
          c.id === id
            ? {
                ...c,
                integrationStatus: 'Configurado (Demo)',
                lastSyncAt: new Date().toISOString(),
              }
            : c
        ),
        activities: appendActivity(prev, {
          brandId: target?.brandId,
          category: 'Sistema',
          action: isEn
            ? `Demo sync completed: ${target?.name ?? id}`
            : `Sincronização demonstrativa: ${target?.name ?? id}`,
          detail: isEn
            ? 'Read-only metrics updated in prototype environment.'
            : 'Métricas de leitura atualizadas no ambiente de protótipo.',
          severity: 'info',
        }),
      };
    });
  };

  const addFinanceEntry: VyronContextValue['addFinanceEntry'] = (input) => {
    const entry: FinanceEntry = {
      ...input,
      id: `fin-${Date.now().toString(36)}`,
    };
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      return {
        ...prev,
        financeEntries: [entry, ...prev.financeEntries],
        activities: appendActivity(prev, {
          brandId: entry.brandId,
          category: 'Finanças',
          action: isEn
            ? `Financial entry (${entry.stage}): ${entry.description}`
            : `Registro financeiro (${entry.stage}): ${entry.description}`,
          detail: `${entry.type} · ${entry.amount.toFixed(2)} ${entry.currency}`,
          severity: entry.stage === 'Received' ? 'success' : 'info',
        }),
      };
    });
  };

  const toggleAgentRun: VyronContextValue['toggleAgentRun'] = (id) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      if (prev.systemControl.state === 'HALTED' || prev.settings.emergencyStopActive) return prev;
      const target = prev.automations.find((a) => a.id === id);
      if (!target) return prev;
      const nextState = target.state === 'Running' ? 'Paused' : 'Running';
      return {
        ...prev,
        automations: prev.automations.map((a) =>
          a.id === id
            ? {
                ...a,
                state: nextState,
                lastRunAt: new Date().toISOString(),
                history: [
                  {
                    id: `exec-${Date.now()}`,
                    timestamp: new Date().toISOString(),
                    status: nextState === 'Running' ? 'Success' : 'Paused',
                    durationSec: nextState === 'Running' ? 6 : 0,
                    summary:
                      nextState === 'Running'
                        ? isEn
                          ? 'Demo execution started respecting policy limits.'
                          : 'Execução demonstrativa iniciada respeitando políticas de limite.'
                        : isEn
                        ? 'Agent manually paused by owner.'
                        : 'Agente pausado manualmente pelo proprietário.',
                    recordsAffected: nextState === 'Running' ? 3 : 0,
                  },
                  ...a.history,
                ],
              }
            : a
        ),
        activities: appendActivity(prev, {
          category: 'Automação',
          action: isEn
            ? `Agent ${nextState === 'Running' ? 'started' : 'paused'}: ${target.name}`
            : `Agente ${nextState === 'Running' ? 'iniciado' : 'pausado'}: ${target.name}`,
          detail: isEn
            ? `State changed from ${target.state} to ${nextState}.`
            : `Estado alterado de ${target.state} para ${nextState}.`,
          severity: 'info',
        }),
      };
    });
  };

  const updateAgentLimits: VyronContextValue['updateAgentLimits'] = (id, limits) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      return {
        ...prev,
        automations: prev.automations.map((a) => (a.id === id ? { ...a, limits } : a)),
        activities: appendActivity(prev, {
          category: 'Automação',
          action: isEn
            ? 'Agent policy and limits updated'
            : 'Política e limites de agente atualizados',
          detail: isEn
            ? `Human approval: ${limits.requireHumanApproval ? 'Required' : 'Waived'} · Daily limit: ${limits.maxActionsPerDay} actions.`
            : `Aprovação humana: ${limits.requireHumanApproval ? 'Obrigatória' : 'Dispensada'} · Limite diário: ${limits.maxActionsPerDay} ações.`,
          severity: 'info',
        }),
      };
    });
  };

  const approveAgentPending: VyronContextValue['approveAgentPending'] = (id) => {
    setState((prev) => {
      const isEn = prev.settings.uiLanguage === 'EN-US';
      const target = prev.automations.find((a) => a.id === id);
      if (!target) return prev;
      return {
        ...prev,
        automations: prev.automations.map((a) =>
          a.id === id
            ? {
                ...a,
                state: 'Idle',
                pendingApprovalCount: 0,
                pendingApprovalSummary: undefined,
                history: [
                  {
                    id: `exec-app-${Date.now()}`,
                    timestamp: new Date().toISOString(),
                    status: 'Success',
                    durationSec: 2,
                    summary: isEn
                      ? 'Pending queue authorized by owner.'
                      : 'Fila pendente autorizada pelo proprietário.',
                    recordsAffected: target.pendingApprovalCount,
                  },
                  ...a.history,
                ],
              }
            : a
        ),
        activities: appendActivity(prev, {
          category: 'Decisão',
          action: isEn
            ? `Execution approved: ${target.name}`
            : `Aprovação de execução: ${target.name}`,
          detail: isEn
            ? `${target.pendingApprovalCount} pending action(s) authorized.`
            : `${target.pendingApprovalCount} ação(ões) pendente(s) autorizada(s).`,
          justification: isEn
            ? 'Manually validated within operational policy bounds.'
            : 'Validado manualmente nos limites da política operacional.',
          severity: 'success',
        }),
      };
    });
  };

  const runPipelineDemo: VyronContextValue['runPipelineDemo'] = (
    mode,
    taskName = 'pipeline.run'
  ) => {
    const lang = langNow();
    const en = lang === 'EN-US';
    if (mode === 'commit' && state.systemControl.state === 'HALTED') {
      const msg = en
        ? 'Write execution blocked: system controls are currently halted.'
        : 'Execução de gravação bloqueada: os controles do sistema estão interrompidos.';
      setState((prev) => ({
        ...prev,
        activities: appendActivity(prev, {
          category: 'Job Run',
          action: en
            ? `Blocked write execution in ${taskName}`
            : `Bloqueio de segurança em ${taskName}`,
          detail: msg,
          severity: 'error',
        }),
      }));
      return { ok: false, message: msg };
    }

    const nowIso = new Date().toISOString();
    const nextId = (state.jobRuns[0]?.id ?? 100) + 1;
    const realProducts = state.products.filter((p) => !p.isTest);
    const job: JobRun = {
      id: nextId,
      taskName,
      mode,
      status: 'succeeded',
      startedAt: nowIso,
      finishedAt: nowIso,
      recordsProcessed: realProducts.length,
      summary:
        mode === 'dry-run'
          ? en
            ? `Simulation completed without persistent writes (${realProducts.length} products evaluated per currency).`
            : `Simulação concluída sem gravação persistente (${realProducts.length} produtos avaliados por moeda).`
          : en
          ? `Commit executed updating the evaluation index across ${realProducts.length} real products.`
          : `Gravação executada recalculando o índice de avaliação em ${realProducts.length} produtos reais.`,
    };

    setState((prev) => ({
      ...prev,
      products:
        mode === 'commit' && (taskName === 'products.score' || taskName === 'pipeline.run')
          ? prev.products.map((p) => {
              const res = scoreProductV61(p, lang);
              return { ...p, opportunityScore: res.score };
            })
          : prev.products,
      jobRuns: [job, ...prev.jobRuns],
      activities: appendActivity(prev, {
        category: 'Job Run',
        action: en
          ? `Batch task: ${taskName} (${mode === 'dry-run' ? 'simulation' : 'commit'})`
          : `Tarefa em lote: ${taskName} (${mode === 'dry-run' ? 'simulação' : 'gravação'})`,
        detail: job.summary,
        actor: 'batch-executor',
        severity: 'success',
      }),
    }));

    return { ok: true, message: job.summary, job };
  };

  const reconcileJobsDemo = () => {
    const lang = langNow();
    const en = lang === 'EN-US';
    const nowIso = new Date().toISOString();
    const res = reconcileOrphanedJobRuns(state.jobRuns, nowIso, 30, lang);
    setState((prev) => {
      const r = reconcileOrphanedJobRuns(prev.jobRuns, nowIso, 30, lang);
      const nextId = (r.updated[0]?.id ?? 100) + 1;
      const reconcileRun: JobRun = {
        id: nextId,
        taskName: 'jobs.reconcile',
        mode: 'commit',
        status: 'succeeded',
        startedAt: nowIso,
        finishedAt: nowIso,
        recordsProcessed: r.reconciledIds.length,
        summary:
          r.reconciledIds.length > 0
            ? en
              ? `Reconciled ${r.reconciledIds.length} pending run(s): #${r.reconciledIds.join(', #')}.`
              : `Reconciliadas ${r.reconciledIds.length} execução(ões) pendente(s): #${r.reconciledIds.join(', #')}.`
            : en
            ? 'No pending runs found.'
            : 'Nenhuma execução pendente encontrada.',
      };
      return {
        ...prev,
        jobRuns: [reconcileRun, ...r.updated],
        activities: appendActivity(prev, {
          category: 'Job Run',
          action: en ? 'Runs reconciliation' : 'Reconciliação de execuções',
          detail: reconcileRun.summary,
          actor: en ? 'Owner' : 'Proprietário',
          severity: r.reconciledIds.length > 0 ? 'warning' : 'info',
        }),
      };
    });
    return res.reconciledIds.length;
  };

  const haltSystemControl: VyronContextValue['haltSystemControl'] = (actor, reason) => {
    const lang = langNow();
    const en = lang === 'EN-US';
    let stoppedCount = 0;
    const nowIso = new Date().toISOString();
    setState((prev) => {
      const res = applyStopAllToAutomations(prev.automations, nowIso, lang);
      stoppedCount = res.stoppedCount;
      const alertNotif: NotificationItem = {
        id: `not-stop-${Date.now()}`,
        type: 'operational',
        title: en ? 'Stop All triggered (System Halted)' : 'Stop All acionado (Sistema Interrompido)',
        message: en
          ? `${res.stoppedCount} agent(s) paused. Automated writes and external deliveries blocked.`
          : `${res.stoppedCount} agente(s) pausado(s). Execuções de gravação e envios externos bloqueados.`,
        timestamp: nowIso,
        read: false,
        targetModule: 'automations',
        actionRequired: false,
      };
      return {
        ...prev,
        automations: res.updated,
        notifications: [alertNotif, ...prev.notifications],
        systemControl: {
          ...prev.systemControl,
          state: 'HALTED',
          actor: actor.trim() || (en ? 'Owner' : 'Proprietário'),
          reason:
            reason.trim() ||
            (en ? 'Immediate halt triggered.' : 'Interrupção imediata acionada.'),
          updatedAt: nowIso,
        },
        settings: {
          ...prev.settings,
          emergencyStopActive: true,
          globalAutonomyEnabled: false,
        },
        activities: appendActivity(prev, {
          category: 'Stop All',
          action: en
            ? 'STOP ALL — System controls halted'
            : 'STOP ALL — Controles do sistema interrompidos',
          detail: en
            ? `${res.stoppedCount} agent(s) halted. Safety lock active in the audit log.`
            : `${res.stoppedCount} agente(s) interrompido(s). Bloqueio de segurança ativo no registro de auditoria.`,
          justification:
            reason.trim() || (en ? 'Owner emergency command.' : 'Comando de emergência do proprietário.'),
          actor: actor.trim() || (en ? 'Owner' : 'Proprietário'),
          severity: 'error',
        }),
      };
    });
    return stoppedCount;
  };

  const resumeSystemControl: VyronContextValue['resumeSystemControl'] = (actor, reason) => {
    const lang = langNow();
    const en = lang === 'EN-US';
    const gate = canResumeSystemControl(state.jobRuns, lang);
    if (!gate.allowed) {
      setState((prev) => ({
        ...prev,
        activities: appendActivity(prev, {
          category: 'Stop All',
          action: en ? 'Resume attempt blocked' : 'Tentativa de retomada bloqueada',
          detail:
            gate.reason ??
            (en ? 'Pending runs still exist.' : 'Existem execuções pendentes.'),
          actor: actor.trim() || (en ? 'Owner' : 'Proprietário'),
          severity: 'warning',
        }),
      }));
      return { ok: false, reason: gate.reason };
    }

    const nowIso = new Date().toISOString();
    setState((prev) => ({
      ...prev,
      systemControl: {
        ...prev.systemControl,
        state: 'ACTIVE',
        actor: actor.trim() || (en ? 'Owner' : 'Proprietário'),
        reason:
          reason.trim() ||
          (en ? 'System resumed after verification.' : 'Sistema retomado após verificação.'),
        updatedAt: nowIso,
      },
      settings: {
        ...prev.settings,
        emergencyStopActive: false,
        globalAutonomyEnabled: true,
      },
      activities: appendActivity(prev, {
        category: 'Stop All',
        action: en
          ? 'SYSTEM RESUMED — Controls active'
          : 'SISTEMA RETOMADO — Controles ativos',
        detail: en
          ? 'Controlled autonomy and write executions restored after clean reconciliation.'
          : 'Autonomia controlada e execuções liberadas após reconciliação limpa.',
        justification:
          reason.trim() ||
          (en ? 'Explicit resume by owner.' : 'Retomada explícita pelo proprietário.'),
        actor: actor.trim() || (en ? 'Owner' : 'Proprietário'),
        severity: 'success',
      }),
    }));
    return { ok: true };
  };

  const triggerStopAll = () =>
    haltSystemControl(
      langNow() === 'EN-US' ? 'Owner' : 'Proprietário',
      langNow() === 'EN-US'
        ? 'Stop All triggered via global bar quick action.'
        : 'Stop All acionado via comando rápido da barra global.'
    );

  const clearEmergencyStop = () =>
    resumeSystemControl(
      langNow() === 'EN-US' ? 'Owner' : 'Proprietário',
      langNow() === 'EN-US'
        ? 'Resume requested by owner.'
        : 'Liberação solicitada pelo proprietário.'
    );

  const markNotificationRead = (id: string) => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => (n.id === id ? { ...n, read: true } : n)),
    }));
  };

  const markAllNotificationsRead = () => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => ({ ...n, read: true })),
    }));
  };

  const simulateNotification = () => {
    const en = langNow() === 'EN-US';
    const samples: Array<Omit<NotificationItem, 'id' | 'timestamp' | 'read'>> = en
      ? [
          {
            type: 'commission_received',
            title: 'New settlement received (Amazon BR)',
            message: 'Payout of R$ 1,840.00 confirmed in Apex Hardware Lab demo statement.',
            targetModule: 'finance',
            brandId: 'brand-apex',
          },
          {
            type: 'opportunity',
            title: 'Opportunity detected in DSP Audio',
            message: '+21% surge in searches for compact Thunderbolt interfaces for creators.',
            targetModule: 'products',
            brandId: 'brand-kinetix',
          },
          {
            type: 'approval_pending',
            title: 'Script ready for SHA-256 hash approval',
            message: '4K Monitor for Code & Design awaits individual authorization.',
            targetModule: 'content',
            targetId: 'cnt-2',
            brandId: 'brand-apex',
            actionRequired: true,
          },
        ]
      : [
          {
            type: 'commission_received',
            title: 'Nova liquidação recebida (Amazon BR)',
            message: 'Repasse de R$ 1.840,00 confirmado no extrato demonstrativo da Apex Hardware Lab.',
            targetModule: 'finance',
            brandId: 'brand-apex',
          },
          {
            type: 'opportunity',
            title: 'Oportunidade detectada em Áudio DSP',
            message: 'Subida de +21% em buscas por interfaces Thunderbolt compactas para criadores.',
            targetModule: 'products',
            brandId: 'brand-kinetix',
          },
          {
            type: 'approval_pending',
            title: 'Roteiro pronto para aprovação por hash SHA-256',
            message: 'Monitor 4K para Código e Design aguarda autorização individual no ambiente privado.',
            targetModule: 'content',
            targetId: 'cnt-2',
            brandId: 'brand-apex',
            actionRequired: true,
          },
        ];
    const pick = samples[state.notifications.length % samples.length];
    const item: NotificationItem = {
      ...pick,
      id: `not-sim-${Date.now()}`,
      timestamp: new Date().toISOString(),
      read: false,
    };
    setState((prev) => ({
      ...prev,
      notifications: [item, ...prev.notifications],
      activities: appendActivity(prev, {
        brandId: item.brandId,
        category: 'Sistema',
        action: en ? `Simulated notification: ${item.title}` : `Notificação simulada: ${item.title}`,
        detail: item.message,
        severity: 'info',
      }),
    }));
  };

  const resetDemoData = () => {
    localStorage.removeItem(STORAGE_KEY);
    setState(INITIAL_VYRON_STATE);
    setGlobalBrandFilter('all');
    setGlobalPeriodFilter('30d');
    setExcludeTestData(true);
    navigate('overview');
  };

  return (
    <VyronContext.Provider
      value={{
        state,
        activeModule,
        selectedBrandId,
        selectedProductId,
        selectedContentId,
        selectedAutomationId,
        contentSubView,
        globalBrandFilter,
        globalPeriodFilter,
        excludeTestData,
        navigate,
        setGlobalBrandFilter,
        setGlobalPeriodFilter,
        setContentSubView,
        setExcludeTestData,
        toggleTheme,
        setTheme,
        updateSettings,
        setBaseCurrency,
        toggleSystemFlags,
        createBrand,
        updateBrand,
        changeBrandStatus,
        createProduct,
        changeProductStatus,
        updateProductGovernance,
        generateContentFromProduct,
        createContent,
        updateContent,
        changeContentStatus,
        authorizeContentVersion,
        revokeContentAuthorization,
        revalidateContentEvidence,
        rejectContentWithFeedback,
        createChannel,
        syncChannelDemo,
        addFinanceEntry,
        toggleAgentRun,
        updateAgentLimits,
        approveAgentPending,
        runPipelineDemo,
        reconcileJobsDemo,
        haltSystemControl,
        resumeSystemControl,
        triggerStopAll,
        clearEmergencyStop,
        markNotificationRead,
        markAllNotificationsRead,
        simulateNotification,
        resetDemoData,
      }}
    >
      {children}
    </VyronContext.Provider>
  );
};

export function useVyron(): VyronContextValue {
  const ctx = useContext(VyronContext);
  if (!ctx) {
    throw new Error('useVyron deve ser utilizado dentro de VyronProvider.');
  }
  return ctx;
}
