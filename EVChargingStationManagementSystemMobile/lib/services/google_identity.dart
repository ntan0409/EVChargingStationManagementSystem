import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/google_oauth_config.dart';

enum GoogleFailureCode {
  canceled,
  configuration,
  unavailable,
  network,
  emptyToken,
  unsupported,
  unknown,
}

class GoogleSignInFailure implements Exception {
  final GoogleFailureCode code;
  const GoogleSignInFailure(this.code);
  String get message => switch (code) {
    GoogleFailureCode.canceled => 'Đã hủy đăng nhập Google.',
    GoogleFailureCode.configuration =>
      'Google OAuth chưa được cấu hình đúng. Kiểm tra Client ID, package, SHA và origin.',
    GoogleFailureCode.unavailable =>
      'Google Play Services hoặc dịch vụ đăng nhập không khả dụng trên thiết bị. Kiểm tra dịch vụ Google và thử lại.',
    GoogleFailureCode.network =>
      'Không thể kết nối Google. Kiểm tra mạng và thử lại.',
    GoogleFailureCode.emptyToken =>
      'Google không trả ID Token. Kiểm tra Web Client ID/serverClientId.',
    GoogleFailureCode.unsupported =>
      'Dùng nút Google SDK trên Web; nền tảng desktop này chưa hỗ trợ đăng nhập Google.',
    GoogleFailureCode.unknown =>
      'Không thể đăng nhập Google. Vui lòng thử lại.',
  };
}

class GoogleCredential {
  final String? idToken;
  final GoogleSignInFailure? failure;
  const GoogleCredential({this.idToken, this.failure});
}

abstract interface class GoogleIdentity {
  Future<void> initialize();
  Future<GoogleCredential> authenticate();
  Stream<GoogleCredential> get authenticationEvents;
  Future<void> signOut();
}

/// App-lifetime bridge around the SDK singleton. No access-token authorization,
/// lightweight auto-login, token persistence or account/profile fabrication.
class SdkGoogleIdentity implements GoogleIdentity {
  static final SdkGoogleIdentity _instance = SdkGoogleIdentity._();
  factory SdkGoogleIdentity() => _instance;
  SdkGoogleIdentity._();
  final _events = StreamController<GoogleCredential>.broadcast();
  Future<void>? _initialization;
  bool _ready = false;

  @override
  Stream<GoogleCredential> get authenticationEvents => _events.stream;

  static GoogleSignInFailure failureFor(Object error) {
    debugPrint('Google Sign-In Error: $error');
    if (error is GoogleSignInFailure) return error;
    if (error is GoogleSignInException) {
      return GoogleSignInFailure(switch (error.code) {
        GoogleSignInExceptionCode.canceled => GoogleFailureCode.canceled,
        GoogleSignInExceptionCode.clientConfigurationError =>
          GoogleFailureCode.configuration,
        GoogleSignInExceptionCode.providerConfigurationError ||
        GoogleSignInExceptionCode.uiUnavailable =>
          GoogleFailureCode.unavailable,
        _ =>
          error.description?.toLowerCase().contains('network') == true
              ? GoogleFailureCode.network
              : GoogleFailureCode.unknown,
      });
    }
    if (error is MissingPluginException) {
      return const GoogleSignInFailure(GoogleFailureCode.unavailable);
    }
    if (error is TimeoutException) {
      return const GoogleSignInFailure(GoogleFailureCode.network);
    }
    if (error is PlatformException && error.code == 'network_error') {
      return const GoogleSignInFailure(GoogleFailureCode.network);
    }
    return const GoogleSignInFailure(GoogleFailureCode.unknown);
  }

  @override
  Future<void> initialize() {
    if (!kIsWeb &&
        [
          TargetPlatform.windows,
          TargetPlatform.linux,
        ].contains(defaultTargetPlatform)) {
      return Future.error(
        const GoogleSignInFailure(GoogleFailureCode.unsupported),
      );
    }
    if (GoogleOAuthConfig.configurationProblem() != null) {
      return Future.error(
        const GoogleSignInFailure(GoogleFailureCode.configuration),
      );
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final apple = [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb
            ? GoogleOAuthConfig.webClientId
            : apple
            ? GoogleOAuthConfig.iosClientId
            : null,
        serverClientId: kIsWeb ? null : GoogleOAuthConfig.webClientId,
      );
      // One subscription for the lifetime of the SDK singleton. Web widgets
      // subscribe/unsubscribe to the broadcast bridge with their own lifecycle.
      GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _events.add(
              GoogleCredential(idToken: event.user.authentication.idToken),
            );
          }
        },
        onError: (Object error) {
          _events.add(GoogleCredential(failure: failureFor(error)));
        },
      );
      _ready = true;
    } catch (error) {
      throw failureFor(error);
    }
  }

  @override
  Future<GoogleCredential> authenticate() async {
    try {
      await initialize();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return const GoogleCredential(
          failure: GoogleSignInFailure(GoogleFailureCode.unsupported),
        );
      }
      final account = await GoogleSignIn.instance.authenticate();
      return GoogleCredential(idToken: account.authentication.idToken);
    } catch (error) {
      return GoogleCredential(failure: failureFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    if (_ready) await GoogleSignIn.instance.signOut();
  }
}
