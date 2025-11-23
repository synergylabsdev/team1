import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
      if apiKey == "REPLACE_WITH_YOUR_IOS_GOOGLE_MAPS_KEY" {
        NSLog("Google Maps API key is using the placeholder value. Update GMSApiKey in Info.plist before shipping.")
      }
    } else {
      assertionFailure("Google Maps API key missing. Set GMSApiKey in Info.plist.")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
