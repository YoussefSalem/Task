// Cross-platform entry point for the location picker. Resolves to the native
// `google_maps_flutter` implementation on mobile/desktop, and the embedded
// Google Maps iframe implementation when compiled for the browser.
//
// Both implementations expose an identical `PickLocationScreen` widget with the
// same `routePath` / `routeName`, so `app/router.dart` is platform-agnostic.
export 'pick_location_screen_mobile.dart'
    if (dart.library.js_interop) 'pick_location_screen_web.dart';
