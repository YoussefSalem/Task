import 'package:meta/meta.dart';

@immutable
class Review {
  const Review({
    required this.rating,
    this.tags = const <String>[],
    this.note = '',
    required this.reviewerId,
    required this.technicianId,
    required this.createdAt,
  });

  final int rating;
  final List<String> tags;
  final String note;
  final String reviewerId;
  final String technicianId;
  final DateTime createdAt;
}
