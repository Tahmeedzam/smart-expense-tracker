import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    assert(_url.isNotEmpty, 'Missing SUPABASE_URL — pass via --dart-define');
    assert(
      _anonKey.isNotEmpty,
      'Missing SUPABASE_ANON_KEY — pass via --dart-define',
    );

    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
