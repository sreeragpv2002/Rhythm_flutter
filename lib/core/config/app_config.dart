
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Base API domain (without language or version)
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://dev.example.com';

  /// API version
  static const String apiVersion = 'api/v1';

  /// Default language (fallback only)
  static const String defaultLanguage = 'en';

  /// Build environment
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// Build full API URL dynamically
  static String apiUrl(String langCode) {
    return '$baseUrl/$langCode/$apiVersion';
  }
}