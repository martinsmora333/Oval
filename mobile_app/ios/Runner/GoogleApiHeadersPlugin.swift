import Flutter
import UIKit

// Dummy implementation to satisfy Flutter's plugin registration system for
googe_api_headers versions <3.0 on iOS. The package only provides a platform
// interface and does not ship an inline iOS implementation, which causes the
// Xcode build to fail on newer Flutter versions. Registering an empty plugin
// resolves the "default plugin but no inline implementation" error.
//
// This file will be picked up automatically by the app target because it is
// inside the Runner target directory.
@objc(GoogleApiHeadersPlugin)
public class GoogleApiHeadersPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op. We just need a symbol so the linker is satisfied.
  }
}
