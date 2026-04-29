import 'app_config.dart';

class MapsConfig {
  static Future<void> initialize() async {
    if (googleMapsApiKey.isEmpty) {
      throw StateError(
        'Missing Google Maps configuration. Pass GOOGLE_MAPS_API_KEY with '
        '--dart-define or use ./scripts/flutter_with_env.sh.',
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
