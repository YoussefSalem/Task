import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/otp_verify_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/call/call_controller.dart';
import '../features/call/call_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/messages_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/earnings/earnings_screen.dart';
import '../features/home/tech_shell.dart';
import '../features/jobs/active_job_screen.dart';
import '../features/jobs/job_detail_screen.dart';
import '../features/jobs/job_feed_screen.dart';
import '../features/jobs/map/jobs_map_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/delete_account.dart';
import '../features/profile/profile_screen.dart';
import '../features/reviews/reviews_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/support/help_support_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Application router. The entry funnel (splash → sign-in → OTP → onboarding)
/// sits above a bottom-nav shell (Dashboard · Jobs · Messages · Earnings); the
/// job journey pushes full-screen routes on top of the shell.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: SplashScreen.routePath,
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: SignInScreen.routePath,
        name: SignInScreen.routeName,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: OtpVerifyScreen.routePath,
        name: OtpVerifyScreen.routeName,
        builder: (context, state) => OtpVerifyScreen(
          phone: state.uri.queryParameters['phone'] ?? 'your phone',
        ),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Bottom-nav shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TechShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: TechShell.dashboardRoutePath,
                name: TechShell.dashboardRouteName,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: TechShell.jobsRoutePath,
                name: TechShell.jobsRouteName,
                builder: (context, state) => const JobFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: TechShell.messagesRoutePath,
                name: TechShell.messagesRouteName,
                builder: (context, state) => const MessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: TechShell.earningsRoutePath,
                name: TechShell.earningsRouteName,
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes above the shell.
      GoRoute(
        path: JobDetailScreen.routePath,
        name: JobDetailScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            JobDetailScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: ActiveJobScreen.routePath,
        name: ActiveJobScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            ActiveJobScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: JobsMapScreen.routePath,
        name: JobsMapScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const JobsMapScreen(),
      ),
      GoRoute(
        path: ChatScreen.routePath,
        name: ChatScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            ChatScreen(args: state.extra as ChatArgs),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: NotificationsScreen.routePath,
        name: NotificationsScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: ReviewsScreen.routePath,
        name: ReviewsScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ReviewsScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        name: SettingsScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: HelpSupportScreen.routePath,
        name: HelpSupportScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: LegalScreen.routePath,
        name: LegalScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => LegalScreen(
          kind: state.uri.queryParameters['kind'] ?? 'terms',
        ),
      ),
      GoRoute(
        path: DeleteAccountScreen.routePath,
        name: DeleteAccountScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: CallScreen.routePath,
        name: CallScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => CallScreen(args: state.extra as CallArgs),
      ),
    ],
  );
});
