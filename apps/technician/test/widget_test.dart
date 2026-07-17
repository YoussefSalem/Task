import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:technician/app/tech_theme.dart';

void main() {
  testWidgets('Teal theme builds and applies its accent', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: TechTheme.light,
        darkTheme: TechTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    // The technician app's brand is teal, not the customer's violet.
    expect(scheme.primary, const Color(0xFF2DD4BF));
    expect(scheme.brightness, Brightness.dark);
  });
}
