import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../notifications/push_messaging.dart';

/// The customer's notification choices. A master [pushEnabled] gate plus
/// per-category switches. Persisted locally for instant reads and mirrored to
/// the `users/{uid}` Firestore doc (under `notification_prefs`) so the push
/// fan-out Cloud Function can honour them server-side.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.pushEnabled = true,
    this.jobUpdates = true,
    this.offers = true,
    this.messages = true,
    this.promotions = true,
  });

  final bool pushEnabled;
  final bool jobUpdates;
  final bool offers;
  final bool messages;
  final bool promotions;

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? jobUpdates,
    bool? offers,
    bool? messages,
    bool? promotions,
  }) =>
      NotificationPrefs(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        jobUpdates: jobUpdates ?? this.jobUpdates,
        offers: offers ?? this.offers,
        messages: messages ?? this.messages,
        promotions: promotions ?? this.promotions,
      );

  Map<String, bool> toMap() => <String, bool>{
        'push_enabled': pushEnabled,
        'job_updates': jobUpdates,
        'offers': offers,
        'messages': messages,
        'promotions': promotions,
      };

  factory NotificationPrefs.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const NotificationPrefs();
    bool read(String k, bool fallback) =>
        m[k] is bool ? m[k] as bool : fallback;
    return NotificationPrefs(
      pushEnabled: read('push_enabled', true),
      jobUpdates: read('job_updates', true),
      offers: read('offers', true),
      messages: read('messages', true),
      promotions: read('promotions', true),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.pushEnabled == pushEnabled &&
      other.jobUpdates == jobUpdates &&
      other.offers == offers &&
      other.messages == messages &&
      other.promotions == promotions;

  @override
  int get hashCode =>
      Object.hash(pushEnabled, jobUpdates, offers, messages, promotions);
}

const String _kPrefKey = 'notification_prefs';

/// Loads, exposes and persists [NotificationPrefs]. Each setter writes through
/// to SharedPreferences immediately and best-effort mirrors the whole map to
/// the signed-in user's Firestore doc. Enabling the master switch also (re)runs
/// push registration so a previously-denied OS permission can be re-requested.
class NotificationPrefsController extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    _load();
    return const NotificationPrefs();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kPrefKey);
    if (raw == null) return;
    final Map<String, bool> map = <String, bool>{
      for (final String pair in raw.split(','))
        if (pair.contains('=')) pair.split('=').first: pair.endsWith('=1'),
    };
    state = NotificationPrefs.fromMap(map);
  }

  Future<void> _persist(NotificationPrefs next) async {
    state = next;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Compact "key=0/1" CSV — avoids pulling in a JSON codec for five bools.
    final String raw = next
        .toMap()
        .entries
        .map((MapEntry<String, bool> e) => '${e.key}=${e.value ? 1 : 0}')
        .join(',');
    await prefs.setString(_kPrefKey, raw);
    await _mirrorToFirestore(next);
  }

  Future<void> _mirrorToFirestore(NotificationPrefs next) async {
    final String? uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return; // Signed out / mock mode — local pref only.
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        <String, dynamic>{'notification_prefs': next.toMap()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Best-effort: the local pref is still authoritative for the UI.
    }
  }

  Future<void> setPushEnabled(bool value) async {
    await _persist(state.copyWith(pushEnabled: value));
    if (value && !kIsWeb) {
      // Re-run registration so a previously-denied OS permission re-prompts and
      // a token is registered for this device.
      final String? uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid != null) {
        await ref.read(pushMessagingProvider).registerFor(uid);
      }
    }
  }

  Future<void> setJobUpdates(bool v) =>
      _persist(state.copyWith(jobUpdates: v));
  Future<void> setOffers(bool v) => _persist(state.copyWith(offers: v));
  Future<void> setMessages(bool v) => _persist(state.copyWith(messages: v));
  Future<void> setPromotions(bool v) =>
      _persist(state.copyWith(promotions: v));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
        NotificationPrefsController.new);
