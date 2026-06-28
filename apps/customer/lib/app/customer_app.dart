import 'package:customer/app/flavor.dart';
import 'package:customer/app/router.dart';
import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/localization/locale_controller.dart';
import 'package:customer/features/notifications/push_messaging.dart';
import 'package:customer/features/settings/theme_controller.dart';
import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_design/task_design.dart';

/// Root widget. Supports light, dark, and system-default themes (Material 3).
/// Language defaults to English; Arabic flips to RTL automatically.
class CustomerApp extends ConsumerStatefulWidget {
  const CustomerApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  ConsumerState<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends ConsumerState<CustomerApp> {
  // Tracks the last-seen signed-in uid so we only (un)register push tokens on
  // an actual sign-in/sign-out transition, not on every auth stream tick.
  String? _pushUid;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Drive FCM token registration off the auth lifecycle. Kept here (above the
    // router) so it runs for the whole session regardless of the visible route.
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      _syncPush(next.valueOrNull?.uid as String?);
    });

    return MaterialApp.router(
      title: widget.flavor.appTitle,
      debugShowCheckedModeBanner: !widget.flavor.isProd,
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

  void _syncPush(String? uid) {
    if (uid == _pushUid) return;
    final PushMessaging push = ref.read(pushMessagingProvider);
    if (uid != null) {
      _pushUid = uid;
      push.registerFor(uid);
    } else {
      _pushUid = null;
      push.unregister();
    }
  }
}
