import 'package:flutter/foundation.dart';

import 'vyron_enums.dart';

@immutable
class DossierSource {
  const DossierSource({
    required this.id,
    required this.claim,
    required this.sourceTitle,
    required this.level,
    required this.consultedAt,
  });

  final String id;
  final String claim;
  final String sourceTitle;
  final int level; // 1 | 2 | 3 | 4
  final String consultedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'claim': claim,
    'sourceTitle': sourceTitle,
    'level': level,
    'consultedAt': consultedAt,
  };

  factory DossierSource.fromJson(Map<String, dynamic> json) => DossierSource(
    id: json['id'] as String,
    claim: json['claim'] as String,
    sourceTitle: json['sourceTitle'] as String,
    level: (json['level'] as num).toInt(),
    consultedAt: json['consultedAt'] as String,
  );
}

@immutable
class ContentVersion {
  const ContentVersion({
    required this.version,
    required this.manifestHash,
    required this.author,
    required this.note,
    this.feedbackCategory,
    required this.timestamp,
    required this.scriptSnapshot,
  });

  final String version;
  final String manifestHash;
  final String author;
  final String note;
  final FeedbackCategory? feedbackCategory;
  final String timestamp;
  final String scriptSnapshot;

  Map<String, dynamic> toJson() => {
    'version': version,
    'manifestHash': manifestHash,
    'author': author,
    'note': note,
    if (feedbackCategory != null) 'feedbackCategory': feedbackCategory!.wire,
    'timestamp': timestamp,
    'scriptSnapshot': scriptSnapshot,
  };

  factory ContentVersion.fromJson(Map<String, dynamic> json) => ContentVersion(
    version: json['version'] as String,
    manifestHash: json['manifestHash'] as String,
    author: json['author'] as String,
    note: json['note'] as String,
    feedbackCategory: FeedbackCategory.fromWire(
      json['feedbackCategory'] as String?,
    ),
    timestamp: json['timestamp'] as String,
    scriptSnapshot: json['scriptSnapshot'] as String,
  );
}

@immutable
class ContentAuthorization {
  const ContentAuthorization({
    required this.type,
    required this.authorizedHash,
    required this.actor,
    required this.authorizedAt,
    required this.expiresAt,
    required this.rulesVersion,
    required this.evidenceVerifiedAt,
    this.offerEndsAt,
    this.revoked,
    this.revokedReason,
  });

  final AuthorizationType type;
  final String authorizedHash;
  final String actor;
  final String authorizedAt;
  final String expiresAt;
  final String rulesVersion;
  final String evidenceVerifiedAt;
  final String? offerEndsAt;
  final bool? revoked;
  final String? revokedReason;

  ContentAuthorization copyWith({
    AuthorizationType? type,
    String? authorizedHash,
    String? actor,
    String? authorizedAt,
    String? expiresAt,
    String? rulesVersion,
    String? evidenceVerifiedAt,
    String? offerEndsAt,
    bool? revoked,
    String? revokedReason,
  }) {
    return ContentAuthorization(
      type: type ?? this.type,
      authorizedHash: authorizedHash ?? this.authorizedHash,
      actor: actor ?? this.actor,
      authorizedAt: authorizedAt ?? this.authorizedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rulesVersion: rulesVersion ?? this.rulesVersion,
      evidenceVerifiedAt: evidenceVerifiedAt ?? this.evidenceVerifiedAt,
      offerEndsAt: offerEndsAt ?? this.offerEndsAt,
      revoked: revoked ?? this.revoked,
      revokedReason: revokedReason ?? this.revokedReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.wire,
    'authorizedHash': authorizedHash,
    'actor': actor,
    'authorizedAt': authorizedAt,
    'expiresAt': expiresAt,
    'rulesVersion': rulesVersion,
    'evidenceVerifiedAt': evidenceVerifiedAt,
    if (offerEndsAt != null) 'offerEndsAt': offerEndsAt,
    if (revoked != null) 'revoked': revoked,
    if (revokedReason != null) 'revokedReason': revokedReason,
  };

  factory ContentAuthorization.fromJson(Map<String, dynamic> json) =>
      ContentAuthorization(
        type: AuthorizationType.fromWire(json['type'] as String?),
        authorizedHash: json['authorizedHash'] as String,
        actor: json['actor'] as String,
        authorizedAt: json['authorizedAt'] as String,
        expiresAt: json['expiresAt'] as String,
        rulesVersion: json['rulesVersion'] as String,
        evidenceVerifiedAt: json['evidenceVerifiedAt'] as String,
        offerEndsAt: json['offerEndsAt'] as String?,
        revoked: json['revoked'] as bool?,
        revokedReason: json['revokedReason'] as String?,
      );
}

@immutable
class ContentMetrics {
  const ContentMetrics({
    required this.views,
    required this.retention30sPct,
    required this.avgViewPct,
    required this.clicks,
    required this.conversions,
    required this.revenueGenerated,
    required this.currency,
    required this.trackingSrc,
    required this.attributionStatus,
  });

  final int views;
  final double retention30sPct;
  final double avgViewPct;
  final int clicks;
  final int conversions;
  final double revenueGenerated;
  final CurrencyCode currency;
  final String trackingSrc;
  final AttributionStatus attributionStatus;

  Map<String, dynamic> toJson() => {
    'views': views,
    'retention30sPct': retention30sPct,
    'avgViewPct': avgViewPct,
    'clicks': clicks,
    'conversions': conversions,
    'revenueGenerated': revenueGenerated,
    'currency': currency.wire,
    'trackingSrc': trackingSrc,
    'attributionStatus': attributionStatus.wire,
  };

  factory ContentMetrics.fromJson(Map<String, dynamic> json) => ContentMetrics(
    views: (json['views'] as num).toInt(),
    retention30sPct: (json['retention30sPct'] as num).toDouble(),
    avgViewPct: (json['avgViewPct'] as num).toDouble(),
    clicks: (json['clicks'] as num).toInt(),
    conversions: (json['conversions'] as num).toInt(),
    revenueGenerated: (json['revenueGenerated'] as num).toDouble(),
    currency: CurrencyCode.fromWire(json['currency'] as String?),
    trackingSrc: json['trackingSrc'] as String,
    attributionStatus: AttributionStatus.fromWire(
      json['attributionStatus'] as String?,
    ),
  );
}

@immutable
class ContentItem {
  const ContentItem({
    required this.id,
    required this.brandId,
    required this.channelId,
    this.productId,
    required this.title,
    required this.description,
    required this.format,
    required this.category,
    required this.visibility,
    required this.analysisMethod,
    required this.sensitiveTopic,
    required this.unclassifiedRiskFlag,
    required this.status,
    required this.scheduledDate,
    this.publishedAt,
    required this.brief,
    required this.angleIdea,
    required this.script,
    required this.affiliateLinkUrl,
    required this.verifiedDestinationUrl,
    required this.linkVerifiedAt,
    required this.commercialConditionsVerifiedAt,
    this.offerEndsAt,
    required this.affiliateDisclosure,
    required this.aiDisclosureRequired,
    required this.aiDisclosureText,
    required this.relevanceTestPassed,
    required this.editorialChecklistPassed,
    required this.humanHoursLogged,
    required this.dossier,
    required this.references,
    required this.currentManifestHash,
    required this.authorization,
    required this.versions,
    this.metrics,
  });

  final String id;
  final String brandId;
  final String channelId;
  final String? productId;
  final String title;
  final String description;
  final ContentFormat format;
  final ContentCategory category;
  final ContentVisibility visibility;
  final AnalysisMethod analysisMethod;
  final SensitiveTopic sensitiveTopic;
  final bool unclassifiedRiskFlag;
  final ContentStatus status;
  final String scheduledDate;
  final String? publishedAt;
  final String brief;
  final String angleIdea;
  final String script;
  final String affiliateLinkUrl;
  final String verifiedDestinationUrl;
  final String linkVerifiedAt;
  final String commercialConditionsVerifiedAt;
  final String? offerEndsAt;
  final String affiliateDisclosure;
  final bool aiDisclosureRequired;
  final String aiDisclosureText;
  final bool relevanceTestPassed;
  final bool editorialChecklistPassed;
  final double humanHoursLogged;
  final List<DossierSource> dossier;
  final List<String> references;
  final String currentManifestHash;
  final ContentAuthorization? authorization;
  final List<ContentVersion> versions;
  final ContentMetrics? metrics;

  ContentItem copyWith({
    String? id,
    String? brandId,
    String? channelId,
    String? productId,
    bool clearProductId = false,
    String? title,
    String? description,
    ContentFormat? format,
    ContentCategory? category,
    ContentVisibility? visibility,
    AnalysisMethod? analysisMethod,
    SensitiveTopic? sensitiveTopic,
    bool? unclassifiedRiskFlag,
    ContentStatus? status,
    String? scheduledDate,
    String? publishedAt,
    String? brief,
    String? angleIdea,
    String? script,
    String? affiliateLinkUrl,
    String? verifiedDestinationUrl,
    String? linkVerifiedAt,
    String? commercialConditionsVerifiedAt,
    String? offerEndsAt,
    String? affiliateDisclosure,
    bool? aiDisclosureRequired,
    String? aiDisclosureText,
    bool? relevanceTestPassed,
    bool? editorialChecklistPassed,
    double? humanHoursLogged,
    List<DossierSource>? dossier,
    List<String>? references,
    String? currentManifestHash,
    ContentAuthorization? authorization,
    bool clearAuthorization = false,
    List<ContentVersion>? versions,
    ContentMetrics? metrics,
  }) {
    return ContentItem(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      channelId: channelId ?? this.channelId,
      productId: clearProductId ? null : (productId ?? this.productId),
      title: title ?? this.title,
      description: description ?? this.description,
      format: format ?? this.format,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      analysisMethod: analysisMethod ?? this.analysisMethod,
      sensitiveTopic: sensitiveTopic ?? this.sensitiveTopic,
      unclassifiedRiskFlag: unclassifiedRiskFlag ?? this.unclassifiedRiskFlag,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      publishedAt: publishedAt ?? this.publishedAt,
      brief: brief ?? this.brief,
      angleIdea: angleIdea ?? this.angleIdea,
      script: script ?? this.script,
      affiliateLinkUrl: affiliateLinkUrl ?? this.affiliateLinkUrl,
      verifiedDestinationUrl:
          verifiedDestinationUrl ?? this.verifiedDestinationUrl,
      linkVerifiedAt: linkVerifiedAt ?? this.linkVerifiedAt,
      commercialConditionsVerifiedAt:
          commercialConditionsVerifiedAt ?? this.commercialConditionsVerifiedAt,
      offerEndsAt: offerEndsAt ?? this.offerEndsAt,
      affiliateDisclosure: affiliateDisclosure ?? this.affiliateDisclosure,
      aiDisclosureRequired: aiDisclosureRequired ?? this.aiDisclosureRequired,
      aiDisclosureText: aiDisclosureText ?? this.aiDisclosureText,
      relevanceTestPassed: relevanceTestPassed ?? this.relevanceTestPassed,
      editorialChecklistPassed:
          editorialChecklistPassed ?? this.editorialChecklistPassed,
      humanHoursLogged: humanHoursLogged ?? this.humanHoursLogged,
      dossier: dossier ?? this.dossier,
      references: references ?? this.references,
      currentManifestHash: currentManifestHash ?? this.currentManifestHash,
      authorization: clearAuthorization
          ? null
          : (authorization ?? this.authorization),
      versions: versions ?? this.versions,
      metrics: metrics ?? this.metrics,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandId': brandId,
    'channelId': channelId,
    if (productId != null) 'productId': productId,
    'title': title,
    'description': description,
    'format': format.wire,
    'category': category.wire,
    'visibility': visibility.wire,
    'analysisMethod': analysisMethod.wire,
    'sensitiveTopic': sensitiveTopic.wire,
    'unclassifiedRiskFlag': unclassifiedRiskFlag,
    'status': status.wire,
    'scheduledDate': scheduledDate,
    if (publishedAt != null) 'publishedAt': publishedAt,
    'brief': brief,
    'angleIdea': angleIdea,
    'script': script,
    'affiliateLinkUrl': affiliateLinkUrl,
    'verifiedDestinationUrl': verifiedDestinationUrl,
    'linkVerifiedAt': linkVerifiedAt,
    'commercialConditionsVerifiedAt': commercialConditionsVerifiedAt,
    if (offerEndsAt != null) 'offerEndsAt': offerEndsAt,
    'affiliateDisclosure': affiliateDisclosure,
    'aiDisclosureRequired': aiDisclosureRequired,
    'aiDisclosureText': aiDisclosureText,
    'relevanceTestPassed': relevanceTestPassed,
    'editorialChecklistPassed': editorialChecklistPassed,
    'humanHoursLogged': humanHoursLogged,
    'dossier': dossier.map((e) => e.toJson()).toList(),
    'references': references,
    'currentManifestHash': currentManifestHash,
    'authorization': authorization?.toJson(),
    'versions': versions.map((e) => e.toJson()).toList(),
    if (metrics != null) 'metrics': metrics!.toJson(),
  };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'] as String,
    brandId: json['brandId'] as String,
    channelId: json['channelId'] as String,
    productId: json['productId'] as String?,
    title: json['title'] as String,
    description: json['description'] as String,
    format: ContentFormat.fromWire(json['format'] as String?),
    category: ContentCategory.fromWire(json['category'] as String?),
    visibility: ContentVisibility.fromWire(json['visibility'] as String?),
    analysisMethod: AnalysisMethod.fromWire(json['analysisMethod'] as String?),
    sensitiveTopic: SensitiveTopic.fromWire(json['sensitiveTopic'] as String?),
    unclassifiedRiskFlag: json['unclassifiedRiskFlag'] as bool? ?? false,
    status: ContentStatus.fromWire(json['status'] as String?),
    scheduledDate: json['scheduledDate'] as String,
    publishedAt: json['publishedAt'] as String?,
    brief: json['brief'] as String,
    angleIdea: json['angleIdea'] as String,
    script: json['script'] as String,
    affiliateLinkUrl: json['affiliateLinkUrl'] as String,
    verifiedDestinationUrl: json['verifiedDestinationUrl'] as String,
    linkVerifiedAt: json['linkVerifiedAt'] as String,
    commercialConditionsVerifiedAt:
        json['commercialConditionsVerifiedAt'] as String,
    offerEndsAt: json['offerEndsAt'] as String?,
    affiliateDisclosure: json['affiliateDisclosure'] as String,
    aiDisclosureRequired: json['aiDisclosureRequired'] as bool? ?? false,
    aiDisclosureText: json['aiDisclosureText'] as String,
    relevanceTestPassed: json['relevanceTestPassed'] as bool? ?? false,
    editorialChecklistPassed:
        json['editorialChecklistPassed'] as bool? ?? false,
    humanHoursLogged: (json['humanHoursLogged'] as num).toDouble(),
    dossier: (json['dossier'] as List<dynamic>)
        .map((e) => DossierSource.fromJson(e as Map<String, dynamic>))
        .toList(),
    references: List<String>.from(json['references'] as List<dynamic>),
    currentManifestHash: json['currentManifestHash'] as String,
    authorization: json['authorization'] == null
        ? null
        : ContentAuthorization.fromJson(
            json['authorization'] as Map<String, dynamic>,
          ),
    versions: (json['versions'] as List<dynamic>)
        .map((e) => ContentVersion.fromJson(e as Map<String, dynamic>))
        .toList(),
    metrics: json['metrics'] == null
        ? null
        : ContentMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
  );
}

@immutable
class Channel {
  const Channel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.handle,
    required this.platform,
    required this.language,
    required this.advancedFeaturesUnlocked,
    required this.integrationStatus,
    required this.followers,
    required this.growthPct30d,
    required this.views30d,
    required this.reach30d,
    required this.engagementRatePct,
    this.shortsToLongPct,
    required this.publications30d,
    required this.lastSyncAt,
  });

  final String id;
  final String brandId;
  final String name;
  final String handle;
  final ChannelPlatform platform;
  final String language;
  final bool advancedFeaturesUnlocked;
  final ChannelIntegrationStatus integrationStatus;
  final int followers;
  final double growthPct30d;
  final int views30d;
  final int reach30d;
  final double engagementRatePct;
  final double? shortsToLongPct;
  final int publications30d;
  final String lastSyncAt;

  Channel copyWith({
    ChannelIntegrationStatus? integrationStatus,
    String? lastSyncAt,
  }) {
    return Channel(
      id: id,
      brandId: brandId,
      name: name,
      handle: handle,
      platform: platform,
      language: language,
      advancedFeaturesUnlocked: advancedFeaturesUnlocked,
      integrationStatus: integrationStatus ?? this.integrationStatus,
      followers: followers,
      growthPct30d: growthPct30d,
      views30d: views30d,
      reach30d: reach30d,
      engagementRatePct: engagementRatePct,
      shortsToLongPct: shortsToLongPct,
      publications30d: publications30d,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandId': brandId,
    'name': name,
    'handle': handle,
    'platform': platform.wire,
    'language': language,
    'advancedFeaturesUnlocked': advancedFeaturesUnlocked,
    'integrationStatus': integrationStatus.wire,
    'followers': followers,
    'growthPct30d': growthPct30d,
    'views30d': views30d,
    'reach30d': reach30d,
    'engagementRatePct': engagementRatePct,
    if (shortsToLongPct != null) 'shortsToLongPct': shortsToLongPct,
    'publications30d': publications30d,
    'lastSyncAt': lastSyncAt,
  };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json['id'] as String,
    brandId: json['brandId'] as String,
    name: json['name'] as String,
    handle: json['handle'] as String,
    platform: ChannelPlatform.fromWire(json['platform'] as String?),
    language: json['language'] as String,
    advancedFeaturesUnlocked:
        json['advancedFeaturesUnlocked'] as bool? ?? false,
    integrationStatus: ChannelIntegrationStatus.fromWire(
      json['integrationStatus'] as String?,
    ),
    followers: (json['followers'] as num).toInt(),
    growthPct30d: (json['growthPct30d'] as num).toDouble(),
    views30d: (json['views30d'] as num).toInt(),
    reach30d: (json['reach30d'] as num).toInt(),
    engagementRatePct: (json['engagementRatePct'] as num).toDouble(),
    shortsToLongPct: (json['shortsToLongPct'] as num?)?.toDouble(),
    publications30d: (json['publications30d'] as num).toInt(),
    lastSyncAt: json['lastSyncAt'] as String,
  );
}

@immutable
class FinanceEntry {
  const FinanceEntry({
    required this.id,
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

  final String id;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandId': brandId,
    if (productId != null) 'productId': productId,
    'platform': platform,
    'description': description,
    'type': type.wire,
    'stage': stage.wire,
    'amount': amount,
    'currency': currency.wire,
    if (fxRateToBRL != null) 'fxRateToBRL': fxRateToBRL,
    if (fxSource != null) 'fxSource': fxSource,
    'date': date,
    'isTest': isTest,
    'isProjection': isProjection,
  };

  factory FinanceEntry.fromJson(Map<String, dynamic> json) => FinanceEntry(
    id: json['id'] as String,
    brandId: json['brandId'] as String,
    productId: json['productId'] as String?,
    platform: json['platform'] as String,
    description: json['description'] as String,
    type: FinanceEntryType.fromWire(json['type'] as String?),
    stage: CommissionStage.fromWire(json['stage'] as String?),
    amount: (json['amount'] as num).toDouble(),
    currency: CurrencyCode.fromWire(json['currency'] as String?),
    fxRateToBRL: (json['fxRateToBRL'] as num?)?.toDouble(),
    fxSource: json['fxSource'] as String?,
    date: json['date'] as String,
    isTest: json['isTest'] as bool? ?? false,
    isProjection: json['isProjection'] as bool? ?? false,
  );
}
