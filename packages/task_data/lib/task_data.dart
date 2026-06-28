/// Task data layer — concrete implementations of the domain contracts.
///
/// Bridges `task_domain` interfaces to Firebase, Paymob (Dio), and the Drift
/// offline queue. Repository implementations are added per feature phase; the
/// enum codecs below are shared infrastructure used by every DTO.
library;

export 'src/directory/firestore_technician_directory_repository.dart';
export 'src/mappers/enum_codecs.dart';
export 'src/messaging/firestore_messaging_repository.dart';
export 'src/messaging/firestore_notification_repository.dart';
export 'src/messaging/firestore_push_token_repository.dart';
export 'src/promotions/firestore_promotions_repository.dart';
export 'src/tracking/firestore_job_tracking_repository.dart';
export 'src/wallet/firestore_wallet_repository.dart';
