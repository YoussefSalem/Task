import 'package:meta/meta.dart';

import 'enums.dart';
import 'job_category.dart';

/// A technician as seen by customers in the public directory (the home
/// "top rated" rail). Sourced from the technician's `users` document.
@immutable
class TechnicianProfile {
  const TechnicianProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.jobsDone,
    this.tier = TechnicianTier.bronze,
    this.photoUrl,
  });

  final String id;
  final String name;

  /// The technician's primary service line.
  final JobCategory category;

  final double rating;
  final int jobsDone;
  final TechnicianTier tier;

  /// Profile photo URL, when the technician has uploaded one.
  final String? photoUrl;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String s) => s.isNotEmpty)
      .map((String s) => s[0])
      .take(2)
      .join()
      .toUpperCase();
}
