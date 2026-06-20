import 'package:customer/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WelcomeScreen renders brand and primary CTA', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Task'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
