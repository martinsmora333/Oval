class AppConfig {
  AppConfig._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;


  static bool _isValidGoogleApiKey(String value) {
    final normalized = value.trim();
    return normalized.startsWith('AIza') && normalized.length > 20;
  }

  static bool get hasGoogleMapsConfig =>
      _isValidGoogleApiKey(googleMapsApiKey);

  static String get resolvedPlacesApiKey {
    final explicitPlacesKey = googlePlacesApiKey.trim();
    if (_isValidGoogleApiKey(explicitPlacesKey)) {
      return explicitPlacesKey;
    }

    return hasGoogleMapsConfig ? googleMapsApiKey.trim() : '';
  }
}
