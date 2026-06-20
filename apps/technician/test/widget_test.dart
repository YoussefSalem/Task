import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:technician/main.dart';

void main() {
  testWidgets('Technician skeleton boots', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const TechnicianApp());

    expect(find.text('Technician app — Phase 2'), findsOneWidget);
  });
}
