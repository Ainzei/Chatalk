import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper class to access environment variables
class EnvConfig {
  // Firebase
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppIdWeb => dotenv.env['FIREBASE_APP_ID_WEB'] ?? '';
  static String get firebaseAppIdAndroid => dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '';
  static String get firebaseAppIdIos => dotenv.env['FIREBASE_APP_ID_IOS'] ?? '';
  static String get firebaseAppIdMacos => dotenv.env['FIREBASE_APP_ID_MACOS'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseIosBundleId => dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';

  // Agora
  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get agoraAppCertificate =>
      dotenv.env['AGORA_APP_CERTIFICATE'] ?? '';
  static String get agoraTokenServiceUrl =>
      dotenv.env['AGORA_TOKEN_SERVICE_URL'] ?? '';

  // Environment
  static String get environment => dotenv.env['ENV'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // API
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Check if all required environment variables are loaded
  static bool validateConfig() {
    final requiredVars = [
      firebaseApiKey,
      firebaseProjectId,
      firebaseStorageBucket,
      agoraAppId,
    ];
    return requiredVars.every((value) => value.isNotEmpty);
  }
}
