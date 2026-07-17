// Cross-platform entry point for the technician jobs map. Resolves to the
// native `google_maps_flutter` implementation on mobile, and a static-map
// fallback when compiled for the browser (web is dev scaffolding only).
//
// Both implementations expose an identical `JobsMapScreen` widget with the same
// `routePath` / `routeName`, so `app/router.dart` stays platform-agnostic.
export 'jobs_map_screen_mobile.dart'
    if (dart.library.js_interop) 'jobs_map_screen_web.dart';
