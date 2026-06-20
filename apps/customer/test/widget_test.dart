import 'package:customer/app/customer_app.dart';
import 'package:customer/app/flavor.dart';
import 'package:customer/features/splash/splash_screen.dart';
import 'package:customer/l10n/app_localizations.dart';
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

  Widget wrapSplash(Locale locale) => ProviderScope(
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SplashScreen(),
        ),
      );

  Widget fullApp() =>
      const ProviderScope(child: CustomerApp(flavor: Flavor.dev));

  testWidgets('Splash shows wordmark and English CTA', (tester) async {
    await tester.pumpWidget(wrapSplash(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Splash localizes the CTA into Arabic', (tester) async {
    await tester.pumpWidget(wrapSplash(const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('ابدأ الآن'), findsOneWidget);
  });

  testWidgets('Get started navigates to the sign-in screen', (tester) async {
    await tester.pumpWidget(fullApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
  });
}
