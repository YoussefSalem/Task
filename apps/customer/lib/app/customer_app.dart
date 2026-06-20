import 'package:customer/app/flavor.dart';
import 'package:customer/app/router.dart';
import 'package:customer/features/localization/locale_controller.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

/// Root widget. Dark-only Material 3. Defaults to English; the language can be
/// switched anywhere via [localeControllerProvider], and Arabic flips to RTL
/// automatically.
class CustomerApp extends ConsumerWidget {
  const CustomerApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: flavor.appTitle,
      debugShowCheckedModeBanner: !flavor.isProd,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
