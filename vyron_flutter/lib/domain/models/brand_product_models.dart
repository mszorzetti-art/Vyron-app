import 'package:flutter/foundation.dart';

import 'vyron_enums.dart';

abstract final class OwnerProfile {
  static const String name = 'Marcus Zorzetti';
  static const String email = 'mszorzetti@gmail.com';
  static const String roleLabel = 'Proprietário & Operador Único';

  static const Set<String> _legacyAliases = {
    'mateus zorzetti',
    'proprietário',
    '',
  };

  static String normalizeOwnerName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || _legacyAliases.contains(trimmed.toLowerCase())) {
      return name;
    }
    return trimmed;
  }
}

@immutable
class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    required this.niche,
    required this.segment,
    required this.market,
    required this.language,
    required this.timezone,
    required this.publishWindow,
    required this.archetype,
    required this.validationStage,
    required this.pillars,
    required this.status,
    required this.accentColor,
    required this.secondaryColor,
    required this.typographyNote,
    required this.tagline,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String niche;
  final String segment;
  final String market;
  final String language;
  final String timezone;
  final String publishWindow;
  final BrandArchetype archetype;
  final ValidationStage validationStage;
  final List<String> pillars;
  final BrandStatus status;
  final String accentColor;
  final String secondaryColor;
  final String typographyNote;
  final String tagline;
  final String description;
  final String createdAt;

  Brand copyWith({
    String? id,
    String? name,
    String? slug,
    String? niche,
    String? segment,
    String? market,
    String? language,
    String? timezone,
    String? publishWindow,
    BrandArchetype? archetype,
    ValidationStage? validationStage,
    List<String>? pillars,
    BrandStatus? status,
    String? accentColor,
    String? secondaryColor,
    String? typographyNote,
    String? tagline,
    String? description,
    String? createdAt,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      niche: niche ?? this.niche,
      segment: segment ?? this.segment,
      market: market ?? this.market,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      publishWindow: publishWindow ?? this.publishWindow,
      archetype: archetype ?? this.archetype,
      validationStage: validationStage ?? this.validationStage,
      pillars: pillars ?? this.pillars,
      status: status ?? this.status,
      accentColor: accentColor ?? this.accentColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      typographyNote: typographyNote ?? this.typographyNote,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'niche': niche,
    'segment': segment,
    'market': market,
    'language': language,
    'timezone': timezone,
    'publishWindow': publishWindow,
    'archetype': archetype.wire,
    'validationStage': validationStage.wire,
    'pillars': pillars,
    'status': status.wire,
    'accentColor': accentColor,
    'secondaryColor': secondaryColor,
    'typographyNote': typographyNote,
    'tagline': tagline,
    'description': description,
    'createdAt': createdAt,
  };

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
    niche: json['niche'] as String,
    segment: json['segment'] as String,
    market: json['market'] as String,
    language: json['language'] as String,
    timezone: json['timezone'] as String,
    publishWindow: json['publishWindow'] as String,
    archetype: BrandArchetype.fromWire(json['archetype'] as String?),
    validationStage: ValidationStage.fromWire(
      json['validationStage'] as String?,
    ),
    pillars: List<String>.from(json['pillars'] as List<dynamic>),
    status: BrandStatus.fromWire(json['status'] as String?),
    accentColor: json['accentColor'] as String,
    secondaryColor: json['secondaryColor'] as String,
    typographyNote: json['typographyNote'] as String,
    tagline: json['tagline'] as String,
    description: json['description'] as String,
    createdAt: json['createdAt'] as String,
  );
}

@immutable
class ProductEvidence {
  const ProductEvidence({
    required this.id,
    required this.sourceName,
    required this.url,
    required this.summary,
    required this.verifiedAt,
  });

  final String id;
  final String sourceName;
  final String url;
  final String summary;
  final String verifiedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceName': sourceName,
    'url': url,
    'summary': summary,
    'verifiedAt': verifiedAt,
  };

  factory ProductEvidence.fromJson(Map<String, dynamic> json) =>
      ProductEvidence(
        id: json['id'] as String,
        sourceName: json['sourceName'] as String,
        url: json['url'] as String,
        summary: json['summary'] as String,
        verifiedAt: json['verifiedAt'] as String,
      );
}

@immutable
class ProductDecisionLog {
  const ProductDecisionLog({
    required this.id,
    required this.previousStatus,
    required this.newStatus,
    required this.justification,
    required this.actor,
    required this.timestamp,
  });

  final String id;
  final ProductStatus previousStatus;
  final ProductStatus newStatus;
  final String justification;
  final String actor;
  final String timestamp;

  Map<String, dynamic> toJson() => {
    'id': id,
    'previousStatus': previousStatus.wire,
    'newStatus': newStatus.wire,
    'justification': justification,
    'actor': actor,
    'timestamp': timestamp,
  };

  factory ProductDecisionLog.fromJson(Map<String, dynamic> json) =>
      ProductDecisionLog(
        id: json['id'] as String,
        previousStatus: ProductStatus.fromWire(
          json['previousStatus'] as String?,
        ),
        newStatus: ProductStatus.fromWire(json['newStatus'] as String?),
        justification: json['justification'] as String,
        actor: json['actor'] as String,
        timestamp: json['timestamp'] as String,
      );
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.externalId,
    required this.brandId,
    required this.linkedBrandIds,
    required this.isTest,
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
    required this.opportunityScore,
    required this.dataConfidence,
    required this.qualityGrade,
    required this.complianceState,
    required this.complianceMarket,
    required this.demandTrendPct,
    required this.competitionLevel,
    required this.status,
    required this.evidence,
    required this.decisions,
    required this.updatedAt,
  });

  final String id;
  final String externalId;
  final String brandId;
  final List<String> linkedBrandIds;
  final bool isTest;
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
  final DataConfidence dataConfidence;
  final ProductQualityGrade? qualityGrade;
  final ComplianceState complianceState;
  final String complianceMarket;
  final double? demandTrendPct;
  final CompetitionLevel competitionLevel;
  final ProductStatus status;
  final List<ProductEvidence> evidence;
  final List<ProductDecisionLog> decisions;
  final String updatedAt;

  Product copyWith({
    String? id,
    String? externalId,
    String? brandId,
    List<String>? linkedBrandIds,
    bool? isTest,
    String? name,
    String? category,
    String? platform,
    RemunerationModel? remunerationModel,
    double? price,
    bool clearPrice = false,
    CurrencyCode? currency,
    double? commissionRatePct,
    bool clearCommissionRatePct = false,
    double? cpaValue,
    bool clearCpaValue = false,
    double? epcValue,
    bool clearEpcValue = false,
    int? cookieWindowDays,
    bool clearCookieWindowDays = false,
    int? opportunityScore,
    bool clearOpportunityScore = false,
    DataConfidence? dataConfidence,
    ProductQualityGrade? qualityGrade,
    bool clearQualityGrade = false,
    ComplianceState? complianceState,
    String? complianceMarket,
    double? demandTrendPct,
    bool clearDemandTrendPct = false,
    CompetitionLevel? competitionLevel,
    ProductStatus? status,
    List<ProductEvidence>? evidence,
    List<ProductDecisionLog>? decisions,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      brandId: brandId ?? this.brandId,
      linkedBrandIds: linkedBrandIds ?? this.linkedBrandIds,
      isTest: isTest ?? this.isTest,
      name: name ?? this.name,
      category: category ?? this.category,
      platform: platform ?? this.platform,
      remunerationModel: remunerationModel ?? this.remunerationModel,
      price: clearPrice ? null : (price ?? this.price),
      currency: currency ?? this.currency,
      commissionRatePct: clearCommissionRatePct
          ? null
          : (commissionRatePct ?? this.commissionRatePct),
      cpaValue: clearCpaValue ? null : (cpaValue ?? this.cpaValue),
      epcValue: clearEpcValue ? null : (epcValue ?? this.epcValue),
      cookieWindowDays: clearCookieWindowDays
          ? null
          : (cookieWindowDays ?? this.cookieWindowDays),
      opportunityScore: clearOpportunityScore
          ? null
          : (opportunityScore ?? this.opportunityScore),
      dataConfidence: dataConfidence ?? this.dataConfidence,
      qualityGrade: clearQualityGrade
          ? null
          : (qualityGrade ?? this.qualityGrade),
      complianceState: complianceState ?? this.complianceState,
      complianceMarket: complianceMarket ?? this.complianceMarket,
      demandTrendPct: clearDemandTrendPct
          ? null
          : (demandTrendPct ?? this.demandTrendPct),
      competitionLevel: competitionLevel ?? this.competitionLevel,
      status: status ?? this.status,
      evidence: evidence ?? this.evidence,
      decisions: decisions ?? this.decisions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'brandId': brandId,
    'linkedBrandIds': linkedBrandIds,
    'isTest': isTest,
    'name': name,
    'category': category,
    'platform': platform,
    'remunerationModel': remunerationModel.wire,
    'price': price,
    'currency': currency.wire,
    'commissionRatePct': commissionRatePct,
    'cpaValue': cpaValue,
    'epcValue': epcValue,
    'cookieWindowDays': cookieWindowDays,
    'opportunityScore': opportunityScore,
    'dataConfidence': dataConfidence.wire,
    'qualityGrade': qualityGrade?.wire,
    'complianceState': complianceState.wire,
    'complianceMarket': complianceMarket,
    'demandTrendPct': demandTrendPct,
    'competitionLevel': competitionLevel.wire,
    'status': status.wire,
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'decisions': decisions.map((e) => e.toJson()).toList(),
    'updatedAt': updatedAt,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    externalId: json['externalId'] as String,
    brandId: json['brandId'] as String,
    linkedBrandIds: List<String>.from(json['linkedBrandIds'] as List<dynamic>),
    isTest: json['isTest'] as bool? ?? false,
    name: json['name'] as String,
    category: json['category'] as String,
    platform: json['platform'] as String,
    remunerationModel: RemunerationModel.fromWire(
      json['remunerationModel'] as String?,
    ),
    price: (json['price'] as num?)?.toDouble(),
    currency: CurrencyCode.fromWire(json['currency'] as String?),
    commissionRatePct: (json['commissionRatePct'] as num?)?.toDouble(),
    cpaValue: (json['cpaValue'] as num?)?.toDouble(),
    epcValue: (json['epcValue'] as num?)?.toDouble(),
    cookieWindowDays: (json['cookieWindowDays'] as num?)?.toInt(),
    opportunityScore: (json['opportunityScore'] as num?)?.toInt(),
    dataConfidence: DataConfidence.fromWire(json['dataConfidence'] as String?),
    qualityGrade: ProductQualityGrade.fromWire(json['qualityGrade'] as String?),
    complianceState: ComplianceState.fromWire(
      json['complianceState'] as String?,
    ),
    complianceMarket: json['complianceMarket'] as String,
    demandTrendPct: (json['demandTrendPct'] as num?)?.toDouble(),
    competitionLevel: CompetitionLevel.fromWire(
      json['competitionLevel'] as String?,
    ),
    status: ProductStatus.fromWire(json['status'] as String?),
    evidence: (json['evidence'] as List<dynamic>)
        .map((e) => ProductEvidence.fromJson(e as Map<String, dynamic>))
        .toList(),
    decisions: (json['decisions'] as List<dynamic>)
        .map((e) => ProductDecisionLog.fromJson(e as Map<String, dynamic>))
        .toList(),
    updatedAt: json['updatedAt'] as String,
  );
}
