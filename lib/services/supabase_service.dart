import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  final Future<void> _initFuture;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() : _initFuture = _initializeSupabase();

  // Internal initialization logic
  static Future<void> _initializeSupabase() async {
    // Validate configuration before initialization
    AppConfig.validateConfig();
    
    print('🔧 Initializing Supabase...');
    print('📍 URL: ${AppConfig.supabaseUrl}');
    print('🔑 Key: ${AppConfig.supabaseAnonKey.substring(0, 10)}...');

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SupabaseLocalStorage(),
      ),
    );

    _instance._client = Supabase.instance.client;
    _instance._isInitialized = true;
  }

  // Client getter (async)
  Future<SupabaseClient> get client async {
    if (!_isInitialized) {
      await _initFuture;
    }
    return _client;
  }

  // Convenience getter for immediate access (use only after initialization)
  SupabaseClient get clientSync {
    if (!_isInitialized) {
      throw Exception(
          'SupabaseService not initialized. Call SupabaseService() first.');
    }
    return _client;
  }

  // Check if service is ready
  bool get isInitialized => _isInitialized;
}
