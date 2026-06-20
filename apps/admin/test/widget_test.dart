import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/main.dart';

void main() {
  testWidgets('Admin skeleton boots', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const AdminApp());

    expect(find.text('Admin dashboard — Phase 3'), findsOneWidget);
  });
}
