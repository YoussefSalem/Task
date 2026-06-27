/// Task data layer — concrete implementations of the domain contracts.
///
/// Bridges `task_domain` interfaces to Firebase, Paymob (Dio), and the Drift
/// offline queue. Repository implementations are added per feature phase; the
/// enum codecs below are shared infrastructure used by every DTO.
library;

export 'src/mappers/enum_codecs.dart';
export 'src/messaging/firestore_messaging_repository.dart';
export 'src/messaging/firestore_notification_repository.dart';
