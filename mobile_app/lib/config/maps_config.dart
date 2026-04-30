import 'package:flutter/foundation.dart';
import 'app_config.dart';

class MapsConfig {
  static Future<void> initialize() async {
    if (!AppConfig.hasGoogleMapsConfig) {
      debugPrint(
        'Google Maps configuration is missing or placeholder-only. Map features will stay disabled in this build.',
      );
    }
  }

  static String get googleMapsApiKey {
    return AppConfig.googleMapsApiKey.trim();
  }

  static String get googlePlacesApiKey {
    return AppConfig.resolvedPlacesApiKey;
  }
}
