import 'package:agora_token_service/agora_token_service.dart';

class AgoraTokenService {
  // Your Agora App ID
  static const String appId = '29bf12aed25044f99a211542314d7798';
  
  // Your Agora App Certificate
  static const String appCertificate = 'e2cafbeff1af4d24a23888f7564059d3';

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
