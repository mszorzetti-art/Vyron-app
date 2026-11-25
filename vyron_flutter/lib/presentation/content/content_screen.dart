import 'dart:math' as math;

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
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';

const List<FeedbackCategory> _rejectionCategories = [
  FeedbackCategory.tom,
  FeedbackCategory.precisaoFonte,
  FeedbackCategory.estrutura,
  FeedbackCategory.divulgacao,
  FeedbackCategory.conformidade,
];

const List<String> _monthsPt = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

const List<String> _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key, this.contentId});

  final String? contentId;

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  String _statusFilter = 'all';
  String _formatFilter = 'all';

  int _calYear = 2026;
  int _calMonth = 11; // 1-12 (November 2026)

  String? _boundContentId;
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _scriptCtrl = TextEditingController();
  final TextEditingController _affLinkCtrl = TextEditingController();
  final TextEditingController _affDiscCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _statusNoteCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _scriptCtrl.dispose();
    _affLinkCtrl.dispose();
    _affDiscCtrl.dispose();
    _hoursCtrl.dispose();
    _statusNoteCtrl.dispose();
    super.dispose();
  }

  void _syncEditorControllers(ContentItem? active) {
    if (active == null) {
      if (_boundContentId != null) {
        _boundContentId = null;
        _descCtrl.clear();
        _scriptCtrl.clear();
        _affLinkCtrl.clear();
        _affDiscCtrl.clear();
        _hoursCtrl.clear();
        _statusNoteCtrl.clear();
      }
      return;
    }

    if (_boundContentId != active.id) {
      _boundContentId = active.id;
      _descCtrl.text = active.description;
      _scriptCtrl.text = active.script;
      _affLinkCtrl.text = active.affiliateLinkUrl;
      _affDiscCtrl.text = active.affiliateDisclosure;
      _hoursCtrl.text = active.humanHoursLogged.toString();
      _statusNoteCtrl.clear();
    }
  }

  Future<void> _pickScheduledDate(
    BuildContext context,
    ContentItem item,
    UiLanguage lang,
  ) async {
    final initial =
        DateTime.tryParse('${item.scheduledDate}T00:00:00Z') ??
        DateTime.utc(2026, 11, 21);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(2024, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
    );
    if (picked == null || !mounted) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    ref
        .read(vyronStateProvider.notifier)
        .updateContent(
          item.id,
          ContentUpdatePatch(scheduledDate: iso),
          versionNote: translate(lang, 'content.field.rescheduledNote', {
            'date': formatDateForLang(iso, lang),
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;

    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    final visibleContents = domain.contents.where((c) {
      if (appState.globalBrandFilter != 'all' &&
          c.brandId != appState.globalBrandFilter) {
        return false;
      }
      if (_statusFilter != 'all' && c.status.wire != _statusFilter) {
        return false;
      }
      if (_formatFilter != 'all' && c.format.wire != _formatFilter) {
        return false;
      }
      return true;
    }).toList();

    final effectiveId = widget.contentId ?? appState.selectedContentId;
    ContentItem? activeContent;
    if (effectiveId != null && effectiveId.isNotEmpty) {
      for (final c in domain.contents) {
        if (c.id == effectiveId) {
          activeContent = c;
          break;
        }
      }
    }
    activeContent ??= visibleContents.isNotEmpty ? visibleContents.first : null;
    _syncEditorControllers(activeContent);

    final localizedActive = activeContent != null
        ? localizeContentDisplay(activeContent, lang)
        : null;
    final preSendEval = activeContent != null
        ? evaluateContentPreSendChecks(
            activeContent,
            domain.systemControl,
            nowIso: DateTime.now().toUtc().toIso8601String(),
            evidenceFreshnessMaxHours:
                domain.settings.evidenceFreshnessMaxHours,
            language: lang,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: appState.contentSubView == ContentSubView.studio
              ? t('content.titleStudio')
              : t('content.titleCalendar'),
          subtitle: t('content.subtitle'),
          actions: [
            VyronSegmentedControl<ContentSubView>(
              key: const Key('content-subview-switch'),
              value: appState.contentSubView,
              onChanged: (sub) {
                notifier.setContentSubView(sub);
              },
              options: [
                VyronSegmentOption(
                  value: ContentSubView.studio,
                  label: t('content.tabStudio'),
                ),
                VyronSegmentOption(
                  value: ContentSubView.calendar,
                  label: t('content.tabCalendar'),
                ),
              ],
            ),
            ElevatedButton.icon(
              key: const Key('content-new-btn'),
              onPressed: () => _openCreateContentModal(
                context,
                lang,
                initialDate: '2026-11-25',
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t('content.newContent')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Bar
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VyronSegmentedControl<String>(
              key: const Key('content-status-filter'),
              value: _statusFilter,
              onChanged: (val) => setState(() => _statusFilter = val),
              options: [
                VyronSegmentOption(value: 'all', label: t('common.all')),
                for (final s in ContentStatus.values)
                  VyronSegmentOption(
                    value: s.wire,
                    label: labelContentStatus(s, lang),
                  ),
              ],
            ),
            VyronSegmentedControl<String>(
              key: const Key('content-format-filter'),
              value: _formatFilter,
              onChanged: (val) => setState(() => _formatFilter = val),
              options: [
                VyronSegmentOption(
                  value: 'all',
                  label: t('content.allFormats'),
                ),
                VyronSegmentOption(
                  value: ContentFormat.longForm.wire,
                  label: labelContentFormat(ContentFormat.longForm, lang),
                ),
                VyronSegmentOption(
                  value: ContentFormat.shorts.wire,
                  label: labelContentFormat(ContentFormat.shorts, lang),
                ),
                VyronSegmentOption(
                  value: ContentFormat.article.wire,
                  label: labelContentFormat(ContentFormat.article, lang),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        if (appState.contentSubView == ContentSubView.calendar)
          _buildCalendarView(
            context,
            visibleContents: visibleContents,
            lang: lang,
            palette: palette,
            t: t,
          )
        else
          _buildStudioView(
            context,
            appState: appState,
            visibleContents: visibleContents,
            activeContent: activeContent,
            localizedActive: localizedActive,
            preSendEval: preSendEval,
            lang: lang,
            palette: palette,
            t: t,
          ),
      ],
    );
  }

  Widget _buildCalendarView(
    BuildContext context, {
    required List<ContentItem> visibleContents,
    required UiLanguage lang,
    required VyronPaletteExtension palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final domain = ref.read(vyronStateProvider).domain;
    final monthNames = lang == UiLanguage.enUS ? _monthsEn : _monthsPt;
    final monthLabel = monthNames[_calMonth - 1];
    final weekdays = [
      t('content.calendar.sun'),
      t('content.calendar.mon'),
      t('content.calendar.tue'),
      t('content.calendar.wed'),
      t('content.calendar.thu'),
      t('content.calendar.fri'),
      t('content.calendar.sat'),
    ];

    final firstDay = DateTime.utc(_calYear, _calMonth, 1);
    final firstWeekday = firstDay.weekday % 7; // 0 = Sunday .. 6 = Saturday
    final daysInMonth = DateTime.utc(_calYear, _calMonth + 1, 0).day;

    final cells = <({int? day, String? iso})>[
      for (var i = 0; i < firstWeekday; i++) (day: null, iso: null),
      for (var d = 1; d <= daysInMonth; d++)
        (
          day: d,
          iso:
              '$_calYear-${_calMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add((day: null, iso: null));
    }
    final weekRows = (cells.length / 7).floor();

    return VyronSurfacePanel(
      key: const Key('content-calendar-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: VyronColors.electricCobalt,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$monthLabel $_calYear',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('content-cal-prev'),
                    tooltip: t('content.calendar.prevMonthAria'),
                    onPressed: () {
                      setState(() {
                        if (_calMonth == 1) {
                          _calMonth = 12;
                          _calYear -= 1;
                        } else {
                          _calMonth -= 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  OutlinedButton(
                    key: const Key('content-cal-ref'),
                    onPressed: () {
                      setState(() {
                        _calYear = 2026;
                        _calMonth = 11;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(
                      t('content.calendar.refMonth'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    key: const Key('content-cal-next'),
                    tooltip: t('content.calendar.nextMonthAria'),
                    onPressed: () {
                      setState(() {
                        if (_calMonth == 12) {
                          _calMonth = 1;
                          _calYear += 1;
                        } else {
                          _calMonth += 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final gridWidth = math.max(constraints.maxWidth, 680.0);
              final needsScroll = constraints.maxWidth < 680.0;
              final gridWidget = Container(
                width: gridWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.panelBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Weekday Header
                    Container(
                      color: palette.surfaceAlt.withValues(alpha: 0.55),
                      child: Row(
                        children: [
                          for (final wd in weekdays)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: palette.panelBorder,
                                    ),
                                    right: wd != weekdays.last
                                        ? BorderSide(color: palette.panelBorder)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  wd,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: VyronTypography.sans,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Week Rows
                    for (var w = 0; w < weekRows; w++)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var cIdx = 0; cIdx < 7; cIdx++) ...[
                              () {
                                final cell = cells[w * 7 + cIdx];
                                final day = cell.day;
                                final iso = cell.iso;
                                final isLastCol = cIdx == 6;
                                final isLastRow = w == weekRows - 1;

                                if (day == null || iso == null) {
                                  return Expanded(
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 94,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.surfaceAlt.withValues(
                                          alpha: 0.22,
                                        ),
                                        border: Border(
                                          bottom: isLastRow
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: palette.panelBorder,
                                                ),
                                          right: isLastCol
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: palette.panelBorder,
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final dayItems = visibleContents
                                    .where((it) => it.scheduledDate == iso)
                                    .toList();

                                return Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 98,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: palette.surface,
                                      border: Border(
                                        bottom: isLastRow
                                            ? BorderSide.none
                                            : BorderSide(
                                                color: palette.panelBorder,
                                              ),
                                        right: isLastCol
                                            ? BorderSide.none
                                            : BorderSide(
                                                color: palette.panelBorder,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$day',
                                              style: TextStyle(
                                                fontFamily:
                                                    VyronTypography.mono,
                                                fontSize: 11,
                                                color: palette.textMuted,
                                              ),
                                            ),
                                            InkWell(
                                              key: Key('cal-add-$iso'),
                                              onTap: () =>
                                                  _openCreateContentModal(
                                                    context,
                                                    lang,
                                                    initialDate: iso,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1,
                                                    ),
                                                child: Text(
                                                  '+',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: palette.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            for (final item in dayItems) ...[
                                              () {
                                                Color brandAccent =
                                                    VyronColors.electricCobalt;
                                                for (final b in domain.brands) {
                                                  if (b.id == item.brandId) {
                                                    brandAccent =
                                                        parseVyronHexColor(
                                                          b.accentColor,
                                                        );
                                                    break;
                                                  }
                                                }
                                                final loc =
                                                    localizeContentDisplay(
                                                      item,
                                                      lang,
                                                    );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: InkWell(
                                                    key: Key(
                                                      'cal-item-${item.id}',
                                                    ),
                                                    onTap: () {
                                                      navigateToVyronModule(
                                                        ref,
                                                        NavModule.content,
                                                        contentId: item.id,
                                                        setContentId: true,
                                                        contentSubView:
                                                            ContentSubView
                                                                .studio,
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            palette.background,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: palette
                                                              .panelBorder,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 6,
                                                                height: 6,
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      brandAccent,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        1,
                                                                      ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  '${labelContentFormat(item.format, lang)} · ${labelContentVisibility(item.visibility, lang)}',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: TextStyle(
                                                                    fontSize: 9,
                                                                    color: palette
                                                                        .textMuted,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            loc.title,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }(),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }(),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              );

              if (needsScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: gridWidget,
                );
              }
              return gridWidget;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudioView(
    BuildContext context, {
    required VyronAppState appState,
    required List<ContentItem> visibleContents,
    required ContentItem? activeContent,
    required LocalizedContentDisplay? localizedActive,
    required PreSendEvaluation? preSendEval,
    required UiLanguage lang,
    required VyronPaletteExtension palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final queuePanel = _buildQueuePanel(
      context,
      appState: appState,
      visibleContents: visibleContents,
      activeContent: activeContent,
      lang: lang,
      palette: palette,
      t: t,
    );

    final workspaceColumn = _buildWorkspaceColumn(
      context,
      appState: appState,
      activeContent: activeContent,
      localizedActive: localizedActive,
      preSendEval: preSendEval,
      lang: lang,
      palette: palette,
      t: t,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: queuePanel),
              const SizedBox(width: 18),
              Expanded(flex: 8, child: workspaceColumn),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [queuePanel, const SizedBox(height: 18), workspaceColumn],
        );
      },
    );
  }

  Widget _buildQueuePanel(
    BuildContext context, {
    required VyronAppState appState,
    required List<ContentItem> visibleContents,
    required ContentItem? activeContent,
    required UiLanguage lang,
    required VyronPaletteExtension palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final domain = appState.domain;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return VyronSurfacePanel(
      padding: VyronPanelPadding.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.panelBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t('content.queueTitle', {
                      'count': '${visibleContents.length}',
                    }),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t('content.queueHint'),
                  style: TextStyle(fontSize: 11, color: palette.textMuted),
                ),
              ],
            ),
          ),
          if (visibleContents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t('content.queueEmpty'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var idx = 0; idx < visibleContents.length; idx++) ...[
                  () {
                    final c = visibleContents[idx];
                    String brandName = c.brandId;
                    for (final b in domain.brands) {
                      if (b.id == c.brandId) {
                        brandName = b.name;
                        break;
                      }
                    }
                    String chPlatform = '';
                    for (final ch in domain.channels) {
                      if (ch.id == c.channelId) {
                        chPlatform = ch.platform.wire;
                        break;
                      }
                    }
                    final loc = localizeContentDisplay(c, lang);
                    final isSelected = activeContent?.id == c.id;
                    final auth = c.authorization;
                    final hashAuthOk =
                        auth != null &&
                        auth.revoked != true &&
                        auth.authorizedHash == c.currentManifestHash;

                    return InkWell(
                      key: Key('content-queue-${c.id}'),
                      onTap: () {
                        navigateToVyronModule(
                          ref,
                          NavModule.content,
                          contentId: c.id,
                          setContentId: true,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VyronColors.electricCobalt.withValues(
                                  alpha: isDark ? 0.16 : 0.09,
                                )
                              : Colors.transparent,
                          border: idx < visibleContents.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color: palette.panelBorder,
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$brandName · $chPlatform · ${labelContentVisibility(c.visibility, lang)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDateForLang(c.scheduledDate, lang),
                                  style: TextStyle(
                                    fontFamily: VyronTypography.mono,
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: VyronStatusLabel(
                                    status: labelContentStatus(c.status, lang),
                                    statusKey: c.status.wire,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hashAuthOk
                                      ? t('content.hashOk')
                                      : c.authorization != null
                                      ? t('content.hashInvalid')
                                      : t('content.noHash'),
                                  style: TextStyle(
                                    fontFamily: VyronTypography.mono,
                                    fontSize: 10,
                                    color: hashAuthOk
                                        ? (isDark
                                              ? VyronColors.emeraldDarkText
                                              : VyronColors.emeraldLightText)
                                        : palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceColumn(
    BuildContext context, {
    required VyronAppState appState,
    required ContentItem? activeContent,
    required LocalizedContentDisplay? localizedActive,
    required PreSendEvaluation? preSendEval,
    required UiLanguage lang,
    required VyronPaletteExtension palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    if (activeContent == null ||
        localizedActive == null ||
        preSendEval == null) {
      return VyronEmptyState(
        title: t('content.emptyTitle'),
        description: t('content.emptyDesc'),
        actionLabel: t('content.emptyCta'),
        onAction: () =>
            _openCreateContentModal(context, lang, initialDate: '2026-11-25'),
      );
    }

    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = activeContent;
    final auth = item.authorization;

    String brandName = item.brandId;
    for (final b in domain.brands) {
      if (b.id == item.brandId) {
        brandName = b.name;
        break;
      }
    }
    String channelName = item.channelId;
    for (final ch in domain.channels) {
      if (ch.id == item.channelId) {
        channelName = ch.name;
        break;
      }
    }

    final blockedCount = preSendEval.checks.where((c) => !c.passed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Main Manifest & Editorial Controls
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: palette.panelBorder),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: palette.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '$brandName · $channelName · ${labelContentFormat(item.format, lang)} · ${labelContentCategory(item.category, lang)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            localizedActive.title,
                            style: Theme.of(context).textTheme.titleLarge,
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
              const SizedBox(height: 16),

              // 4 Operational & Governance Parameters
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 700
                      ? 4
                      : (constraints.maxWidth >= 460 ? 2 : 1);
                  const gap = 12.0;
                  final cellW =
                      (constraints.maxWidth - gap * (cols - 1)) / cols;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: cellW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t('content.field.scheduledDate'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              key: const Key('content-scheduled-date-btn'),
                              onPressed: () =>
                                  _pickScheduledDate(context, item, lang),
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                              ),
                              label: Text(
                                formatDateForLang(item.scheduledDate, lang),
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: cellW,
                        child: VyronDropdownField<ContentVisibility>(
                          key: const Key('content-visibility-dropdown'),
                          labelText: t('content.field.visibility'),
                          value: item.visibility,
                          items: [
                            DropdownMenuItem(
                              value: ContentVisibility.privateVis,
                              child: Text(
                                '${labelContentVisibility(ContentVisibility.privateVis, lang)} (${t('common.privateEnv')})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: ContentVisibility.unlisted,
                              child: Text(
                                labelContentVisibility(
                                  ContentVisibility.unlisted,
                                  lang,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: ContentVisibility.publicVis,
                              child: Text(
                                labelContentVisibility(
                                  ContentVisibility.publicVis,
                                  lang,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (next) {
                            if (next == null) return;
                            notifier.updateContent(
                              item.id,
                              ContentUpdatePatch(visibility: next),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: cellW,
                        child: VyronDropdownField<AnalysisMethod>(
                          key: const Key('content-analysis-dropdown'),
                          labelText: t('content.field.analysisMethod'),
                          value: item.analysisMethod,
                          items: [
                            for (final am in AnalysisMethod.values)
                              DropdownMenuItem(
                                value: am,
                                child: Text(
                                  labelAnalysisMethod(am, lang),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (next) {
                            if (next == null) return;
                            notifier.updateContent(
                              item.id,
                              ContentUpdatePatch(analysisMethod: next),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: cellW,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: VyronDropdownField<SensitiveTopic>(
                                key: const Key('content-sensitive-dropdown'),
                                labelText: t('content.field.sensitiveHours'),
                                value: item.sensitiveTopic,
                                items: [
                                  for (final st in SensitiveTopic.values)
                                    DropdownMenuItem(
                                      value: st,
                                      child: Text(
                                        labelSensitiveTopic(st, lang),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (next) {
                                  if (next == null) return;
                                  notifier.updateContent(
                                    item.id,
                                    ContentUpdatePatch(sensitiveTopic: next),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: TextField(
                                key: const Key('content-hours-field'),
                                controller: _hoursCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 12,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'h',
                                ),
                                onChanged: (raw) {
                                  final parsed = double.tryParse(
                                    raw.replaceAll(',', '.'),
                                  );
                                  if (parsed == null) return;
                                  notifier.updateContent(
                                    item.id,
                                    ContentUpdatePatch(
                                      humanHoursLogged: math.max(0.0, parsed),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                key: const Key('content-desc-field'),
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t('content.field.description'),
                ),
                onChanged: (val) {
                  notifier.updateContent(
                    item.id,
                    ContentUpdatePatch(description: val),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Script (manifest-hashed)
              TextField(
                key: const Key('content-script-field'),
                controller: _scriptCtrl,
                maxLines: 4,
                style: const TextStyle(
                  fontFamily: VyronTypography.mono,
                  fontSize: 12,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  labelText: t('content.field.script'),
                ),
                onChanged: (val) {
                  notifier.updateContent(
                    item.id,
                    ContentUpdatePatch(script: val),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Affiliate Link + Disclosure
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 560;
                  final linkField = TextField(
                    key: const Key('content-aff-link-field'),
                    controller: _affLinkCtrl,
                    style: const TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      labelText: t('content.field.affiliateLink'),
                    ),
                    onChanged: (val) {
                      notifier.updateContent(
                        item.id,
                        ContentUpdatePatch(affiliateLinkUrl: val),
                      );
                    },
                  );
                  final discField = TextField(
                    key: const Key('content-aff-disc-field'),
                    controller: _affDiscCtrl,
                    decoration: InputDecoration(
                      labelText: t('content.field.disclosure'),
                    ),
                    onChanged: (val) {
                      notifier.updateContent(
                        item.id,
                        ContentUpdatePatch(affiliateDisclosure: val),
                      );
                    },
                  );
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: linkField),
                        const SizedBox(width: 12),
                        Expanded(child: discField),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      linkField,
                      const SizedBox(height: 12),
                      discField,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // 3 Compliance Checkboxes
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 640 ? 3 : 1;
                  const gap = 10.0;
                  final tileW =
                      (constraints.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _CheckToggleCard(
                        key: const Key('content-relevance-check'),
                        width: tileW,
                        value: item.relevanceTestPassed,
                        label: t('content.field.relevanceCheck'),
                        onChanged: (checked) {
                          notifier.updateContent(
                            item.id,
                            ContentUpdatePatch(relevanceTestPassed: checked),
                          );
                        },
                      ),
                      _CheckToggleCard(
                        key: const Key('content-editorial-check'),
                        width: tileW,
                        value: item.editorialChecklistPassed,
                        label: t('content.field.editorialCheck'),
                        onChanged: (checked) {
                          notifier.updateContent(
                            item.id,
                            ContentUpdatePatch(
                              editorialChecklistPassed: checked,
                            ),
                          );
                        },
                      ),
                      _CheckToggleCard(
                        key: const Key('content-unclassified-risk-check'),
                        width: tileW,
                        value: item.unclassifiedRiskFlag,
                        label: t('content.field.unclassifiedRisk'),
                        onChanged: (checked) {
                          notifier.updateContent(
                            item.id,
                            ContentUpdatePatch(unclassifiedRiskFlag: checked),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. HASH APPROVAL PANEL & 6 MANDATORY PRE-SEND CHECKS
        VyronSurfacePanel(
          key: const Key('content-hash-panel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: palette.panelBorder),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 17,
                                color: VyronColors.electricCobalt,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  t('content.hashPanel.title'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('content.hashPanel.subtitle'),
                            style: TextStyle(
                              fontSize: 12,
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
                          t('content.hashPanel.currentManifest'),
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                        Text(
                          '${preSendEval.recalculatedHash.substring(0, 16)}...',
                          key: const Key('content-current-hash'),
                          style: const TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Summary cards: linked auth vs gate result
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 560;
                  final authCard = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('content.hashPanel.linkedAuth'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (auth != null) ...[
                          Text(
                            t('content.hashPanel.hashPrefix', {
                              'hash': auth.authorizedHash.substring(0, 16),
                            }),
                            style: const TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t('content.hashPanel.byActorExpires', {
                              'actor': localizeActor(auth.actor, lang),
                              'date': formatDateTimeForLang(
                                auth.expiresAt,
                                lang,
                              ),
                            }),
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                        ] else
                          Text(
                            t('content.hashPanel.noActiveAuth'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? VyronColors.amberDarkText
                                  : VyronColors.amberLightText,
                            ),
                          ),
                      ],
                    ),
                  );

                  final gateCard = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('content.hashPanel.gateResult'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (preSendEval.canSend)
                          Text(
                            t('content.hashPanel.readyToSend', {
                              'visibility': labelContentVisibility(
                                item.visibility,
                                lang,
                              ),
                            }),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? VyronColors.emeraldDarkText
                                  : VyronColors.emeraldLightText,
                            ),
                          )
                        else
                          Text(
                            t('content.hashPanel.blocked', {
                              'count': '$blockedCount',
                            }),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? VyronColors.crimsonDarkText
                                  : VyronColors.crimsonLightText,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          t('content.hashPanel.controlsSummary', {
                            'state': labelSystemControlState(
                              domain.systemControl.state,
                              lang,
                            ),
                            'pub': domain.systemControl.publishingEnabled
                                ? t('content.hashPanel.pubEnabled')
                                : t('content.hashPanel.pubDisabled'),
                          }),
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: authCard),
                        const SizedBox(width: 12),
                        Expanded(child: gateCard),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [authCard, const SizedBox(height: 10), gateCard],
                  );
                },
              ),
              const SizedBox(height: 14),

              // 6 Mandatory Pre-Send Checks
              for (final chk in preSendEval.checks) ...[
                Container(
                  key: Key('content-check-${chk.id.name}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        chk.passed
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        size: 17,
                        color: chk.passed
                            ? (isDark
                                  ? VyronColors.emeraldDarkText
                                  : VyronColors.emeraldLightText)
                            : (isDark
                                  ? VyronColors.crimsonDarkText
                                  : VyronColors.crimsonLightText),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chk.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chk.detail,
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
              const SizedBox(height: 6),

              // Hash Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('content-revalidate-btn'),
                    onPressed: () {
                      notifier.revalidateContentEvidence(item.id);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: Text(t('content.action.revalidate')),
                  ),
                  ElevatedButton.icon(
                    key: const Key('content-authorize-btn'),
                    onPressed: () => _openAuthorizeHashModal(
                      context,
                      item: item,
                      recalculatedHash: preSendEval.recalculatedHash,
                      lang: lang,
                    ),
                    icon: const Icon(Icons.lock_outline_rounded, size: 15),
                    label: Text(t('content.action.authorize')),
                  ),
                  if (auth != null && auth.revoked != true)
                    OutlinedButton(
                      key: const Key('content-revoke-btn'),
                      onPressed: () {
                        notifier.revokeContentAuthorization(
                          item.id,
                          t('content.action.revokeReason'),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? VyronColors.amberDarkText
                            : VyronColors.amberLightText,
                        side: BorderSide(
                          color: VyronColors.amber.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(t('content.action.revoke')),
                    ),
                  OutlinedButton.icon(
                    key: const Key('content-reject-btn'),
                    onPressed: () => _openRejectFeedbackModal(
                      context,
                      item: item,
                      lang: lang,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? VyronColors.crimsonDarkText
                          : VyronColors.crimsonLightText,
                      side: BorderSide(
                        color: VyronColors.crimson.withValues(alpha: 0.45),
                      ),
                    ),
                    icon: const Icon(Icons.gpp_bad_outlined, size: 15),
                    label: Text(t('content.action.reject')),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Manual Version Note & Status Transitions
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.panelBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('content-version-note-field'),
                            controller: _statusNoteCtrl,
                            decoration: InputDecoration(
                              hintText: t('content.versionNotePlaceholder'),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          key: const Key('content-save-version-btn'),
                          onPressed: () {
                            final note = _statusNoteCtrl.text.trim();
                            notifier.updateContent(
                              item.id,
                              const ContentUpdatePatch(),
                              versionNote: note.isNotEmpty
                                  ? note
                                  : t('content.versionNoteDefault'),
                            );
                            _statusNoteCtrl.clear();
                          },
                          child: Text(t('content.saveVersion')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final st in ContentStatus.values)
                          () {
                            final isCurr = item.status == st;
                            if (isCurr) {
                              return ElevatedButton(
                                key: Key('content-status-btn-${st.name}'),
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor:
                                      VyronColors.electricCobalt,
                                  disabledForegroundColor:
                                      VyronColors.coolWhite,
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: Text(
                                  labelContentStatus(st, lang),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }
                            return OutlinedButton(
                              key: Key('content-status-btn-${st.name}'),
                              onPressed: () {
                                final note = _statusNoteCtrl.text.trim();
                                notifier.changeContentStatus(
                                  item.id,
                                  st,
                                  note.isNotEmpty
                                      ? note
                                      : t('content.movedToNote', {
                                          'status': labelContentStatus(
                                            st,
                                            lang,
                                          ),
                                        }),
                                );
                                _statusNoteCtrl.clear();
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: Text(
                                labelContentStatus(st, lang),
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 3. Dossier + Metrics & Version History
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            final dossierPanel = _buildDossierAndMetricsPanel(
              context,
              item: item,
              localizedActive: localizedActive,
              lang: lang,
              palette: palette,
              t: t,
            );
            final versionsPanel = _buildVersionHistoryPanel(
              context,
              localizedActive: localizedActive,
              lang: lang,
              palette: palette,
              t: t,
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dossierPanel),
                  const SizedBox(width: 18),
                  Expanded(child: versionsPanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dossierPanel,
                const SizedBox(height: 18),
                versionsPanel,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDossierAndMetricsPanel(
    BuildContext context, {
    required ContentItem item,
    required LocalizedContentDisplay localizedActive,
    required UiLanguage lang,
    required VyronPaletteExtension palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = item.metrics;

    return VyronSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('content.dossierTitle'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (localizedActive.dossier.isEmpty)
            Text(
              t('content.dossierEmpty'),
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            )
          else
            for (final d in localizedActive.dossier) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.panelBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('content.dossierLevelDate', {
                        'level': '${d.level}',
                        'date': formatDateForLang(d.consultedAt, lang),
                      }),
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 10,
                        color: palette.cobaltText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.claim,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.sourceTitle,
                      style: TextStyle(fontSize: 11, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          if (metrics != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.panelBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        t('content.metrics.title'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        labelAttributionStatus(metrics.attributionStatus, lang),
                        style: TextStyle(
                          fontFamily: VyronTypography.mono,
                          fontSize: 11,
                          color: isDark
                              ? VyronColors.amberDarkText
                              : VyronColors.amberLightText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetricTile(
                          label: t('content.metrics.viewsRet'),
                          value:
                              '${formatCompactNumberForLang(metrics.views, lang)} · ${formatNumberForLang(metrics.retention30sPct, lang, 1)}%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetricTile(
                          label: t('content.metrics.clicksTracking'),
                          value:
                              '${formatCompactNumberForLang(metrics.clicks, lang)} (${metrics.trackingSrc})',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetricTile(
                          label: t('content.metrics.conversions'),
                          value: '${metrics.conversions}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetricTile(
                          label: t('content.metrics.revenue'),
                          value: formatCurrencyForLang(
                            metrics.revenueGenerated,
                            metrics.currency,
                            lang,
                          ),
                          valueColor: isDark
                              ? VyronColors.emeraldDarkText
                              : VyronColors.emeraldLightText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionHistoryPanel(
    BuildContext context, {
    required LocalizedContentDisplay localizedActive,
    required UiLanguage lang,
    required VyronPaletteExtension palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final versions = localizedActive.versions;
    return VyronSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('content.versionsTitle', {'count': '${versions.length}'}),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < versions.length; i++) ...[
            () {
              final v = versions[i];
              final fbLabel = v.feedbackCategory != null
                  ? ' [${labelFeedbackCategory(v.feedbackCategory!, lang)}]'
                  : '';
              return Container(
                padding: const EdgeInsets.only(bottom: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: i < versions.length - 1
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: palette.panelBorder),
                        ),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${v.version} · ${v.author}$fbLabel',
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.cobaltText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatDateForLang(v.timestamp, lang),
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'hash: ${v.manifestHash.substring(0, math.min(14, v.manifestHash.length))}...',
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 10,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.note,
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  ],
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  Future<void> _openAuthorizeHashModal(
    BuildContext context, {
    required ContentItem item,
    required String recalculatedHash,
    required UiLanguage lang,
  }) async {
    final domain = ref.read(vyronStateProvider).domain;
    final notifier = ref.read(vyronStateProvider.notifier);

    await showVyronModalDialog<void>(
      context: context,
      title: translate(lang, 'content.modal.authTitle'),
      subtitle: translate(lang, 'content.modal.authSubtitle'),
      language: lang,
      builder: (dialogContext) {
        return _AuthorizeHashModalBody(
          item: item,
          recalculatedHash: recalculatedHash,
          lang: lang,
          initialActor: domain.settings.ownerName,
          initialValidHours: domain.settings.defaultAuthValidityHours,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: (actor, validHours, note) {
            notifier.authorizeContentVersion(
              item.id,
              actor: actor,
              validHours: validHours,
              note: note,
            );
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _openRejectFeedbackModal(
    BuildContext context, {
    required ContentItem item,
    required UiLanguage lang,
  }) async {
    final notifier = ref.read(vyronStateProvider.notifier);

    await showVyronModalDialog<void>(
      context: context,
      title: translate(lang, 'content.modal.rejectTitle'),
      subtitle: translate(lang, 'content.modal.rejectSubtitle'),
      language: lang,
      builder: (dialogContext) {
        return _RejectFeedbackModalBody(
          lang: lang,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: (category, note) {
            notifier.rejectContentWithFeedback(
              item.id,
              category: category,
              note: note,
            );
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _openCreateContentModal(
    BuildContext context,
    UiLanguage lang, {
    required String initialDate,
  }) async {
    final domain = ref.read(vyronStateProvider).domain;
    final notifier = ref.read(vyronStateProvider.notifier);
    final nonTestProducts = domain.products.where((p) => !p.isTest).toList();

    await showVyronModalDialog<void>(
      context: context,
      title: translate(lang, 'content.modal.createTitle'),
      subtitle: translate(lang, 'content.modal.createSubtitle'),
      language: lang,
      maxWidth: 560,
      builder: (dialogContext) {
        return _CreateContentModalBody(
          lang: lang,
          initialDate: initialDate,
          brands: domain.brands,
          channels: domain.channels,
          nonTestProducts: nonTestProducts,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSubmit: (input) {
            final created = notifier.createContent(input);
            Navigator.of(dialogContext).pop();
            navigateToVyronModule(
              ref,
              NavModule.content,
              contentId: created.id,
              setContentId: true,
              contentSubView: ContentSubView.studio,
            );
          },
        );
      },
    );
  }
}

class _AuthorizeHashModalBody extends StatefulWidget {
  const _AuthorizeHashModalBody({
    required this.item,
    required this.recalculatedHash,
    required this.lang,
    required this.initialActor,
    required this.initialValidHours,
    required this.onCancel,
    required this.onConfirm,
  });

  final ContentItem item;
  final String recalculatedHash;
  final UiLanguage lang;
  final String initialActor;
  final int initialValidHours;
  final VoidCallback onCancel;
  final void Function(String actor, int validHours, String note) onConfirm;

  @override
  State<_AuthorizeHashModalBody> createState() =>
      _AuthorizeHashModalBodyState();
}

class _AuthorizeHashModalBodyState extends State<_AuthorizeHashModalBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _actorCtrl;
  late final TextEditingController _validCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _actorCtrl = TextEditingController(text: widget.initialActor);
    _validCtrl = TextEditingController(text: '${widget.initialValidHours}');
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _actorCtrl.dispose();
    _validCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final lang = widget.lang;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translate(lang, 'content.modal.manifestHash', {
                    'hash': widget.recalculatedHash,
                  }),
                  style: const TextStyle(
                    fontFamily: VyronTypography.mono,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translate(lang, 'content.modal.visibility', {
                    'visibility': labelContentVisibility(
                      widget.item.visibility,
                      lang,
                    ),
                  }),
                  style: const TextStyle(
                    fontFamily: VyronTypography.mono,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translate(lang, 'content.modal.rulesType'),
                  style: const TextStyle(
                    fontFamily: VyronTypography.mono,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('auth-modal-actor'),
                  controller: _actorCtrl,
                  decoration: InputDecoration(
                    labelText: translate(lang, 'content.modal.authorizer'),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? '*' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('auth-modal-hours'),
                  controller: _validCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: VyronTypography.mono),
                  decoration: InputDecoration(
                    labelText: translate(lang, 'content.modal.validityHours'),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1 || n > 168) return '1-168';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('auth-modal-note'),
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: translate(lang, 'content.modal.auditNote'),
              hintText: translate(lang, 'content.modal.auditNotePlaceholder'),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(translate(lang, 'common.cancel')),
              ),
              ElevatedButton(
                key: const Key('auth-modal-confirm'),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onConfirm(
                    _actorCtrl.text.trim(),
                    math.max(1, int.tryParse(_validCtrl.text) ?? 48),
                    _noteCtrl.text.trim(),
                  );
                },
                child: Text(translate(lang, 'content.modal.confirmAuth')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RejectFeedbackModalBody extends StatefulWidget {
  const _RejectFeedbackModalBody({
    required this.lang,
    required this.onCancel,
    required this.onConfirm,
  });

  final UiLanguage lang;
  final VoidCallback onCancel;
  final void Function(FeedbackCategory category, String note) onConfirm;

  @override
  State<_RejectFeedbackModalBody> createState() =>
      _RejectFeedbackModalBodyState();
}

class _RejectFeedbackModalBodyState extends State<_RejectFeedbackModalBody> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.tom;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VyronDropdownField<FeedbackCategory>(
            key: const Key('reject-modal-category'),
            labelText: translate(lang, 'content.modal.rejectCategory'),
            value: _selectedCategory,
            items: [
              for (final cat in _rejectionCategories)
                DropdownMenuItem(
                  value: cat,
                  child: Text(labelFeedbackCategory(cat, lang)),
                ),
            ],
            onChanged: (next) {
              if (next != null) {
                setState(() => _selectedCategory = next);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('reject-modal-note'),
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: translate(lang, 'content.modal.rejectReason'),
              hintText: translate(lang, 'content.modal.rejectPlaceholder'),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? '*' : null,
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(translate(lang, 'common.cancel')),
              ),
              ElevatedButton(
                key: const Key('reject-modal-confirm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VyronColors.crimson,
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onConfirm(_selectedCategory, _noteCtrl.text.trim());
                },
                child: Text(translate(lang, 'content.modal.confirmReject')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateContentModalBody extends StatefulWidget {
  const _CreateContentModalBody({
    required this.lang,
    required this.initialDate,
    required this.brands,
    required this.channels,
    required this.nonTestProducts,
    required this.onCancel,
    required this.onSubmit,
  });

  final UiLanguage lang;
  final String initialDate;
  final List<Brand> brands;
  final List<Channel> channels;
  final List<Product> nonTestProducts;
  final VoidCallback onCancel;
  final ValueChanged<ContentCreateInput> onSubmit;

  @override
  State<_CreateContentModalBody> createState() =>
      _CreateContentModalBodyState();
}

class _CreateContentModalBodyState extends State<_CreateContentModalBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _briefCtrl = TextEditingController();
  late String _brandId;
  late String _channelId;
  String _productId = '';
  ContentFormat _format = ContentFormat.longForm;
  ContentCategory _category = ContentCategory.comercialContextual;
  ContentVisibility _visibility = ContentVisibility.privateVis;
  late String _plannedDate;

  @override
  void initState() {
    super.initState();
    _brandId = widget.brands.isNotEmpty ? widget.brands.first.id : '';
    _channelId = widget.channels.isNotEmpty ? widget.channels.first.id : '';
    _plannedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _briefCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('create-content-title'),
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: translate(lang, 'content.modal.titleReq'),
              hintText: translate(lang, 'content.modal.titlePlaceholder'),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? '*' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.brands.isNotEmpty)
                Expanded(
                  child: VyronDropdownField<String>(
                    key: const Key('create-content-brand'),
                    labelText: translate(lang, 'content.modal.brand'),
                    value: _brandId,
                    items: [
                      for (final b in widget.brands)
                        DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (next) {
                      if (next != null) {
                        setState(() => _brandId = next);
                      }
                    },
                  ),
                ),
              if (widget.brands.isNotEmpty && widget.channels.isNotEmpty)
                const SizedBox(width: 12),
              if (widget.channels.isNotEmpty)
                Expanded(
                  child: VyronDropdownField<String>(
                    key: const Key('create-content-channel'),
                    labelText: translate(lang, 'content.modal.channel'),
                    value: _channelId,
                    items: [
                      for (final ch in widget.channels)
                        DropdownMenuItem(
                          value: ch.id,
                          child: Text(
                            '${ch.name} (${ch.platform.wire})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (next) {
                      if (next != null) {
                        setState(() => _channelId = next);
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (cCtx, cCons) {
              final wide = cCons.maxWidth >= 420;
              final fDrop = VyronDropdownField<ContentFormat>(
                labelText: translate(lang, 'content.modal.format'),
                value: _format,
                items: [
                  for (final f in ContentFormat.values)
                    DropdownMenuItem(
                      value: f,
                      child: Text(
                        labelContentFormat(f, lang),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (next) {
                  if (next != null) setState(() => _format = next);
                },
              );
              final cDrop = VyronDropdownField<ContentCategory>(
                labelText: translate(lang, 'content.modal.category'),
                value: _category,
                items: [
                  for (final cat in ContentCategory.values)
                    DropdownMenuItem(
                      value: cat,
                      child: Text(
                        labelContentCategory(cat, lang),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (next) {
                  if (next != null) {
                    setState(() => _category = next);
                  }
                },
              );
              final vDrop = VyronDropdownField<ContentVisibility>(
                labelText: translate(lang, 'content.modal.visibilityLabel'),
                value: _visibility,
                items: [
                  for (final v in ContentVisibility.values)
                    DropdownMenuItem(
                      value: v,
                      child: Text(
                        labelContentVisibility(v, lang),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (next) {
                  if (next != null) {
                    setState(() => _visibility = next);
                  }
                },
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: fDrop),
                    const SizedBox(width: 8),
                    Expanded(child: cDrop),
                    const SizedBox(width: 8),
                    Expanded(child: vDrop),
                  ],
                );
              }
              return Column(
                children: [
                  fDrop,
                  const SizedBox(height: 10),
                  cDrop,
                  const SizedBox(height: 10),
                  vDrop,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translate(lang, 'content.modal.plannedDate'),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.vyronColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final initial =
                            DateTime.tryParse('${_plannedDate}T00:00:00Z') ??
                            DateTime.utc(2026, 11, 25);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime.utc(2024, 1, 1),
                          lastDate: DateTime.utc(2030, 12, 31),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _plannedDate =
                                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
                      label: Text(
                        formatDateForLang(_plannedDate, lang),
                        style: const TextStyle(
                          fontFamily: VyronTypography.mono,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VyronDropdownField<String>(
                  labelText: translate(lang, 'content.modal.productOptional'),
                  value: _productId,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(translate(lang, 'common.none')),
                    ),
                    for (final p in widget.nonTestProducts)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          localizeProduct(p, lang).name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (next) {
                    if (next != null) {
                      setState(() => _productId = next);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('create-content-brief'),
            controller: _briefCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: translate(lang, 'content.modal.brief'),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: widget.onCancel,
                child: Text(translate(lang, 'common.cancel')),
              ),
              ElevatedButton(
                key: const Key('create-content-submit'),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onSubmit(
                    ContentCreateInput(
                      brandId: _brandId,
                      channelId: _channelId,
                      productId: _productId.isEmpty ? null : _productId,
                      title: _titleCtrl.text.trim(),
                      format: _format,
                      category: _category,
                      visibility: _visibility,
                      status: ContentStatus.brief,
                      scheduledDate: _plannedDate,
                      brief: _briefCtrl.text.trim().isNotEmpty
                          ? _briefCtrl.text.trim()
                          : translate(lang, 'content.modal.createTitle'),
                      angleIdea: lang == UiLanguage.enUS
                          ? 'Technical and comparative approach.'
                          : 'Abordagem técnica e comparativa.',
                      script: lang == UiLanguage.enUS
                          ? '1. Technical hook\n2. Practical evidence\n3. Final recommendation'
                          : '1. Gancho técnico\n2. Evidência prática\n3. Recomendação final',
                      references: const [],
                    ),
                  );
                },
                child: Text(translate(lang, 'content.modal.createBtn')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckToggleCard extends StatelessWidget {
  const _CheckToggleCard({
    super.key,
    required this.width,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final double width;
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.panelBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: value,
                  onChanged: (checked) {
                    if (checked != null) onChanged(checked);
                  },
                  activeColor: VyronColors.electricCobalt,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: palette.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: VyronTypography.mono,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
