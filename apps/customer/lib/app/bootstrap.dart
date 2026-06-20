import 'package:customer/app/customer_app.dart';
import 'package:customer/app/flavor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single composition root for every flavor entrypoint.
///
/// Firebase is intentionally NOT initialised here yet: it requires a real
/// project's `firebase_options.dart` produced by `flutterfire configure`, which
/// is wired in the Auth phase. The foundation runs without it so the design
/// system, routing, and RTL can be verified first.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(auth-phase): initialise Firebase + App Check here once
  // `flutterfire configure` has generated firebase_options.dart for this flavor.

  runApp(
    ProviderScope(
      observers: const <ProviderObserver>[],
      child: CustomerApp(flavor: flavor),
    ),
  );
}
