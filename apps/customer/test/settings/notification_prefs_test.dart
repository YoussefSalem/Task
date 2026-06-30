import 'package:customer/features/settings/notification_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPrefs', () {
    test('defaults to everything enabled', () {
      const NotificationPrefs prefs = NotificationPrefs();
      expect(prefs.pushEnabled, isTrue);
      expect(prefs.jobUpdates, isTrue);
      expect(prefs.offers, isTrue);
      expect(prefs.messages, isTrue);
      expect(prefs.promotions, isTrue);
    });

    test('toMap/fromMap round-trips every field', () {
      const NotificationPrefs prefs = NotificationPrefs(
        pushEnabled: false,
        jobUpdates: true,
        offers: false,
        messages: true,
        promotions: false,
      );
      final NotificationPrefs restored =
          NotificationPrefs.fromMap(prefs.toMap());
      expect(restored, prefs);
    });

    test('fromMap falls back to enabled for missing keys', () {
      final NotificationPrefs prefs =
          NotificationPrefs.fromMap(<String, dynamic>{'offers': false});
      expect(prefs.offers, isFalse);
      expect(prefs.pushEnabled, isTrue);
      expect(prefs.messages, isTrue);
    });

    test('fromMap ignores non-bool values', () {
      final NotificationPrefs prefs = NotificationPrefs.fromMap(
          <String, dynamic>{'push_enabled': 'nope', 'messages': 0});
      expect(prefs.pushEnabled, isTrue);
      expect(prefs.messages, isTrue);
    });

    test('fromMap on null returns defaults', () {
      expect(NotificationPrefs.fromMap(null), const NotificationPrefs());
    });

    test('copyWith changes only the named field', () {
      const NotificationPrefs prefs = NotificationPrefs();
      final NotificationPrefs next = prefs.copyWith(promotions: false);
      expect(next.promotions, isFalse);
      expect(next.pushEnabled, isTrue);
      expect(next.jobUpdates, isTrue);
    });
  });
}
