import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:technician/app/flavor.dart';
import 'package:technician/app/router.dart';
import 'package:technician/app/tech_theme.dart';
import 'package:technician/features/auth/auth_controller.dart';
import 'package:technician/features/notifications/push_messaging.dart';
import 'package:technician/features/settings/theme_controller.dart';

/// Root widget for the Technician app. Light + dark (Material 3), teal brand.
class TechnicianApp extends ConsumerStatefulWidget {
  const TechnicianApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  ConsumerState<TechnicianApp> createState() => _TechnicianAppState();
}

class _TechnicianAppState extends ConsumerState<TechnicianApp> {
  // Last-seen signed-in uid, so we (un)register push tokens only on an actual
  // sign-in/sign-out transition rather than on every auth stream tick.
  String? _pushUid;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Drive FCM token registration off the auth lifecycle, above the router so
    // it runs for the whole session regardless of the visible route.
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      _syncPush(next.valueOrNull?.uid as String?);
    });

    return MaterialApp.router(
      title: widget.flavor.appTitle,
      debugShowCheckedModeBanner: !widget.flavor.isProd,
      theme: TechTheme.light,
      darkTheme: TechTheme.dark,
      themeMode: themeMode,
      // Instant theme switch — the frosted/gradient surfaces are expensive to
      // crossfade, which makes the default animation feel sluggish.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
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
