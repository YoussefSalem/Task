import 'package:customer/app/customer_app.dart';
import 'package:customer/app/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget fullApp() =>
      const ProviderScope(child: CustomerApp(flavor: Flavor.dev));

  testWidgets('Splash shows the Task wordmark and no Get Started CTA',
      (tester) async {
    await tester.pumpWidget(fullApp());
    await tester.pump(); // first frame

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('Splash auto-routes unauthenticated users to sign-in',
      (tester) async {
    await tester.pumpWidget(fullApp());
    await tester.pump(); // resolve providers + first frame

    // Advance past the minimum dwell and the exit fade.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(); // let go_router build the destination

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
  });
}
