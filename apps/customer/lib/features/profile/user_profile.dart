import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// The customer's profile, merged from the Firestore `users/{uid}` doc with
/// Firebase Auth fallbacks (phone from the phone-auth credential, name/email
/// from the Google/Apple provider when the user never filled the form).
@immutable
class UserProfile {
  const UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.birthday,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime? birthday;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name;
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final joined = '$f$l'.trim();
    return joined.isEmpty ? '?' : joined.toUpperCase();
  }
}

/// Reads (and seeds, for social sign-ins) the Firestore profile document.
class UserProfileRepository {
  UserProfileRepository(this._uid);

  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  /// Writes the profile fields collected by the complete-profile form. Merges
  /// so a later edit never wipes unrelated fields. `role` is set so the
  /// security rules' role() lookup resolves to 'customer'.
  Future<void> save({
    required String firstName,
    required String lastName,
    required String email,
    required DateTime birthday,
  }) async {
    await _doc.set(<String, dynamic>{
      'role': 'customer',
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'birthday': Timestamp.fromDate(birthday),
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final userProfileRepositoryProvider =
    Provider<UserProfileRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return UserProfileRepository(user.uid);
});

/// Streams the merged [UserProfile]. Firestore fields win; anything missing
/// falls back to the Auth user so social sign-ins still show a name/email.
final userProfileProvider = StreamProvider.autoDispose<UserProfile>((ref) {
  final User? user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<UserProfile>.value(const UserProfile());
  }

  // Auth-derived fallbacks.
  final nameParts = (user.displayName ?? '').trim().split(RegExp(r'\s+'));
  final fallbackFirst = nameParts.isNotEmpty ? nameParts.first : '';
  final fallbackLast =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
  final fallbackEmail = user.email ?? '';
  final fallbackPhone = user.phoneNumber ?? '';

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    final birthdayTs = data?['birthday'];
    return UserProfile(
      firstName: (data?['first_name'] as String?)?.trim().isNotEmpty == true
          ? data!['first_name'] as String
          : fallbackFirst,
      lastName: (data?['last_name'] as String?)?.trim().isNotEmpty == true
          ? data!['last_name'] as String
          : fallbackLast,
      email: (data?['email'] as String?)?.trim().isNotEmpty == true
          ? data!['email'] as String
          : fallbackEmail,
      phone: (data?['phone'] as String?)?.trim().isNotEmpty == true
          ? data!['phone'] as String
          : fallbackPhone,
      birthday: birthdayTs is Timestamp ? birthdayTs.toDate() : null,
    );
  });
});
