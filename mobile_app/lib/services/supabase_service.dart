import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final url = AppConfig.supabaseUrl.trim();
    final anonKey = AppConfig.supabaseAnonKey.trim();

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Pass SUPABASE_URL and '
        'SUPABASE_ANON_KEY with --dart-define or use ./scripts/flutter_with_env.sh.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
