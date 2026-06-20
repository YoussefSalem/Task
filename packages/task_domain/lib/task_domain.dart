/// Task domain layer — the technology-agnostic heart of the system.
///
/// Contains entities, enums, value objects, repository *interfaces*, and use
/// cases. Depends only on `task_core`. Implementations live in `task_data`.
library;

export 'src/entities/enums.dart';
export 'src/repositories/auth_repository.dart';
