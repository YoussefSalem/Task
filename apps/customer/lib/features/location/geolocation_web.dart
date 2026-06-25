import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One-shot browser geolocation. Invokes [onResult] with the device's
/// latitude/longitude, or throws on denial/timeout so the caller can fall back.
Future<void> detectCurrentLocation(
    void Function(double lat, double lng) onResult) async {
  final geo = web.window.navigator.geolocation;
  final completer = Completer<web.GeolocationPosition>();
  geo.getCurrentPosition(
    ((web.GeolocationPosition p) => completer.complete(p)).toJS,
    ((web.GeolocationPositionError err) {
      if (!completer.isCompleted) completer.completeError(err);
    }).toJS,
  );
  final pos = await completer.future.timeout(const Duration(seconds: 10));
  onResult(pos.coords.latitude.toDouble(), pos.coords.longitude.toDouble());
}
