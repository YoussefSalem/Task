import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

/// Firestore directory of technicians for the home "top rated" rail.
final technicianDirectoryRepositoryProvider =
    Provider<TechnicianDirectoryRepository>(
  (ref) => FirestoreTechnicianDirectoryRepository(),
);

/// Highest-rated technicians, best first. Empty until technicians exist.
final topTechniciansProvider = StreamProvider<List<TechnicianProfile>>(
  (ref) => ref.watch(technicianDirectoryRepositoryProvider).watchTopRated(),
);

/// Firestore-backed home promotions.
final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => FirestorePromotionsRepository(),
);

/// Active promotions for the home hero carousel, ordered. Empty hides the rail.
final promotionsProvider = StreamProvider<List<Promotion>>(
  (ref) => ref.watch(promotionsRepositoryProvider).watchActive(),
);
