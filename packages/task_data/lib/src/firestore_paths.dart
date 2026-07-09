import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore collection/subcollection names and composite path
/// helpers.
///
/// Every real Firestore repository in this codebase previously hardcoded its
/// own path segments inline. This class exists so a future rename (e.g. to
/// align with a different backend's schema) is a one-file change instead of a
/// hunt across ~10 files. Introducing it does not change any path — every
/// constant and helper here resolves to the exact same string the inline
/// literals it replaces did.
abstract final class FirestorePaths {
  // --- Top-level collections -----------------------------------------------

  static const String users = 'users';
  static const String jobs = 'jobs';
  static const String addresses = 'addresses';
  static const String promotions = 'promotions';

  // --- Subcollection segment names (relative, not full paths) --------------

  static const String wallet = 'wallet';
  static const String walletTransactions = 'wallet_transactions';
  static const String fcmTokens = 'fcm_tokens';
  static const String notifications = 'notifications';
  static const String reviews = 'reviews';
  static const String tracking = 'tracking';
  static const String threads = 'threads';
  static const String messages = 'messages';
  static const String complaints = 'complaints';

  // --- Fixed document ids ----------------------------------------------------

  /// The single, fixed doc id under `users/{uid}/wallet` holding the balance.
  static const String walletSummaryDocId = 'summary';

  // --- users/{uid} -----------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> usersCollection(
          FirebaseFirestore db) =>
      db.collection(users);

  static DocumentReference<Map<String, dynamic>> userDoc(
          FirebaseFirestore db, String uid) =>
      usersCollection(db).doc(uid);

  static DocumentReference<Map<String, dynamic>> walletSummaryDoc(
          FirebaseFirestore db, String uid) =>
      userDoc(db, uid).collection(wallet).doc(walletSummaryDocId);

  static CollectionReference<Map<String, dynamic>> walletTransactionsCollection(
          FirebaseFirestore db, String uid) =>
      userDoc(db, uid).collection(walletTransactions);

  static CollectionReference<Map<String, dynamic>> fcmTokensCollection(
          FirebaseFirestore db, String uid) =>
      userDoc(db, uid).collection(fcmTokens);

  static CollectionReference<Map<String, dynamic>> notificationsCollection(
          FirebaseFirestore db, String uid) =>
      userDoc(db, uid).collection(notifications);

  // --- jobs/{jobId} ------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> jobsCollection(
          FirebaseFirestore db) =>
      db.collection(jobs);

  static DocumentReference<Map<String, dynamic>> jobDoc(
          FirebaseFirestore db, String jobId) =>
      jobsCollection(db).doc(jobId);

  static CollectionReference<Map<String, dynamic>> jobReviewsCollection(
          FirebaseFirestore db, String jobId) =>
      jobDoc(db, jobId).collection(reviews);

  static CollectionReference<Map<String, dynamic>> jobTrackingCollection(
          FirebaseFirestore db, String jobId) =>
      jobDoc(db, jobId).collection(tracking);

  static DocumentReference<Map<String, dynamic>> jobThreadDoc(
          FirebaseFirestore db, String jobId, String technicianId) =>
      jobDoc(db, jobId).collection(threads).doc(technicianId);

  static CollectionReference<Map<String, dynamic>> jobThreadMessagesCollection(
          FirebaseFirestore db, String jobId, String technicianId) =>
      jobThreadDoc(db, jobId, technicianId).collection(messages);

  static CollectionReference<Map<String, dynamic>> jobComplaintsCollection(
          FirebaseFirestore db, String jobId) =>
      jobDoc(db, jobId).collection(complaints);

  // --- addresses ---------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> addressesCollection(
          FirebaseFirestore db) =>
      db.collection(addresses);

  // --- promotions ------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> promotionsCollection(
          FirebaseFirestore db) =>
      db.collection(promotions);
}
