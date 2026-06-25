import 'package:customer/features/address/address_screen.dart';
import 'package:customer/features/call/call_controller.dart';
import 'package:customer/features/call/call_screen.dart';
import 'package:customer/features/assistant/ai_chat_screen.dart';
import 'package:customer/features/auth/complete_profile_screen.dart';
import 'package:customer/features/auth/otp_verify_screen.dart';
import 'package:customer/features/auth/sign_in_screen.dart';
import 'package:customer/features/booking/asap_dispatch_screen.dart';
import 'package:customer/features/chat/chat_screen.dart';
import 'package:customer/features/location/pick_location_screen.dart';
import 'package:customer/features/matching/matching_screen.dart';
import 'package:customer/features/marketplace/all_services_screen.dart';
import 'package:customer/features/marketplace/job_create_stub_screen.dart';
import 'package:customer/features/offers/offers_screen.dart';
import 'package:customer/features/booking/quote_bids_screen.dart';
import 'package:customer/features/bookings/bookings_screen.dart';
import 'package:customer/features/home/home_screen.dart';
import 'package:customer/features/home/home_shell.dart';
import 'package:customer/features/job/job_tracking_screen.dart';
import 'package:customer/features/payment/payment_screen.dart';
import 'package:customer/features/profile/profile_screen.dart';
import 'package:customer/features/review/rating_screen.dart';
import 'package:customer/features/splash/splash_screen.dart';
import 'package:customer/features/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Application router. The entry funnel (splash → sign-in → OTP) sits above a
/// bottom-nav shell (Explore / Bookings / Profile); the booking journey pushes
/// full-screen routes on top of the shell.
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
        path: CompleteProfileScreen.routePath,
        name: CompleteProfileScreen.routeName,
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // Bottom-nav shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: <RouteBase>[
              GoRoute(
                path: HomeShell.homeRoutePath,
                name: HomeShell.homeRouteName,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomeShell.jobsRoutePath,
                name: HomeShell.jobsRouteName,
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomeShell.messagesRoutePath,
                name: HomeShell.messagesRouteName,
                builder: (context, state) => const MessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomeShell.profileRoutePath,
                name: HomeShell.profileRouteName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Booking journey (full-screen, above the shell).
      GoRoute(
        path: AllServicesScreen.routePath,
        name: AllServicesScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AllServicesScreen(),
      ),
      GoRoute(
        path: JobCreateStubScreen.routePath,
        name: JobCreateStubScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const JobCreateStubScreen(),
      ),
      GoRoute(
        path: AddressScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: AsapDispatchScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AsapDispatchScreen(),
      ),
      GoRoute(
        path: QuoteBidsScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const QuoteBidsScreen(),
      ),
      GoRoute(
        path: JobTrackingScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const JobTrackingScreen(),
      ),
      GoRoute(
        path: RatingScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const RatingScreen(),
      ),
      GoRoute(
        path: PaymentScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => PaymentScreen(
          settle: state.uri.queryParameters['stage'] == 'settle',
        ),
      ),
      GoRoute(
        path: AiChatScreen.routePath,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => AiChatScreen(
          initialMessage: state.extra as String?,
        ),
      ),
      GoRoute(
        path: PickLocationScreen.routePath,
        name: PickLocationScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const PickLocationScreen(),
      ),
      GoRoute(
        path: MatchingScreen.routePath,
        name: MatchingScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => MatchingScreen(
          jobId: state.uri.queryParameters['jobId'],
        ),
      ),
      GoRoute(
        path: OffersScreen.routePath,
        name: OffersScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const OffersScreen(),
      ),
      GoRoute(
        path: ChatScreen.routePath,
        name: ChatScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final args = state.extra as ChatArgs;
          return ChatScreen(
            technicianId: args.technicianId,
            technicianName: args.technicianName,
          );
        },
      ),
      GoRoute(
        path: CallScreen.routePath,
        name: CallScreen.routeName,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final args = state.extra as CallArgs;
          return CallScreen(args: args);
        },
      ),
    ],
  );
});
