/// Supply values using --dart-define. Never embed service-role/private keys.
class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get supabaseConfigured => supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;
}
