class AppConfig {
  // Platform-agnostic configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co', // Fallback for development
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here', // Fallback for development
  );
  
  // Environment detection
  static bool get isProduction => const String.fromEnvironment('ENVIRONMENT') == 'production';
  static bool get isDevelopment => !isProduction;
  
  // Platform detection helpers
  static bool get isWeb => identical(0, 0.0);
  static bool get isMobile => !isWeb;
  
  // Debug configuration validation
  static void validateConfig() {
    if (supabaseUrl.isEmpty || supabaseUrl == 'https://your-project.supabase.co') {
      throw Exception('SUPABASE_URL not properly configured');
    }
    
    if (supabaseAnonKey.isEmpty || supabaseAnonKey == 'your-anon-key-here') {
      throw Exception('SUPABASE_ANON_KEY not properly configured');
    }
    
    // Configuration validated successfully
    // Platform: ${isMobile ? 'Mobile' : 'Web'}
    // Environment: ${isProduction ? 'Production' : 'Development'}
  }
}
