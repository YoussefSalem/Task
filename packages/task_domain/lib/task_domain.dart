/// Task domain layer — the technology-agnostic heart of the system.
///
/// Contains entities, enums, value objects, repository *interfaces*, and use
/// cases. Depends only on `task_core`. Implementations live in `task_data`.
library;

export 'src/entities/enums.dart';
export 'src/entities/job_category.dart';
export 'src/entities/job_enums.dart';
export 'src/entities/offer.dart';
export 'src/entities/job_request.dart';
export 'src/repositories/auth_repository.dart';
