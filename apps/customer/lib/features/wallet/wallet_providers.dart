import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../chat/chat_providers.dart';

/// Firestore-backed wallet (balance + ledger). Read-only from the client; the
/// balance is mutated by the backend once payments land.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => FirestoreWalletRepository(),
);

/// Live wallet balance for the signed-in customer. Emits [WalletSummary.empty]
/// when signed out or before the wallet doc exists.
final walletSummaryProvider = StreamProvider<WalletSummary>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream<WalletSummary>.value(WalletSummary.empty);
  }
  return ref.watch(walletRepositoryProvider).watchSummary(uid);
});

/// Live wallet ledger for the signed-in customer, newest first. Empty when
/// signed out or before the user has any transactions.
final walletTransactionsProvider =
    StreamProvider<List<WalletTransaction>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream<List<WalletTransaction>>.value(const <WalletTransaction>[]);
  }
  return ref.watch(walletRepositoryProvider).watchTransactions(uid);
});
