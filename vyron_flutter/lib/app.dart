import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/lifecycle/vyron_lifecycle_observer.dart';
import 'application/state/vyron_state_notifier.dart';
import 'core/routing/vyron_router.dart';
import 'core/theme/vyron_theme.dart';
import 'domain/models/vyron_enums.dart';

class VyronBootstrapApp extends ConsumerWidget {
  const VyronBootstrapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vyronTheme = ref.watch(
      vyronStateProvider.select((s) => s.domain.settings.theme),
    );
    final router = ref.watch(vyronRouterProvider);
    final themeMode = vyronTheme == VyronThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return VyronLifecycleObserver(
      child: MaterialApp.router(
        title: 'Vyron',
        debugShowCheckedModeBanner: false,
        theme: VyronTheme.light(),
        darkTheme: VyronTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
