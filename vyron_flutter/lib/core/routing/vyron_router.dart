import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/state/vyron_access_notifier.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/security/vyron_access_rules.dart';
import '../../domain/models/vyron_enums.dart';
import '../../presentation/access/access_screen.dart';
import '../../presentation/analytics/analytics_screen.dart';
import '../../presentation/brands/brands_screen.dart';
import '../../presentation/channels/channels_screen.dart';
import '../../presentation/content/content_screen.dart';
import '../../presentation/overview/overview_screen.dart';
import '../../presentation/products/products_screen.dart';
import '../../presentation/shell/adaptive_shell.dart';
import '../../presentation/shell/module_placeholder_view.dart';

abstract final class VyronRoutes {
  static const String access = '/access';
  static const String overview = '/overview';
  static const String brands = '/brands';
  static const String products = '/products';
  static const String content = '/content';
  static const String channels = '/channels';
  static const String analytics = '/analytics';
  static const String finance = '/finance';
  static const String automations = '/automations';
  static const String activity = '/activity';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
}

String vyronModulePath(
  NavModule module, {
  String? entityId,
}) {
  final base = switch (module) {
    NavModule.overview => VyronRoutes.overview,
    NavModule.brands => VyronRoutes.brands,
    NavModule.products => VyronRoutes.products,
    NavModule.content => VyronRoutes.content,
    NavModule.channels => VyronRoutes.channels,
    NavModule.analytics => VyronRoutes.analytics,
    NavModule.finance => VyronRoutes.finance,
    NavModule.automations => VyronRoutes.automations,
    NavModule.activity => VyronRoutes.activity,
    NavModule.notifications => VyronRoutes.notifications,
    NavModule.settings => VyronRoutes.settings,
  };
  if (entityId != null && entityId.isNotEmpty) {
    return '$base/${Uri.encodeComponent(entityId)}';
  }
  return base;
}

class _VyronRouterNotifier extends ChangeNotifier {
  _VyronRouterNotifier(this._ref) {
    _previousSession = _ref.read(vyronAccessProvider).session;
    _subscription = _ref.listen<VyronAccessControllerState>(
      vyronAccessProvider,
      (prev, next) {
        final prevSession = prev?.session ?? _previousSession;
        final nextSession = next.session;
        _previousSession = nextSession;

        if (!nextSession.authenticated) {
          lastAuthorizedLocation = VyronRoutes.overview;
        }

        if ((prevSession.isAuthorized != nextSession.isAuthorized) ||
            (prevSession.locked != nextSession.locked) ||
            (prevSession.authenticated != nextSession.authenticated)) {
          if (!prevSession.authenticated && nextSession.isAuthorized) {
            lastAuthorizedLocation = VyronRoutes.overview;
          }
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;
  late VyronAccessSession _previousSession;
  late final ProviderSubscription<VyronAccessControllerState> _subscription;

  String lastAuthorizedLocation = VyronRoutes.overview;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final vyronRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _VyronRouterNotifier(ref);

  late final GoRouter router;
  router = GoRouter(
    initialLocation: VyronRoutes.overview,
    refreshListenable: notifier,
    redirect: (context, state) {
      final access = ref.read(vyronAccessProvider);
      final isAccessRoute = state.matchedLocation == VyronRoutes.access;

      if (!access.isAuthorized) {
        if (!isAccessRoute && access.session.locked) {
          final currentUri = state.uri.toString();
          if (currentUri.isNotEmpty && currentUri != VyronRoutes.access) {
            notifier.lastAuthorizedLocation = currentUri;
          }
        }
        return isAccessRoute ? null : VyronRoutes.access;
      }

      if (isAccessRoute) {
        return notifier.lastAuthorizedLocation;
      }

      notifier.lastAuthorizedLocation = state.uri.toString();
      return null;
    },
    routes: [
      GoRoute(
        path: VyronRoutes.access,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: AccessScreen(
            onUnlocked: ({required bool wasLocked}) {
              if (!wasLocked) {
                notifier.lastAuthorizedLocation = VyronRoutes.overview;
                ref
                    .read(vyronStateProvider.notifier)
                    .navigate(NavModule.overview);
              }
            },
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdaptiveShell(
            onNavigateModule: (module) {
              ref.read(vyronStateProvider.notifier).navigate(
                    module,
                    brandId: null,
                    setBrandId: module == NavModule.brands,
                    productId: null,
                    setProductId: module == NavModule.products,
                    contentId: null,
                    setContentId: module == NavModule.content,
                    automationId: null,
                    setAutomationId: module == NavModule.automations,
                  );
              final target = vyronModulePath(module);
              notifier.lastAuthorizedLocation = target;
              router.go(target);
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => VyronRoutes.overview,
          ),
          GoRoute(
            path: VyronRoutes.overview,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const OverviewScreen(),
            ),
          ),
          GoRoute(
            path: VyronRoutes.brands,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const BrandsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':brandId',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: BrandsScreen(
                    brandId: state.pathParameters['brandId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: VyronRoutes.products,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ProductsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':productId',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: ProductsScreen(
                    productId: state.pathParameters['productId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: VyronRoutes.content,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ContentScreen(),
            ),
            routes: [
              GoRoute(
                path: ':contentId',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: ContentScreen(
                    contentId: state.pathParameters['contentId'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: VyronRoutes.channels,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ChannelsScreen(),
            ),
          ),
          GoRoute(
            path: VyronRoutes.analytics,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: VyronRoutes.finance,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ModulePlaceholderView(module: NavModule.finance),
            ),
          ),
          GoRoute(
            path: VyronRoutes.automations,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ModulePlaceholderView(module: NavModule.automations),
            ),
            routes: [
              GoRoute(
                path: ':automationId',
                builder: (context, state) => ModulePlaceholderView(
                  module: NavModule.automations,
                  selectedEntityId: state.pathParameters['automationId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: VyronRoutes.activity,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ModulePlaceholderView(module: NavModule.activity),
            ),
          ),
          GoRoute(
            path: VyronRoutes.notifications,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ModulePlaceholderView(
                module: NavModule.notifications,
              ),
            ),
          ),
          GoRoute(
            path: VyronRoutes.settings,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const ModulePlaceholderView(module: NavModule.settings),
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

void navigateToVyronModule(
  WidgetRef ref,
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
  ref.read(vyronStateProvider.notifier).navigate(
        module,
        brandId: brandId,
        setBrandId: setBrandId,
        productId: productId,
        setProductId: setProductId,
        contentId: contentId,
        setContentId: setContentId,
        automationId: automationId,
        setAutomationId: setAutomationId,
        contentSubView: contentSubView,
      );

  final entityId = switch (module) {
    NavModule.brands => brandId,
    NavModule.products => productId,
    NavModule.content => contentId,
    NavModule.automations => automationId,
    _ => null,
  };
  final router = GoRouter.maybeOf(ref.context);
  if (router != null) {
    router.go(vyronModulePath(module, entityId: entityId));
  }
}
