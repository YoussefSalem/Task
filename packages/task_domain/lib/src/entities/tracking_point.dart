import 'package:meta/meta.dart';

/// One live-location sample for a job in progress, written by the assigned
/// technician to `jobs/{jobId}/tracking/{id}`. The customer's tracking screen
/// reads the latest point to place the technician on the map and show the ETA.
@immutable
class TrackingPoint {
  const TrackingPoint({
    required this.lat,
    required this.lng,
    required this.at,
    this.etaMinutes,
  });

  final double lat;
  final double lng;
  final DateTime at;

  /// Estimated minutes to arrival reported by the technician's device, if any.
  final int? etaMinutes;
}
