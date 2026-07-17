import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_design/task_design.dart';

import '../../app/tech_colors.dart';
import '../../widgets/tech_ambient.dart';
import '../auth/auth_controller.dart';
import '../auth/sign_in_screen.dart';
import '../home/tech_shell.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/technician_profile.dart';

/// The routing brain. Waits for the auth stream to settle, then sends the pro to
/// sign-in, onboarding, or the dashboard. Also seeds the `users/{uid}` doc so a
/// social sign-in lands with `role: technician`.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _routed = false;

  Future<void> _decide(User? user) async {
    if (_routed) return;
    _routed = true;
    if (user == null) {
      if (mounted) context.goNamed(SignInScreen.routeName);
      return;
    }
    // Best-effort: make sure a technician doc exists before gating on it.
    try {
      await seedTechnicianDocument(user);
    } catch (_) {}
    final bool complete = await hasCompletedTechnicianProfile(user.uid)
        .catchError((_) => false);
    if (!mounted) return;
    context.goNamed(
      complete ? TechShell.dashboardRouteName : OnboardingScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to the very first settled auth value.
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      next.whenData((user) {
        if (!_routed) _decide(user);
      });
    });
    // Handle the case where the value is already available on first build.
    final authAsync = ref.read(authStateProvider);
    authAsync.whenData((user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_routed) _decide(user);
      });
    });

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: TechAmbient(intensity: 0.22)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: TechColors.accent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: TechColors.accentBright.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: -2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.handyman_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
