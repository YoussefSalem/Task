import 'package:customer/features/welcome/welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Application router. Routes are registered per feature as phases land;
/// for the foundation there is a single welcome route.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: WelcomeScreen.routePath,
    routes: <RouteBase>[
      GoRoute(
        path: WelcomeScreen.routePath,
        name: WelcomeScreen.routeName,
        builder: (context, state) => const WelcomeScreen(),
      ),
    ],
  );
});
