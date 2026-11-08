import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration constants and initialization helpers.
class SupabaseConfig {
  /// Supabase Project URL.
  /// Replace with your Supabase Project URL (e.g. 'https://xyzcompany.supabase.co').
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder-project.supabase.co',
  );

  /// Supabase Anon / Public API Key.
  /// Replace with your project anon key from Project Settings -> API.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  /// Helper flag to determine if live Supabase credentials are configured.
  static bool get isConfigured =>
      supabaseUrl != 'https://placeholder-project.supabase.co' &&
      supabaseAnonKey != 'placeholder-anon-key' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Global accessor for the SupabaseClient instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Initializes Supabase with error recovery if placeholder credentials are used.
  static Future<bool> initialize() async {
    try {
      if (isConfigured) {
        await Supabase.initialize(
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
          debug: kDebugMode,
        );
        debugPrint('[SupabaseConfig] Live Supabase initialized successfully.');
        return true;
      } else {
        debugPrint(
          '[SupabaseConfig] Supabase is running with placeholder credentials. Live backend operations will use local demo fallback until actual URL/Key are provided.',
        );
        return false;
      }
    } catch (e, stack) {
      debugPrint('[SupabaseConfig] Failed to initialize Supabase: $e\n$stack');
      return false;
    }
  }
}
