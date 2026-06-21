import 'package:meta/meta.dart';

import 'job_category.dart';
import 'job_enums.dart';

/// The in-progress fixed-price job the customer assembles before publishing.
@immutable
class JobRequestDraft {
  const JobRequestDraft({
    this.category,
    this.title = '',
    this.description = '',
    this.fixedPrice = 0,
    this.urgency = Urgency.soon,
    this.propertyType = PropertyType.apartment,
    this.floor,
    this.parking,
    this.photos = const <String>[],
    this.locationLabel = '',
    this.notes = '',
  });

  final JobCategory? category;
  final String title;
  final String description;
  final int fixedPrice;
  final Urgency urgency;
  final PropertyType propertyType;
  final String? floor;
  final bool? parking;
  final List<String> photos;
  final String locationLabel;
  final String notes;

  bool get isValid =>
      category != null && title.trim().isNotEmpty && fixedPrice > 0;

  JobRequestDraft copyWith({
    JobCategory? category,
    bool clearCategory = false,
    String? title,
    String? description,
    int? fixedPrice,
    Urgency? urgency,
    PropertyType? propertyType,
    String? floor,
    bool? parking,
    List<String>? photos,
    String? locationLabel,
    String? notes,
  }) =>
      JobRequestDraft(
        category: clearCategory ? null : (category ?? this.category),
        title: title ?? this.title,
        description: description ?? this.description,
        fixedPrice: fixedPrice ?? this.fixedPrice,
        urgency: urgency ?? this.urgency,
        propertyType: propertyType ?? this.propertyType,
        floor: floor ?? this.floor,
        parking: parking ?? this.parking,
        photos: photos ?? this.photos,
        locationLabel: locationLabel ?? this.locationLabel,
        notes: notes ?? this.notes,
      );
}
