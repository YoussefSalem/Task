/// Native fallback — no browser geolocation available. A plugin-based
/// implementation (e.g. `geolocator`) can replace this later.
Future<void> detectCurrentLocation(
    void Function(double lat, double lng) onResult) async {
  // No-op: caller keeps the existing location.
}
