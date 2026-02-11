import 'package:agora_token_service/agora_token_service.dart';
import 'package:flutter_chat_ui/utils/env_config.dart';

class AgoraTokenService {
  // Load Agora credentials from environment variables
  static String get appId => EnvConfig.agoraAppId;
  static String get appCertificate => EnvConfig.agoraAppCertificate;

  // Generate RTC token for video/audio calls
  static String generateToken({
    required String channelName,
    required int uid,
    int expirationSeconds = 3600, // 1 hour
  }) {
    try {
      // If no certificate is set, return empty token (works when App Certificate is disabled in Agora Console)
      if (appCertificate.isEmpty) {
        return ''; // Empty token for testing mode
      }

      // Generate token using Agora Token Service with RtcTokenBuilder
      final expireTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expirationSeconds;
      
      final token = RtcTokenBuilder.build(
        appId: appId,
        appCertificate: appCertificate,
        channelName: channelName,
        uid: uid.toString(),
        role: RtcRole.publisher,
        expireTimestamp: expireTimestamp,
      );

      return token;
    } catch (e) {
      // Error generating Agora token: $e
      return ''; // Return empty token for testing
    }
  }
}
