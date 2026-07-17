import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../auth/auth_controller.dart';

/// The signed-in technician's profile, merged from `users/{uid}` with Firebase
/// Auth fallbacks. Mirrors the public [TechnicianProfile] the customer directory
/// reads, plus private fields the pro manages (phone, availability).
@immutable
class TechProfile {
  const TechProfile({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.email = '',
    this.primaryCategory,
    this.rating = 0,
    this.jobsDone = 0,
    this.tier = TechnicianTier.bronze,
    this.available = false,
    this.photoUrl,
    this.bio = '',
    this.serviceArea = '',
    this.kycStatus = KycStatus.applied,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String email;

  /// The pro's main service line. Null until onboarding is completed.
  final JobCategory? primaryCategory;
  final double rating;
  final int jobsDone;
  final TechnicianTier tier;

  /// Whether the pro is currently accepting jobs (drives the online toggle).
  final bool available;
  final String? photoUrl;

  /// Short "about me" blurb shown to customers.
  final String bio;

  /// The area the pro covers, e.g. "Nasr City & New Cairo".
  final String serviceArea;

  /// Verification lifecycle. New pros start [KycStatus.applied]; a backend/admin
  /// review moves them to approved.
  final KycStatus kycStatus;

  bool get isVerified => kycStatus == KycStatus.approved;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final joined = '$f$l'.trim();
    return joined.isEmpty ? '?' : joined.toUpperCase();
  }

  /// Onboarding is complete once a name and a primary service line are on file.
  bool get isComplete => firstName.isNotEmpty && primaryCategory != null;
}

/// Reads and writes the technician's `users/{uid}` document.
class TechnicianProfileRepository {
  TechnicianProfileRepository(this._uid);

  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirestorePaths.userDoc(FirebaseFirestore.instance, _uid);

  /// Writes the onboarding form. `role` is set so the security rules' role()
  /// lookup resolves to 'technician'; rating/jobs_done/tier seed the directory.
  Future<void> completeOnboarding({
    required String firstName,
    required String lastName,
    required JobCategory primaryCategory,
    String? email,
  }) async {
    await _doc.set(<String, dynamic>{
      'role': 'technician',
      'first_name': firstName,
      'last_name': lastName,
      'primary_category': primaryCategory.name,
      if (email != null && email.isNotEmpty) 'email': email,
      'rating': 0,
      'jobs_done': 0,
      'tier': TechnicianTier.bronze.toWire(),
      'available': false,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateName({
    required String firstName,
    required String lastName,
  }) async {
    await _doc.set(<String, dynamic>{
      'role': 'technician',
      'first_name': firstName,
      'last_name': lastName,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCategory(JobCategory category) async {
    await _doc.set(<String, dynamic>{
      'role': 'technician',
      'primary_category': category.name,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates the customer-facing blurb and coverage area.
  Future<void> updateAbout({String? bio, String? serviceArea}) async {
    await _doc.set(<String, dynamic>{
      'role': 'technician',
      'bio': ?bio,
      'service_area': ?serviceArea,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Increments the pro's completed-job counter. Called when a job is marked
  /// complete. Client-trusted for now (the pro owns their user doc); a backend
  /// aggregate can replace this once the payments phase lands.
  Future<void> incrementJobsDone() async {
    await _doc.set(<String, dynamic>{
      'role': 'technician',
      'jobs_done': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Flips the "accepting jobs" flag. The technician owns their own user doc, so
  /// this write is permitted by the users update rule.
  Future<void> setAvailability(bool available) async {
    await _doc.set(<String, dynamic>{
      'role': 'technician',
      'available': available,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Ensures a `users/{uid}` doc exists with role 'technician' for the signed-in
/// pro, seeding auth-derived name/email/phone without clobbering onboarding.
Future<void> seedTechnicianDocument(User user) async {
  final doc = FirestorePaths.userDoc(FirebaseFirestore.instance, user.uid);
  final snap = await doc.get();

  final parts = (user.displayName ?? '').trim().split(RegExp(r'\s+'))
    ..removeWhere((s) => s.isEmpty);
  final first = parts.isNotEmpty ? parts.first : '';
  final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

  await doc.set(<String, dynamic>{
    'role': 'technician',
    if (first.isNotEmpty) 'first_name': first,
    if (last.isNotEmpty) 'last_name': last,
    if ((user.email ?? '').isNotEmpty) 'email': user.email,
    if ((user.phoneNumber ?? '').isNotEmpty) 'phone': user.phoneNumber,
    if ((user.photoURL ?? '').isNotEmpty) 'photo_url': user.photoURL,
    if (!snap.exists) 'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

final techProfileRepositoryProvider =
    Provider<TechnicianProfileRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return TechnicianProfileRepository(user.uid);
});

/// Streams the merged [TechProfile]. Firestore fields win; anything missing
/// falls back to the Auth user so social sign-ins still show a name/email.
final techProfileProvider = StreamProvider.autoDispose<TechProfile>((ref) {
  final User? user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<TechProfile>.value(const TechProfile());

  final nameParts = (user.displayName ?? '').trim().split(RegExp(r'\s+'));
  final fallbackFirst = nameParts.isNotEmpty ? nameParts.first : '';
  final fallbackLast =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  return FirestorePaths.userDoc(FirebaseFirestore.instance, user.uid)
      .snapshots()
      .map((snap) {
    final data = snap.data() ?? const <String, dynamic>{};
    JobCategory? category;
    final rawCat = data['primary_category'];
    if (rawCat is String) {
      for (final JobCategory c in JobCategory.values) {
        if (c.name == rawCat || c.id == rawCat) category = c;
      }
    }
    TechnicianTier tier = TechnicianTier.bronze;
    final rawTier = data['tier'];
    if (rawTier is String) {
      try {
        tier = TechnicianTierCodec.fromWire(rawTier);
      } on FormatException {
        tier = TechnicianTier.bronze;
      }
    }
    String pick(String key, String fallback) {
      final v = (data[key] as String?)?.trim();
      return v != null && v.isNotEmpty ? v : fallback;
    }

    KycStatus kyc = KycStatus.applied;
    final rawKyc = data['kyc_status'];
    if (rawKyc is String) {
      try {
        kyc = KycStatusCodec.fromWire(rawKyc);
      } on FormatException {
        kyc = KycStatus.applied;
      }
    }

    return TechProfile(
      firstName: pick('first_name', fallbackFirst),
      lastName: pick('last_name', fallbackLast),
      phone: pick('phone', user.phoneNumber ?? ''),
      email: pick('email', user.email ?? ''),
      primaryCategory: category,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      jobsDone: (data['jobs_done'] as num?)?.toInt() ?? 0,
      tier: tier,
      available: data['available'] as bool? ?? false,
      photoUrl: (data['photo_url'] as String?)?.isNotEmpty == true
          ? data['photo_url'] as String
          : null,
      bio: (data['bio'] as String?) ?? '',
      serviceArea: (data['service_area'] as String?) ?? '',
      kycStatus: kyc,
    );
  });
});

/// Whether the technician has finished onboarding, used to gate the shell.
Future<bool> hasCompletedTechnicianProfile(String uid) async {
  final snap =
      await FirestorePaths.userDoc(FirebaseFirestore.instance, uid).get();
  if (!snap.exists) return false;
  final data = snap.data() ?? const <String, dynamic>{};
  final first = (data['first_name'] as String?)?.trim() ?? '';
  final cat = (data['primary_category'] as String?)?.trim() ?? '';
  return first.isNotEmpty && cat.isNotEmpty;
}
