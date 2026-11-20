import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_access_notifier.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/security/vyron_access_rules.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_mark.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';
import 'system_control_modal.dart';

class _NavItemSpec {
  const _NavItemSpec({
    required this.module,
    required this.labelKey,
    required this.icon,
  });

  final NavModule module;
  final String labelKey;
  final IconData icon;
}

class _NavGroupSpec {
  const _NavGroupSpec({
    required this.labelKey,
    required this.items,
  });

  final String labelKey;
  final List<_NavItemSpec> items;
}

const List<_NavGroupSpec> _navGroups = [
  _NavGroupSpec(
    labelKey: 'nav.group.operation',
    items: [
      _NavItemSpec(
        module: NavModule.overview,
        labelKey: 'nav.overview',
        icon: Icons.dashboard_outlined,
      ),
      _NavItemSpec(
        module: NavModule.brands,
        labelKey: 'nav.brands',
        icon: Icons.layers_outlined,
      ),
      _NavItemSpec(
        module: NavModule.products,
        labelKey: 'nav.products',
        icon: Icons.inventory_2_outlined,
      ),
      _NavItemSpec(
        module: NavModule.content,
        labelKey: 'nav.content',
        icon: Icons.description_outlined,
      ),
      _NavItemSpec(
        module: NavModule.channels,
        labelKey: 'nav.channels',
        icon: Icons.sensors_outlined,
      ),
    ],
  ),
  _NavGroupSpec(
    labelKey: 'nav.group.performance',
    items: [
      _NavItemSpec(
        module: NavModule.analytics,
        labelKey: 'nav.analytics',
        icon: Icons.bar_chart_outlined,
      ),
      _NavItemSpec(
        module: NavModule.finance,
        labelKey: 'nav.finance',
        icon: Icons.account_balance_wallet_outlined,
      ),
    ],
  ),
  _NavGroupSpec(
    labelKey: 'nav.group.governance',
    items: [
      _NavItemSpec(
        module: NavModule.automations,
        labelKey: 'nav.automations',
        icon: Icons.smart_toy_outlined,
      ),
      _NavItemSpec(
        module: NavModule.activity,
        labelKey: 'nav.activity',
        icon: Icons.timeline_outlined,
      ),
      _NavItemSpec(
        module: NavModule.notifications,
        labelKey: 'nav.notifications',
        icon: Icons.notifications_outlined,
      ),
      _NavItemSpec(
        module: NavModule.settings,
        labelKey: 'nav.settings',
        icon: Icons.settings_outlined,
      ),
    ],
  ),
];

String moduleLabelKey(NavModule module) {
  return switch (module) {
    NavModule.overview => 'nav.overview',
    NavModule.brands => 'nav.brands',
    NavModule.products => 'nav.products',
    NavModule.content => 'nav.content',
    NavModule.channels => 'nav.channels',
    NavModule.analytics => 'nav.analytics',
    NavModule.finance => 'nav.finance',
    NavModule.automations => 'nav.automations',
    NavModule.activity => 'nav.activity',
    NavModule.notifications => 'nav.notifications',
    NavModule.settings => 'nav.settings',
  };
}

enum _OwnerMenuAction {
  lock,
  settings,
  logout,
}

/// Shell adaptativo oficial do Vyron:
/// - Desktop/Tablet (>= 960px): Sidebar fixa lateral 248px + Top Header + Área principal.
/// - Mobile (< 960px): Drawer completo + Top Header + Barra inferior de 5 destinos.
class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.child,
    required this.onNavigateModule,
  });

  final Widget child;
  final ValueChanged<NavModule> onNavigateModule;

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateAndCloseDrawer(NavModule module) {
    widget.onNavigateModule(module);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  List<String> _buildBreadcrumbs(
    VyronAppState appState,
    UiLanguage lang,
  ) {
    final items = <String>[
      translate(lang, moduleLabelKey(appState.activeModule)),
    ];
    final domain = appState.domain;

    if (appState.activeModule == NavModule.brands &&
        appState.selectedBrandId != null) {
      for (final b in domain.brands) {
        if (b.id == appState.selectedBrandId) {
          items.add(b.name);
          break;
        }
      }
    } else if (appState.activeModule == NavModule.products &&
        appState.selectedProductId != null) {
      for (final p in domain.products) {
        if (p.id == appState.selectedProductId) {
          items.add(localizeProduct(p, lang).name);
          break;
        }
      }
    } else if (appState.activeModule == NavModule.content &&
        appState.contentSubView == ContentSubView.calendar) {
      items.add(translate(lang, 'nav.breadcrumb.editorialCalendar'));
    } else if (appState.activeModule == NavModule.automations &&
        appState.selectedAutomationId != null) {
      for (final a in domain.automations) {
        if (a.id == appState.selectedAutomationId) {
          items.add(localizeAgent(a, lang).name);
          break;
        }
      }
    }

    return items;
  }

  Future<void> _openControlModal(
    SystemControlModalMode mode,
    UiLanguage lang,
    String ownerName,
  ) async {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    await showSystemControlModal(
      context: context,
      mode: mode,
      language: lang,
      initialActor: ownerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 960;
    final showBrandInHeader = width >= 720;

    final unreadCount = domain.notifications.where((n) => !n.read).length;
    final pendingApprovals = domain.automations.fold<int>(
      0,
      (sum, a) => sum + a.pendingApprovalCount,
    );
    final isHalted = domain.systemControl.state == SystemControlStatus.halted;
    final breadcrumbs = _buildBreadcrumbs(appState, lang);

    final sidebar = _VyronSidebarContent(
      activeModule: appState.activeModule,
      language: lang,
      settings: domain.settings,
      systemControl: domain.systemControl,
      unreadCount: unreadCount,
      pendingApprovals: pendingApprovals,
      showCloseButton: !isWide,
      onCloseDrawer: () => Navigator.of(context).pop(),
      onSelectModule: _navigateAndCloseDrawer,
      onOpenControlModal: (mode) => _openControlModal(
        mode,
        lang,
        domain.settings.ownerName,
      ),
      onLock: () {
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.of(context).pop();
        }
        ref.read(vyronAccessProvider.notifier).lock(LockReason.manual);
      },
      onLogout: () {
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.of(context).pop();
        }
        ref.read(vyronAccessProvider.notifier).logout();
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.background,
      drawer: isWide
          ? null
          : Drawer(
              width: 268,
              backgroundColor: palette.sidebarBackground,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: SafeArea(child: sidebar),
            ),
      bottomNavigationBar: isWide
          ? null
          : _VyronMobileBottomNav(
              activeModule: appState.activeModule,
              language: lang,
              onSelectModule: widget.onNavigateModule,
              onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isWide)
              SizedBox(
                width: 248,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.sidebarBackground,
                    border: Border(
                      right: BorderSide(color: palette.panelBorder),
                    ),
                  ),
                  child: sidebar,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VyronTopHeader(
                    isWide: isWide,
                    showBrandInHeader: showBrandInHeader,
                    breadcrumbs: breadcrumbs,
                    brands: domain.brands,
                    globalBrandFilter: appState.globalBrandFilter,
                    globalPeriodFilter: appState.globalPeriodFilter,
                    themeMode: domain.settings.theme,
                    language: lang,
                    ownerName: domain.settings.ownerName,
                    unreadCount: unreadCount,
                    onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                    onNavigateRootModule: () =>
                        widget.onNavigateModule(appState.activeModule),
                    onBrandChanged: (id) => ref
                        .read(vyronStateProvider.notifier)
                        .setGlobalBrandFilter(id),
                    onPeriodChanged: (p) => ref
                        .read(vyronStateProvider.notifier)
                        .setGlobalPeriodFilter(p),
                    onToggleTheme: () =>
                        ref.read(vyronStateProvider.notifier).toggleTheme(),
                    onOpenNotifications: () =>
                        widget.onNavigateModule(NavModule.notifications),
                    onLock: () => ref
                        .read(vyronAccessProvider.notifier)
                        .lock(LockReason.manual),
                    onOpenSettings: () =>
                        widget.onNavigateModule(NavModule.settings),
                    onLogout: () =>
                        ref.read(vyronAccessProvider.notifier).logout(),
                  ),
                  if (!showBrandInHeader)
                    _MobileBrandFilterBar(
                      brands: domain.brands,
                      globalBrandFilter: appState.globalBrandFilter,
                      language: lang,
                      onBrandChanged: (id) => ref
                          .read(vyronStateProvider.notifier)
                          .setGlobalBrandFilter(id),
                    ),
                  if (isHalted)
                    _HaltedSystemBanner(
                      reason: localizeSystemControlReason(
                        domain.systemControl.reason,
                        lang,
                      ),
                      language: lang,
                      onResumeTap: () => _openControlModal(
                        SystemControlModalMode.resume,
                        lang,
                        domain.settings.ownerName,
                      ),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VyronSidebarContent extends StatelessWidget {
  const _VyronSidebarContent({
    required this.activeModule,
    required this.language,
    required this.settings,
    required this.systemControl,
    required this.unreadCount,
    required this.pendingApprovals,
    required this.showCloseButton,
    required this.onCloseDrawer,
    required this.onSelectModule,
    required this.onOpenControlModal,
    required this.onLock,
    required this.onLogout,
  });

  final NavModule activeModule;
  final UiLanguage language;
  final OwnerSettings settings;
  final SystemControlState systemControl;
  final int unreadCount;
  final int pendingApprovals;
  final bool showCloseButton;
  final VoidCallback onCloseDrawer;
  final ValueChanged<NavModule> onSelectModule;
  final ValueChanged<SystemControlModalMode> onOpenControlModal;
  final VoidCallback onLock;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHalted = systemControl.state == SystemControlStatus.halted;

    final statusColor = isHalted
        ? (isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText)
        : (isDark
            ? VyronColors.emeraldDarkText
            : VyronColors.emeraldLightText);
    final statusDotColor =
        isHalted ? VyronColors.crimsonDarkText : VyronColors.emerald;

    return ColoredBox(
      color: palette.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: palette.panelBorder),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => onSelectModule(NavModule.overview),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const VyronWordmark(
                      markSize: 22,
                      fontSize: 13,
                      variant: VyronMarkVariant.cobalt,
                    ),
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    tooltip: translate(language, 'nav.closeNavAria'),
                    onPressed: onCloseDrawer,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              children: [
                for (var gIdx = 0; gIdx < _navGroups.length; gIdx++) ...[
                  if (gIdx > 0) const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Text(
                      translate(language, _navGroups[gIdx].labelKey),
                      style: TextStyle(
                        fontFamily: VyronTypography.sans,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  for (final item in _navGroups[gIdx].items)
                    _SidebarNavTile(
                      key: Key('vyron-nav-${item.module.wire}'),
                      icon: item.icon,
                      label: translate(language, item.labelKey),
                      active: activeModule == item.module,
                      count: item.module == NavModule.notifications &&
                              unreadCount > 0
                          ? unreadCount
                          : item.module == NavModule.automations &&
                                  pendingApprovals > 0
                              ? pendingApprovals
                              : null,
                      onTap: () => onSelectModule(item.module),
                    ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: palette.panelBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        translate(language, 'controls.title'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: palette.textMuted.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          translate(
                            language,
                            isHalted
                                ? 'controls.statusHalted'
                                : 'controls.statusActive',
                          ),
                          key: const Key('vyron-system-status-label'),
                          style: TextStyle(
                            fontFamily: VyronTypography.sans,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: isHalted
                      ? ElevatedButton.icon(
                          key: const Key('vyron-resume-system-btn'),
                          onPressed: () =>
                              onOpenControlModal(SystemControlModalMode.resume),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VyronColors.graphite,
                            foregroundColor: VyronColors.coolWhite,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(
                            Icons.gpp_maybe_outlined,
                            size: 15,
                            color: VyronColors.crimsonDarkText,
                          ),
                          label: Text(
                            translate(language, 'controls.resumeSystem'),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          key: const Key('vyron-stop-all-btn'),
                          onPressed: () =>
                              onOpenControlModal(SystemControlModalMode.halt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? VyronColors.crimson
                                : VyronColors.crimsonLightButton,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: VyronColors.crimsonDarkText
                                  .withValues(alpha: 0.25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.gpp_maybe_outlined, size: 15),
                          label: Text(
                            translate(language, 'controls.stopAll'),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        translate(
                          language,
                          systemControl.phaseBPublicAllowed
                              ? 'common.publicOp'
                              : 'common.privateEnv',
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      settings.baseCurrency.wire,
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: palette.panelBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.ownerName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: VyronTypography.sans,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              translate(language, 'common.owner'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: VyronTypography.sans,
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SidebarSquareAction(
                        key: const Key('vyron-sidebar-lock-btn'),
                        icon: Icons.lock_outline_rounded,
                        tooltip: translate(language, 'nav.lockTooltip'),
                        onTap: onLock,
                      ),
                      const SizedBox(width: 6),
                      _SidebarSquareAction(
                        key: const Key('vyron-sidebar-logout-btn'),
                        icon: Icons.logout_rounded,
                        tooltip: translate(language, 'nav.logoutTooltip'),
                        danger: true,
                        onTap: onLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = active
        ? VyronColors.electricCobalt.withValues(alpha: isDark ? 0.2 : 0.12)
        : Colors.transparent;
    final fgColor = active ? palette.cobaltText : palette.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 17, color: fgColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: VyronTypography.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: fgColor,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.cobaltText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSquareAction extends StatelessWidget {
  const _SidebarSquareAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = danger
        ? (isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText)
        : palette.textMuted;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.panelBorder),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
      ),
    );
  }
}

class _VyronTopHeader extends StatelessWidget {
  const _VyronTopHeader({
    required this.isWide,
    required this.showBrandInHeader,
    required this.breadcrumbs,
    required this.brands,
    required this.globalBrandFilter,
    required this.globalPeriodFilter,
    required this.themeMode,
    required this.language,
    required this.ownerName,
    required this.unreadCount,
    required this.onOpenDrawer,
    required this.onNavigateRootModule,
    required this.onBrandChanged,
    required this.onPeriodChanged,
    required this.onToggleTheme,
    required this.onOpenNotifications,
    required this.onLock,
    required this.onOpenSettings,
    required this.onLogout,
  });

  final bool isWide;
  final bool showBrandInHeader;
  final List<String> breadcrumbs;
  final List<Brand> brands;
  final String globalBrandFilter;
  final PeriodFilter globalPeriodFilter;
  final VyronThemeMode themeMode;
  final UiLanguage language;
  final String ownerName;
  final int unreadCount;
  final VoidCallback onOpenDrawer;
  final VoidCallback onNavigateRootModule;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<PeriodFilter> onPeriodChanged;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLock;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = themeMode == VyronThemeMode.dark;
    final showThemeText = MediaQuery.sizeOf(context).width >= 600;
    final showOwnerName = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 12),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          bottom: BorderSide(color: palette.panelBorder),
        ),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            IconButton(
              key: const Key('vyron-open-drawer-btn'),
              tooltip: translate(language, 'nav.openNavAria'),
              onPressed: onOpenDrawer,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.menu_rounded,
                size: 20,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: _BreadcrumbBar(
              showPrefix: MediaQuery.sizeOf(context).width >= 600,
              items: breadcrumbs,
              onTapFirst: onNavigateRootModule,
            ),
          ),
          const SizedBox(width: 8),
          if (showBrandInHeader) ...[
            _BrandDropdownBox(
              brands: brands,
              selectedBrandId: globalBrandFilter,
              language: language,
              onChanged: onBrandChanged,
            ),
            const SizedBox(width: 8),
          ],
          _PeriodDropdownBox(
            selected: globalPeriodFilter,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(width: 6),
          _HeaderPillButton(
            key: const Key('vyron-theme-toggle-btn'),
            tooltip: translate(
              language,
              isDark ? 'nav.theme.toLight' : 'nav.theme.toDark',
            ),
            onTap: onToggleTheme,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 15,
                  color: isDark
                      ? VyronColors.titanium
                      : VyronColors.graphite,
                ),
                if (showThemeText) ...[
                  const SizedBox(width: 6),
                  Text(
                    translate(
                      language,
                      isDark ? 'nav.theme.light' : 'nav.theme.dark',
                    ),
                    style: TextStyle(
                      fontFamily: VyronTypography.sans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          _HeaderPillButton(
            key: const Key('vyron-header-notifications-btn'),
            tooltip: translate(
              language,
              'nav.notificationsAria',
              {'count': unreadCount},
            ),
            onTap: onOpenNotifications,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 15,
                  color: palette.textPrimary,
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$unreadCount',
                    style: TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.cobaltText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<_OwnerMenuAction>(
            key: const Key('vyron-owner-menu-btn'),
            tooltip: translate(
              language,
              'nav.ownerMenuAria',
              {'name': ownerName},
            ),
            color: palette.surface,
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: palette.border),
            ),
            onSelected: (action) {
              switch (action) {
                case _OwnerMenuAction.lock:
                  onLock();
                case _OwnerMenuAction.settings:
                  onOpenSettings();
                case _OwnerMenuAction.logout:
                  onLogout();
              }
            },
            itemBuilder: (menuContext) {
              final menuDark =
                  Theme.of(menuContext).brightness == Brightness.dark;
              final dangerColor = menuDark
                  ? VyronColors.crimsonDarkText
                  : VyronColors.crimsonLightText;
              return [
                PopupMenuItem<_OwnerMenuAction>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        translate(language, 'nav.ownerEnv'),
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<_OwnerMenuAction>(
                  value: _OwnerMenuAction.lock,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: VyronColors.electricCobalt,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        translate(language, 'nav.lockVyron'),
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 12,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<_OwnerMenuAction>(
                  value: _OwnerMenuAction.settings,
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 15,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        translate(language, 'nav.preferencesAccess'),
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 12,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<_OwnerMenuAction>(
                  value: _OwnerMenuAction.logout,
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 15, color: dangerColor),
                      const SizedBox(width: 8),
                      Text(
                        translate(language, 'nav.logout'),
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 12,
                          color: dangerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.panelBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: VyronColors.electricCobalt,
                  ),
                  if (showOwnerName) ...[
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        ownerName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    required this.showPrefix,
    required this.items,
    required this.onTapFirst,
  });

  final bool showPrefix;
  final List<String> items;
  final VoidCallback onTapFirst;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Row(
      children: [
        if (showPrefix) ...[
          Text(
            'Vyron',
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 13,
              color: palette.textMuted,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: palette.textMuted,
          ),
        ],
        Flexible(
          child: items.length > 1
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showPrefix) ...[
                      InkWell(
                        onTap: onTapFirst,
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          items.first,
                          style: TextStyle(
                            fontFamily: VyronTypography.sans,
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: palette.textMuted,
                      ),
                    ],
                    Flexible(
                      child: Text(
                        items.last,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  items.first,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: VyronTypography.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MobileBrandFilterBar extends StatelessWidget {
  const _MobileBrandFilterBar({
    required this.brands,
    required this.globalBrandFilter,
    required this.language,
    required this.onBrandChanged,
  });

  final List<Brand> brands;
  final String globalBrandFilter;
  final UiLanguage language;
  final ValueChanged<String> onBrandChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          bottom: BorderSide(color: palette.panelBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 15,
            color: palette.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BrandDropdownBox(
              brands: brands,
              selectedBrandId: globalBrandFilter,
              language: language,
              expanded: true,
              onChanged: onBrandChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandDropdownBox extends StatelessWidget {
  const _BrandDropdownBox({
    required this.brands,
    required this.selectedBrandId,
    required this.language,
    required this.onChanged,
    this.expanded = false,
  });

  final List<Brand> brands;
  final String selectedBrandId;
  final UiLanguage language;
  final ValueChanged<String> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final hasMatch = selectedBrandId == 'all' ||
        brands.any((b) => b.id == selectedBrandId);
    final effectiveValue = hasMatch ? selectedBrandId : 'all';

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.panelBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('vyron-global-brand-select'),
          value: effectiveValue,
          isDense: true,
          isExpanded: expanded,
          dropdownColor: palette.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: palette.textMuted,
          ),
          style: TextStyle(
            fontFamily: VyronTypography.sans,
            fontSize: 12,
            color: palette.textPrimary,
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'all',
              child: Text(
                translate(language, 'nav.allBrands'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final brand in brands)
              DropdownMenuItem<String>(
                value: brand.id,
                child: Text(
                  brand.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _PeriodDropdownBox extends StatelessWidget {
  const _PeriodDropdownBox({
    required this.selected,
    required this.onChanged,
  });

  final PeriodFilter selected;
  final ValueChanged<PeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.panelBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PeriodFilter>(
          key: const Key('vyron-global-period-select'),
          value: selected,
          isDense: true,
          dropdownColor: palette.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 15,
            color: palette.textMuted,
          ),
          style: TextStyle(
            fontFamily: VyronTypography.mono,
            fontSize: 12,
            color: palette.textPrimary,
          ),
          items: [
            for (final period in PeriodFilter.values)
              DropdownMenuItem<PeriodFilter>(
                value: period,
                child: Text(period.wire),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _HeaderPillButton extends StatelessWidget {
  const _HeaderPillButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.panelBorder),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _HaltedSystemBanner extends StatelessWidget {
  const _HaltedSystemBanner({
    required this.reason,
    required this.language,
    required this.onResumeTap,
  });

  final String reason;
  final UiLanguage language;
  final VoidCallback onResumeTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText;

    return Container(
      key: const Key('vyron-halted-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: VyronColors.crimson.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: VyronColors.crimson.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gpp_maybe_outlined,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  translate(
                    language,
                    'controls.haltedBanner',
                    {'reason': reason},
                  ),
                  style: TextStyle(
                    fontFamily: VyronTypography.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            key: const Key('vyron-halted-banner-resume-btn'),
            onPressed: onResumeTap,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? VyronColors.crimson : VyronColors.crimsonLightButton,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              translate(language, 'controls.resumeSystem'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _VyronMobileBottomNav extends StatelessWidget {
  const _VyronMobileBottomNav({
    required this.activeModule,
    required this.language,
    required this.onSelectModule,
    required this.onOpenMenu,
  });

  final NavModule activeModule;
  final UiLanguage language;
  final ValueChanged<NavModule> onSelectModule;
  final VoidCallback onOpenMenu;

  int get _selectedIndex {
    return switch (activeModule) {
      NavModule.overview => 0,
      NavModule.products => 1,
      NavModule.content => 2,
      NavModule.finance => 3,
      _ => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final en = language == UiLanguage.enUS;

    return Container(
      decoration: BoxDecoration(
        color: palette.sidebarBackground,
        border: Border(
          top: BorderSide(color: palette.panelBorder),
        ),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: palette.sidebarBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VyronColors.electricCobalt.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              onSelectModule(NavModule.overview);
            case 1:
              onSelectModule(NavModule.products);
            case 2:
              onSelectModule(NavModule.content);
            case 3:
              onSelectModule(NavModule.finance);
            case 4:
              onOpenMenu();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined, size: 20),
            selectedIcon: const Icon(
              Icons.dashboard_rounded,
              size: 20,
              color: VyronColors.electricCobalt,
            ),
            label: translate(language, 'nav.overview'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined, size: 20),
            selectedIcon: const Icon(
              Icons.inventory_2_rounded,
              size: 20,
              color: VyronColors.electricCobalt,
            ),
            label: en ? 'Products' : 'Produtos',
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined, size: 20),
            selectedIcon: const Icon(
              Icons.description_rounded,
              size: 20,
              color: VyronColors.electricCobalt,
            ),
            label: en ? 'Content' : 'Conteúdo',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            selectedIcon: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 20,
              color: VyronColors.electricCobalt,
            ),
            label: translate(language, 'nav.finance'),
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_rounded, size: 20),
            selectedIcon: Icon(
              Icons.menu_rounded,
              size: 20,
              color: VyronColors.electricCobalt,
            ),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
