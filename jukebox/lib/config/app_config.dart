import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late String apiBaseUrl;
  static late String environment;

  /// Initialize app configuration
  /// Load .env.local for development or .env.prod for production
  static Future<void> init({String env = 'local'}) async {
    environment = env;

    // Load the appropriate .env file based on environment
    final envFile = env == 'prod' ? '.env.prod' : '.env.local';

    try {
      await dotenv.load(fileName: envFile);
      apiBaseUrl = dotenv.env['API_BASE_URL'] ?? _getDefaultApiUrl();
    } catch (e) {
      print('Error loading $envFile: $e');
      print('Using default API URL');
      apiBaseUrl = _getDefaultApiUrl();
    }

    print('🚀 App initialized with environment: $environment');
    print('📍 API Base URL: $apiBaseUrl');
  }

  /// Get default API URL based on environment
  static String _getDefaultApiUrl() {
    if (environment == 'prod') {
      return 'https://jukebox-1048249386206.europe-west1.run.app/api/';
    } else {
      // Local development (Android emulator uses 10.0.2.2)
      return 'http://10.0.2.2:8000/api/';
    }
  }

  /// Check if we're in development mode
  static bool get isDevelopment => environment == 'local';

  /// Check if we're in production mode
  static bool get isProduction => environment == 'prod';
}
