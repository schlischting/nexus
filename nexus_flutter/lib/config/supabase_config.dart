// Configuração Supabase para Nexus
// Valores carregados de .env em runtime

const String SUPABASE_URL = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT.supabase.co',
);

const String SUPABASE_ANON_KEY = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);

class SupabaseConfig {
  static const String url = SUPABASE_URL;
  static const String anonKey = SUPABASE_ANON_KEY;

  static bool get isConfigured {
    return url != 'https://YOUR_PROJECT.supabase.co' &&
        anonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  }

  static String get environment {
    if (url.contains('localhost')) return 'local';
    if (url.contains('preview')) return 'preview';
    return 'production';
  }
}
