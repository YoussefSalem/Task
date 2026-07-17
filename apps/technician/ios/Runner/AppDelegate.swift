import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK for iOS key (jobs map). Same key the Android side uses;
    // requires "Maps SDK for iOS" enabled on it in Google Cloud Console.
    // google_maps_flutter_ios needs this before any GMSMapView is created.
    GMSServices.provideAPIKey("AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
