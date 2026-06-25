import 'package:customer/app/flavor.dart';
import 'package:customer/app/router.dart';
import 'package:customer/features/localization/locale_controller.dart';
import 'package:customer/features/settings/theme_controller.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

/// Root widget. Supports light, dark, and system-default themes (Material 3).
/// Language defaults to English; Arabic flips to RTL automatically.
class CustomerApp extends ConsumerWidget {
  const CustomerApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: flavor.appTitle,
      debugShowCheckedModeBanner: !flavor.isProd,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Instant theme switch — the frosted-glass + gradient surfaces are
      // expensive to crossfade, which made the default animation feel sluggish.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
