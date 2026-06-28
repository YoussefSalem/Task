import '../entities/technician_profile.dart';

/// Read-only directory of technicians for the customer-facing "top rated" rail.
/// Implemented in `task_data` over the `users` collection (role == technician).
abstract interface class TechnicianDirectoryRepository {
  /// Live list of the highest-rated technicians, best first, capped at [limit].
  /// Emits an empty list when no technicians exist yet.
  Stream<List<TechnicianProfile>> watchTopRated({int limit});
}
