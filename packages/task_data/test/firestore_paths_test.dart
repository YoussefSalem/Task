import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_data/task_data.dart';

/// Locks the exact wire names every real Firestore repository in this codebase
/// already writes to. These values must never change as part of introducing
/// [FirestorePaths] itself — only a deliberate later migration should touch
/// them, and it should touch this file first.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
  });

  group('bare collection/subcollection name constants', () {
    test('top-level collection names match existing production literals', () {
      expect(FirestorePaths.users, 'users');
      expect(FirestorePaths.jobs, 'jobs');
      expect(FirestorePaths.addresses, 'addresses');
      expect(FirestorePaths.promotions, 'promotions');
    });

    test('subcollection segment names match existing production literals', () {
      expect(FirestorePaths.wallet, 'wallet');
      expect(FirestorePaths.walletTransactions, 'wallet_transactions');
      expect(FirestorePaths.fcmTokens, 'fcm_tokens');
      expect(FirestorePaths.notifications, 'notifications');
      expect(FirestorePaths.reviews, 'reviews');
      expect(FirestorePaths.tracking, 'tracking');
      expect(FirestorePaths.threads, 'threads');
      expect(FirestorePaths.messages, 'messages');
    });

    test('fixed document id for the wallet summary doc', () {
      expect(FirestorePaths.walletSummaryDocId, 'summary');
    });
  });

  group('composite path helpers resolve to the exact existing paths', () {
    test('userDoc', () {
      expect(FirestorePaths.userDoc(db, 'uid1').path, 'users/uid1');
    });

    test('walletSummaryDoc', () {
      expect(FirestorePaths.walletSummaryDoc(db, 'uid1').path,
          'users/uid1/wallet/summary');
    });

    test('walletTransactionsCollection', () {
      expect(FirestorePaths.walletTransactionsCollection(db, 'uid1').path,
          'users/uid1/wallet_transactions');
    });

    test('fcmTokensCollection', () {
      expect(FirestorePaths.fcmTokensCollection(db, 'uid1').path,
          'users/uid1/fcm_tokens');
    });

    test('notificationsCollection', () {
      expect(FirestorePaths.notificationsCollection(db, 'uid1').path,
          'users/uid1/notifications');
    });

    test('jobDoc', () {
      expect(FirestorePaths.jobDoc(db, 'job1').path, 'jobs/job1');
    });

    test('jobReviewsCollection', () {
      expect(FirestorePaths.jobReviewsCollection(db, 'job1').path,
          'jobs/job1/reviews');
    });

    test('jobTrackingCollection', () {
      expect(FirestorePaths.jobTrackingCollection(db, 'job1').path,
          'jobs/job1/tracking');
    });

    test('jobComplaintsCollection', () {
      expect(FirestorePaths.jobComplaintsCollection(db, 'job1').path,
          'jobs/job1/complaints');
    });

    test('jobThreadDoc', () {
      expect(FirestorePaths.jobThreadDoc(db, 'job1', 'tech1').path,
          'jobs/job1/threads/tech1');
    });

    test('jobThreadMessagesCollection', () {
      expect(
          FirestorePaths.jobThreadMessagesCollection(db, 'job1', 'tech1').path,
          'jobs/job1/threads/tech1/messages');
    });

    test('addressesCollection', () {
      expect(FirestorePaths.addressesCollection(db).path, 'addresses');
    });

    test('promotionsCollection', () {
      expect(FirestorePaths.promotionsCollection(db).path, 'promotions');
    });

    test('jobsCollection', () {
      expect(FirestorePaths.jobsCollection(db).path, 'jobs');
    });

    test('usersCollection', () {
      expect(FirestorePaths.usersCollection(db).path, 'users');
    });
  });
}
