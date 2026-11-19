import React, { createContext, useContext, useEffect, useState } from 'react';
import { INITIAL_VYRON_STATE } from '../data/seedData';
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
        return parsed;
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
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // Ignore quota errors
    }
  }, [state]);

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
      actor: payload.actor ?? 'Proprietário',
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
    setState((prev) => ({
      ...prev,
      settings: { ...prev.settings, ...patch },
      activities: appendActivity(prev, {
        category: 'Sistema',
        action: 'Preferências atualizadas',
        detail: 'Configurações operacionais ou políticas de autonomia alteradas pelo proprietário.',
        severity: 'info',
      }),
    }));
  };

  const toggleSystemFlags: VyronContextValue['toggleSystemFlags'] = (patch) => {
    setState((prev) => {
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
          action: 'Flags de publicação atualizadas',
          detail: `PUBLISHING_ENABLED=${nextControl.publishingEnabled} · Fase B Pública=${nextControl.phaseBPublicAllowed}`,
          severity: 'warning',
        }),
      };
    });
  };

  const createBrand: VyronContextValue['createBrand'] = (input) => {
    const newBrand: Brand = {
      timezone: input.market.includes('França') || input.market.includes('Europa') ? 'Europe/Paris' : 'America/Sao_Paulo',
      publishWindow: '18:00-21:00',
      archetype: 'Híbrida',
      validationStage: '1. Exploração',
      pillars: ['Diagnóstico Técnico', 'Comparativo Prático', 'Recomendação Transparente'],
      ...input,
      id: `brand-${Date.now().toString(36)}`,
      createdAt: new Date().toISOString().slice(0, 10),
    };
    setState((prev) => ({
      ...prev,
      brands: [newBrand, ...prev.brands],
      activities: appendActivity(prev, {
        brandId: newBrand.id,
        category: 'Sistema',
        action: `Marca criada: ${newBrand.name}`,
        detail: `${newBrand.niche} (${newBrand.market} · ${newBrand.timezone})`,
        severity: 'success',
      }),
    }));
    return newBrand;
  };

  const updateBrand: VyronContextValue['updateBrand'] = (id, patch) => {
    setState((prev) => ({
      ...prev,
      brands: prev.brands.map((b) => (b.id === id ? { ...b, ...patch } : b)),
      activities: appendActivity(prev, {
        brandId: id,
        category: 'Sistema',
        action: 'Dados da marca atualizados',
        detail: 'Parâmetros de identidade, fuso IANA, estágio ou pilares atualizados.',
        severity: 'info',
      }),
    }));
  };

  const changeBrandStatus: VyronContextValue['changeBrandStatus'] = (
    id,
    status,
    justification
  ) => {
    setState((prev) => {
      const target = prev.brands.find((b) => b.id === id);
      return {
        ...prev,
        brands: prev.brands.map((b) => (b.id === id ? { ...b, status } : b)),
        activities: appendActivity(prev, {
          brandId: id,
          category: 'Decisão',
          action: `Marca ${target?.name ?? id}: ${status}`,
          detail: `Status operacional alterado para ${status}.`,
          justification,
          severity: status === 'Archived' ? 'warning' : 'info',
        }),
      };
    });
  };

  const createProduct: VyronContextValue['createProduct'] = (input) => {
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
          sourceName: 'Cadastro Manual (Proprietário)',
          url: 'https://vyron.internal',
          summary: `Produto registrado no catálogo compartilhado (${input.platform}).`,
          verifiedAt: new Date().toISOString().slice(0, 10),
        },
      ],
      decisions: [],
      updatedAt: new Date().toISOString(),
    };

    const computed = scoreProductV61(tempProd);
    const finalProd: Product = {
      ...tempProd,
      opportunityScore:
        input.opportunityScore !== undefined ? input.opportunityScore : computed.score,
    };

    setState((prev) => ({
      ...prev,
      products: [finalProd, ...prev.products],
      activities: appendActivity(prev, {
        brandId: finalProd.brandId,
        category: 'Produto',
        action: `Produto cadastrado: ${finalProd.name}`,
        detail: `Score ${finalProd.opportunityScore ?? 'Desconhecido (null)'} · ${finalProd.currency} · ${finalProd.platform}`,
        severity: 'info',
      }),
    }));
    return finalProd;
  };

  const changeProductStatus: VyronContextValue['changeProductStatus'] = (
    id,
    nextStatus,
    justification
  ) => {
    setState((prev) => {
      const target = prev.products.find((p) => p.id === id);
      if (!target) return prev;
      const updatedProd = transitionProductStatus(target, nextStatus, justification);
      return {
        ...prev,
        products: prev.products.map((p) => (p.id === id ? updatedProd : p)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Decisão',
          action: `Produto ${nextStatus}: ${target.name}`,
          detail: `Status alterado de ${target.status} para ${nextStatus}.`,
          justification,
          severity: nextStatus === 'Approved' ? 'success' : 'warning',
        }),
      };
    });
  };

  const updateProductGovernance: VyronContextValue['updateProductGovernance'] = (id, patch) => {
    setState((prev) => {
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
          action: `Governança atualizada: ${target.name}`,
          detail: `Qualidade=${patch.qualityGrade ?? target.qualityGrade ?? 'N/D'} · Compliance=${patch.complianceState ?? target.complianceState}`,
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
    const prod = state.products.find((p) => p.id === productId);
    const title = prod ? `Análise Técnica: ${prod.name}` : 'Nova Pauta de Produto';
    return createContent({
      brandId: prod?.brandId ?? state.brands[0].id,
      channelId,
      productId,
      title,
      description: prod
        ? `Avaliação criteriosa de ${prod.name} com evidências de mercado e divulgação transparente.`
        : 'Pauta gerada a partir do catálogo.',
      format,
      category: 'Comercial contextual',
      visibility: 'private',
      analysisMethod: 'Análise documental',
      status: 'Brief',
      scheduledDate: '2026-11-26',
      brief: prod
        ? `Explorar proposta de valor de ${prod.name} (${prod.platform}, comissão ${prod.commissionRatePct ?? 'N/D'}%).`
        : 'Briefing criado a partir do catálogo.',
      angleIdea: 'Demonstrativo técnico com evidências reais e comparação objetiva.',
      script: '1. Problema real do usuário\n2. Análise de especificações e limites\n3. Custo-benefício e recomendação transparente.',
      affiliateLinkUrl: prod ? `https://vyron.link/${prod.externalId.toLowerCase()}` : '',
      verifiedDestinationUrl: prod?.evidence[0]?.url ?? '',
      linkVerifiedAt: prod?.evidence[0] ? new Date().toISOString() : '',
      commercialConditionsVerifiedAt: prod ? new Date().toISOString() : '',
      affiliateDisclosure: 'Publicidade / Links de afiliado: podemos receber comissão sem custo extra.',
      references: prod?.evidence.map((e) => e.sourceName) ?? [],
    });
  };

  const createContent: VyronContextValue['createContent'] = (input) => {
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
        'Conteúdo com possível vínculo comercial. Transparência conforme CDC/CONAR.',
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
          author: 'Proprietário',
          note: 'Briefing criado no Content Studio.',
          timestamp: nowIso,
          scriptSnapshot: baseWithoutHash.script,
        },
      ],
    };

    setState((prev) => ({
      ...prev,
      contents: [newItem, ...prev.contents],
      activities: appendActivity(prev, {
        brandId: newItem.brandId,
        category: 'Conteúdo',
        action: `Conteúdo criado: ${newItem.title}`,
        detail: `${newItem.format} · ${newItem.visibility} · Hash ${hash.slice(0, 10)}...`,
        severity: 'info',
      }),
    }));
    return newItem;
  };

  const updateContent: VyronContextValue['updateContent'] = (id, patch, versionNote) => {
    setState((prev) => {
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
            author: 'Proprietário',
            note:
              versionNote ??
              'Manifesto alterado: autorização anterior invalidada (herança zero).',
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
                action: `Hash invalidado por edição: ${target.title}`,
                detail: `Novo hash ${newHash.slice(0, 12)}... exigirá nova autorização individual antes de envio.`,
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
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;
      const updated = transitionContentStatus(
        target,
        nextStatus,
        note,
        'Proprietário',
        new Date().toISOString(),
        feedbackCategory
      );
      return {
        ...prev,
        contents: prev.contents.map((c) => (c.id === id ? updated : c)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Conteúdo',
          action: `Conteúdo ${nextStatus}: ${target.title}`,
          detail: `Movido de ${target.status} para ${nextStatus}.`,
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
        actor: actor.trim() || 'Proprietário',
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
            note: note?.trim() || `Autorização individual vinculada ao hash ${hash.slice(0, 12)}...`,
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
          action: `Autorização emitida: ${target.title}`,
          detail: `Hash ${hash.slice(0, 12)}... · Visibilidade '${target.visibility}' · Expira ${expiresAt.slice(0, 16).replace('T', ' ')}`,
          justification: note || 'Verificação humana individual das 6 travas pré-envio.',
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
                  revokedReason: reason.trim() || 'Revogada manualmente pelo proprietário.',
                },
              }
            : c
        ),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Autorização Hash',
          action: `Autorização revogada: ${target.title}`,
          detail: 'Envio externo bloqueado até nova aprovação individual.',
          justification: reason,
          severity: 'warning',
        }),
      };
    });
  };

  const revalidateContentEvidence: VyronContextValue['revalidateContentEvidence'] = (id) => {
    const nowIso = new Date().toISOString();
    setState((prev) => {
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
          action: `Evidência e link revalidados: ${target.title}`,
          detail: `Timestamp atualizado para ${nowIso.slice(0, 16).replace('T', ' ')}.`,
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
      const target = prev.contents.find((c) => c.id === id);
      if (!target) return prev;
      const updated = transitionContentStatus(
        target,
        'Rejected',
        `[${category}] ${note}`,
        'Proprietário',
        new Date().toISOString(),
        category
      );
      return {
        ...prev,
        contents: prev.contents.map((c) => (c.id === id ? updated : c)),
        activities: appendActivity(prev, {
          brandId: target.brandId,
          category: 'Decisão',
          action: `Conteúdo rejeitado (${category}): ${target.title}`,
          detail: 'Feedback estruturado gravado no histórico adaptativo.',
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
    setState((prev) => ({
      ...prev,
      channels: [ch, ...prev.channels],
      activities: appendActivity(prev, {
        brandId: ch.brandId,
        category: 'Sistema',
        action: `Canal conectado (Demo): ${ch.name}`,
        detail: `${ch.platform} · ${ch.handle}`,
        severity: 'success',
      }),
    }));
    return ch;
  };

  const syncChannelDemo: VyronContextValue['syncChannelDemo'] = (id) => {
    setState((prev) => {
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
          action: `Sincronização demonstrativa: ${target?.name ?? id}`,
          detail: 'Métricas de leitura atualizadas no ambiente de protótipo.',
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
    setState((prev) => ({
      ...prev,
      financeEntries: [entry, ...prev.financeEntries],
      activities: appendActivity(prev, {
        brandId: entry.brandId,
        category: 'Finanças',
        action: `Registro financeiro (${entry.stage}): ${entry.description}`,
        detail: `${entry.type} · ${entry.amount.toFixed(2)} ${entry.currency}`,
        severity: entry.stage === 'Received' ? 'success' : 'info',
      }),
    }));
  };

  const toggleAgentRun: VyronContextValue['toggleAgentRun'] = (id) => {
    setState((prev) => {
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
                        ? 'Execução demonstrativa iniciada respeitando políticas de limite.'
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
          action: `Agente ${nextState === 'Running' ? 'iniciado' : 'pausado'}: ${target.name}`,
          detail: `Estado alterado de ${target.state} para ${nextState}.`,
          severity: 'info',
        }),
      };
    });
  };

  const updateAgentLimits: VyronContextValue['updateAgentLimits'] = (id, limits) => {
    setState((prev) => ({
      ...prev,
      automations: prev.automations.map((a) => (a.id === id ? { ...a, limits } : a)),
      activities: appendActivity(prev, {
        category: 'Automação',
        action: 'Política e limites de agente atualizados',
        detail: `Aprovação humana: ${limits.requireHumanApproval ? 'Obrigatória' : 'Dispensada'} · Limite diário: ${limits.maxActionsPerDay} ações.`,
        severity: 'info',
      }),
    }));
  };

  const approveAgentPending: VyronContextValue['approveAgentPending'] = (id) => {
    setState((prev) => {
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
                    summary: 'Fila pendente autorizada pelo proprietário.',
                    recordsAffected: target.pendingApprovalCount,
                  },
                  ...a.history,
                ],
              }
            : a
        ),
        activities: appendActivity(prev, {
          category: 'Decisão',
          action: `Aprovação de execução: ${target.name}`,
          detail: `${target.pendingApprovalCount} ação(ões) pendente(s) autorizada(s).`,
          justification: 'Validado manualmente nos limites da política operacional.',
          severity: 'success',
        }),
      };
    });
  };

  const runPipelineDemo: VyronContextValue['runPipelineDemo'] = (
    mode,
    taskName = 'pipeline.run'
  ) => {
    if (mode === 'commit' && state.systemControl.state === 'HALTED') {
      const msg =
        'Execução --commit bloqueada (fail-closed): system_controls está em HALTED.';
      setState((prev) => ({
        ...prev,
        activities: appendActivity(prev, {
          category: 'Job Run',
          action: `Bloqueio fail-closed em ${taskName} (--commit)`,
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
          ? `Dry-run concluído sem gravação persistente (${realProducts.length} produtos avaliados por moeda).`
          : `Commit executado com score-6.1 (v0-hipotese) em ${realProducts.length} produtos reais.`,
    };

    setState((prev) => ({
      ...prev,
      products:
        mode === 'commit' && (taskName === 'products.score' || taskName === 'pipeline.run')
          ? prev.products.map((p) => {
              const res = scoreProductV61(p);
              return { ...p, opportunityScore: res.score };
            })
          : prev.products,
      jobRuns: [job, ...prev.jobRuns],
      activities: appendActivity(prev, {
        category: 'Job Run',
        action: `autopilot ${taskName} (${mode})`,
        detail: job.summary,
        actor: 'batch-executor',
        severity: 'success',
      }),
    }));

    return { ok: true, message: job.summary, job };
  };

  const reconcileJobsDemo = () => {
    const nowIso = new Date().toISOString();
    const res = reconcileOrphanedJobRuns(state.jobRuns, nowIso, 30);
    setState((prev) => {
      const r = reconcileOrphanedJobRuns(prev.jobRuns, nowIso, 30);
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
            ? `Reconciliados ${r.reconciledIds.length} job(s) órfão(s): #${r.reconciledIds.join(', #')}.`
            : 'Nenhum job órfão pendente encontrado.',
      };
      return {
        ...prev,
        jobRuns: [reconcileRun, ...r.updated],
        activities: appendActivity(prev, {
          category: 'Job Run',
          action: 'autopilot jobs reconcile',
          detail: reconcileRun.summary,
          actor: 'Proprietário',
          severity: r.reconciledIds.length > 0 ? 'warning' : 'info',
        }),
      };
    });
    return res.reconciledIds.length;
  };

  const haltSystemControl: VyronContextValue['haltSystemControl'] = (actor, reason) => {
    let stoppedCount = 0;
    const nowIso = new Date().toISOString();
    setState((prev) => {
      const res = applyStopAllToAutomations(prev.automations, nowIso);
      stoppedCount = res.stoppedCount;
      const alertNotif: NotificationItem = {
        id: `not-stop-${Date.now()}`,
        type: 'operational',
        title: 'Stop All acionado (system_controls = HALTED)',
        message: `${res.stoppedCount} agente(s) pausado(s). Execuções --commit e publicações bloqueadas fail-closed.`,
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
          actor: actor.trim() || 'Proprietário',
          reason: reason.trim() || 'Interrupção imediata acionada.',
          updatedAt: nowIso,
        },
        settings: {
          ...prev.settings,
          emergencyStopActive: true,
          globalAutonomyEnabled: false,
        },
        activities: appendActivity(prev, {
          category: 'Stop All',
          action: 'STOP ALL — system_controls = HALTED',
          detail: `${res.stoppedCount} agente(s) interrompido(s). Bloqueio fail-closed ativo no audit_log.`,
          justification: reason.trim() || 'Comando de emergência do proprietário.',
          actor: actor.trim() || 'Proprietário',
          severity: 'error',
        }),
      };
    });
    return stoppedCount;
  };

  const resumeSystemControl: VyronContextValue['resumeSystemControl'] = (actor, reason) => {
    const gate = canResumeSystemControl(state.jobRuns);
    if (!gate.allowed) {
      setState((prev) => ({
        ...prev,
        activities: appendActivity(prev, {
          category: 'Stop All',
          action: 'Tentativa de resume bloqueada',
          detail: gate.reason ?? 'Existem job_runs pendentes.',
          actor: actor.trim() || 'Proprietário',
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
        actor: actor.trim() || 'Proprietário',
        reason: reason.trim() || 'Sistema retomado após verificação.',
        updatedAt: nowIso,
      },
      settings: {
        ...prev.settings,
        emergencyStopActive: false,
        globalAutonomyEnabled: true,
      },
      activities: appendActivity(prev, {
        category: 'Stop All',
        action: 'SYSTEM RESUMED — system_controls = ACTIVE',
        detail: 'Autonomia controlada e execuções --commit liberadas após reconciliação limpa.',
        justification: reason.trim() || 'Retomada explícita pelo proprietário.',
        actor: actor.trim() || 'Proprietário',
        severity: 'success',
      }),
    }));
    return { ok: true };
  };

  const triggerStopAll = () =>
    haltSystemControl('Proprietário', 'Stop All acionado via comando rápido da barra global.');

  const clearEmergencyStop = () =>
    resumeSystemControl('Proprietário', 'Liberação solicitada pelo proprietário.');

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
    const samples: Array<Omit<NotificationItem, 'id' | 'timestamp' | 'read'>> = [
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
        message: 'Monitor 4K para Código e Design aguarda autorização individual na Fase A.',
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
        action: `Notificação simulada: ${item.title}`,
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
