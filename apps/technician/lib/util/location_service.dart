import 'package:geolocator/geolocator.dart';

/// Thin wrapper over `geolocator` for broadcasting the on-the-job location trail.
///
/// Kept tiny and defensive: every call resolves to a value or null rather than
/// throwing, so the caller (the share-location toggle) can degrade gracefully
/// when permission is denied, location services are off, or we're on a platform
/// without a GPS (e.g. a desktop web preview).
class LocationService {
  const LocationService();

  /// Requests permission if needed. Returns true only when we're allowed to read
  /// position AND the OS location service is on.
  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      return perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// A single current fix, or null if unavailable.
  Future<({double lat, double lng})?> current() async {
    try {
      final Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return null;
    }
  }
}
