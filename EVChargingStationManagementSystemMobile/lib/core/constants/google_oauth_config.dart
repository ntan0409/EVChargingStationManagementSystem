import 'package:flutter/foundation.dart';

class GoogleOAuthConfig {
  // Public OAuth identifiers only. Never put a client secret in Flutter.
  static const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1075888121668-9hav7j6vaml1khc3kt4vfvh3h4de2ihf.apps.googleusercontent.com',
  );
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static String? configurationProblem({
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    final target = platform ?? defaultTargetPlatform;
    if (!isWeb &&
        [TargetPlatform.windows, TargetPlatform.linux].contains(target)) {
      return 'Google Sign-In hỗ trợ Android/iOS/macOS và Web; nền tảng này chưa được hỗ trợ.';
    }
    if (webClientId.isEmpty ||
        !webClientId.endsWith('.apps.googleusercontent.com')) {
      return 'Chưa cấu hình GOOGLE_WEB_CLIENT_ID. Xem audit/PHASE3_RESULT.md.';
    }
    if (!isWeb &&
        [TargetPlatform.iOS, TargetPlatform.macOS].contains(target) &&
        iosClientId.isEmpty) {
      return 'Chưa cấu hình GOOGLE_IOS_CLIENT_ID và URL scheme cho nền tảng Apple.';
    }
    return null;
  }
}
