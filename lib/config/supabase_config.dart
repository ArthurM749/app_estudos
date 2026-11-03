class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pjuuvkrrkjqblqpkwcoo.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqdXV2a3Jya2pxYmxxcGt3Y29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1Nzg4NTUsImV4cCI6MjEwOTE1NDg1NX0.Nu-EUIOaJOnDm4Livsce2SZDGyCnlWKkjcpFZ5ldti4',
  );
}
