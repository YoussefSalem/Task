/// Task domain layer — the technology-agnostic heart of the system.
///
/// Contains entities, enums, value objects, repository *interfaces*, and use
/// cases. Depends only on `task_core`. Implementations live in `task_data`.
library;

export 'src/entities/app_notification.dart';
export 'src/entities/enums.dart';
export 'src/entities/job_category.dart';
export 'src/entities/job_enums.dart';
export 'src/entities/job_request.dart';
export 'src/entities/job_request_draft.dart';
export 'src/entities/message.dart';
export 'src/entities/messaging_enums.dart';
export 'src/entities/offer.dart';
export 'src/entities/promotion.dart';
export 'src/entities/review.dart';
export 'src/entities/technician_profile.dart';
export 'src/entities/tracking_point.dart';
export 'src/entities/wallet.dart';
export 'src/repositories/auth_repository.dart';
export 'src/repositories/job_marketplace_repository.dart';
export 'src/repositories/job_tracking_repository.dart';
export 'src/repositories/messaging_repository.dart';
export 'src/repositories/notification_repository.dart';
export 'src/repositories/promotions_repository.dart';
export 'src/repositories/push_token_repository.dart';
export 'src/repositories/technician_directory_repository.dart';
export 'src/repositories/wallet_repository.dart';
