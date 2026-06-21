import 'package:meta/meta.dart';

import 'enums.dart';
import 'job_category.dart';
import 'job_enums.dart';
import 'offer.dart';

/// A fixed-price job posted by a customer. The customer names one [fixedPrice];
/// technicians negotiate via [offers]. No hourly pricing exists in this model.
@immutable
class JobRequest {
  const JobRequest({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.fixedPrice,
    this.currency = 'EGP',
    required this.urgency,
    required this.propertyType,
    this.floor,
    this.parking,
    this.photos = const <String>[],
    required this.locationLabel,
    this.notes = '',
    required this.status,
    this.offers = const <Offer>[],
    required this.createdAt,
  });

  final String id;
  final JobCategory category;
  final String title;
  final String description;
  final int fixedPrice; // EGP — the customer's single offered amount
  final String currency;
  final Urgency urgency;
  final PropertyType propertyType;
  final String? floor;
  final bool? parking;
  final List<String> photos;
  final String locationLabel;
  final String notes;
  final JobStatus status;
  final List<Offer> offers;
  final DateTime createdAt;

  Offer? get acceptedOffer {
    for (final Offer o in offers) {
      if (o.status == OfferStatus.accepted) return o;
    }
    return null;
  }

  /// The agreed price if an offer was accepted, else the customer's fixed offer.
  int get settledPrice => acceptedOffer?.currentPrice ?? fixedPrice;

  JobRequest copyWith({
    JobStatus? status,
    List<Offer>? offers,
    int? fixedPrice,
  }) =>
      JobRequest(
        id: id,
        category: category,
        title: title,
        description: description,
        fixedPrice: fixedPrice ?? this.fixedPrice,
        currency: currency,
        urgency: urgency,
        propertyType: propertyType,
        floor: floor,
        parking: parking,
        photos: photos,
        locationLabel: locationLabel,
        notes: notes,
        status: status ?? this.status,
        offers: offers ?? this.offers,
        createdAt: createdAt,
      );
}
