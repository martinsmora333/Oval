import Flutter
import UIKit
import GoogleMaps
import os.log

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key from Info.plist
    initializeGoogleMaps()
    
    // Register plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure window appearance
    if #available(iOS 15.0, *) {
      let navigationBarAppearance = UINavigationBarAppearance()
      navigationBarAppearance.configureWithOpaqueBackground()
      navigationBarAppearance.backgroundColor = UIColor.white
      UINavigationBar.appearance().standardAppearance = navigationBarAppearance
      UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func initializeGoogleMaps() {
    // Primary source: generated local plist from Podfile / .env
    if let path = Bundle.main.path(forResource: "GoogleMaps-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
       let apiKey = dict["GMSApiKey"] as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
      os_log("Google Maps SDK initialized with API key from GoogleMaps-Info.plist")
      return
    }

    #if DEBUG
    // Optional fallback for debug-only native launches outside the wrapper script.
    if let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"], !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
      os_log("Google Maps SDK initialized with API key from environment variables")
      return
    }
    #endif
    
    // Final fallback - this will cause a crash in release builds
    // but provides a clear error message in debug builds
    let errorMessage = """
    🔴 Google Maps SDK initialization failed: No API key found.
    Expected source order:
    1. GoogleMaps-Info.plist generated from the local .env file
    2. GOOGLE_MAPS_API_KEY process environment variable (DEBUG only)
    """
    
    #if DEBUG
    fatalError(errorMessage)
    #else
    os_log("%@", type: .fault, errorMessage)
    #endif
  }
  
  // Handle URL schemes for Google Sign-In if needed
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Handle any custom URL schemes here if needed
    return super.application(app, open: url, options: options)
  }
}
