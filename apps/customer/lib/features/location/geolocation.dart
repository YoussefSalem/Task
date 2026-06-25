/// Cross-platform entry point for one-shot device geolocation. Resolves to the
/// web implementation when compiled for the browser, and a no-op stub on native
/// (where a plugin like `geolocator` would be wired later).
export 'geolocation_stub.dart'
    if (dart.library.js_interop) 'geolocation_web.dart';
