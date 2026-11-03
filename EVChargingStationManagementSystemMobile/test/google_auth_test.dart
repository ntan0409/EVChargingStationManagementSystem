import 'dart:async';
import 'package:dio/dio.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:ev_charging_station/services/google_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_api.dart';
import 'support/fake_google_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeGoogleIdentity google;
  late FakeApiAdapter adapter;
  late Dio dio;
  late ApiClient client;
  late AuthProvider auth;
  late String systemJwt;
  late Object? exchangeBody;
  int exchangeStatus = 200;
  int profileStatus = 200;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
    google = FakeGoogleIdentity();
    systemJwt = testToken();
    exchangeStatus = 200;
    profileStatus = 200;
    exchangeBody = {'token': systemJwt};
    adapter = FakeApiAdapter(
      (request) => request.uri.path.endsWith('/profile')
          ? jsonResponse(
              profileStatus == 200
                  ? {'data': testProfile(name: 'Profile From Backend')}
                  : {'message': 'Profile rejected'},
              status: profileStatus,
            )
          : jsonResponse(exchangeBody, status: exchangeStatus),
    );
    dio = Dio()..httpClientAdapter = adapter;
    client = ApiClient(dio: dio);
    auth = AuthProvider(
      authService: AuthService(apiClient: client),
      googleIdentity: google,
    );
  });
  tearDown(() async {
    auth.dispose();
    dio.close(force: true);
    await google.events.close();
  });

  test(
    'Google ID token exchange uses backend JWT/profile, never Google token as session',
    () async {
      expect(await auth.loginWithGoogle(), isTrue);
      expect(google.signIns, 1);
      expect(
        adapter.requests.first.uri.toString(),
        '$testBaseUrl/Auth/login-google',
      );
      expect(adapter.requests.first.method, 'POST');
      expect(adapter.requests.first.data, {'idToken': googleIdTokenFixture});
      expect(adapter.requests.first.headers['Authorization'], isNull);
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer $systemJwt',
      );
      expect(auth.currentUser!.name, 'Profile From Backend');
      expect(auth.currentUser!.accountId, testAccountId);
      expect(await client.getAuthToken(), systemJwt);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), systemJwt);
      expect(
        prefs.getKeys().map(prefs.get),
        isNot(contains(googleIdTokenFixture)),
      );
    },
  );

  test(
    'User cancellation is not success, no backend call and no error toast message',
    () async {
      google.credential = const GoogleCredential(
        failure: GoogleSignInFailure(GoogleFailureCode.canceled),
      );
      expect(await auth.loginWithGoogle(), isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.isLoading, isFalse);
      expect(auth.errorMessage, isNull);
      expect(adapter.requests, isEmpty);
    },
  );

  for (final token in [null, '', '   ']) {
    test(
      'Empty Google ID token ($token) cannot reach backend or persist session',
      () async {
        google.credential = GoogleCredential(idToken: token);
        expect(await auth.loginWithGoogle(), isFalse);
        expect(auth.errorMessage, contains('ID Token'));
        expect(adapter.requests, isEmpty);
        expect(await client.getAuthToken(), isNull);
        expect(auth.isAuthenticated, isFalse);
      },
    );
  }

  for (final status in [400, 401, 403, 500, 503]) {
    test(
      'Google backend HTTP$status cannot authenticate or fall back to password',
      () async {
        exchangeStatus = status;
        exchangeBody = {'message': 'Google account rejected $status'};
        expect(await auth.loginWithGoogle(), isFalse);
        expect(auth.errorMessage, 'Google account rejected $status');
        expect(auth.isAuthenticated, isFalse);
        expect(auth.currentUser, isNull);
        expect(adapter.requests.length, 1);
        expect(adapter.requests.single.uri.path, '/api/Auth/login-google');
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          isNull,
        );
        expect(google.signOuts, 1);
      },
    );
  }

  test(
    'Missing backend JWT cannot authenticate after Google SDK succeeds',
    () async {
      exchangeBody = {'message': 'No system token'};
      expect(await auth.loginWithGoogle(), isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(adapter.requests.length, 1);
      expect(await client.getAuthToken(), isNull);
    },
  );

  for (final status in [401, 403, 500]) {
    test(
      'Valid-shaped system JWT with profile HTTP$status is not an authenticated session',
      () async {
        profileStatus = status;
        expect(await auth.loginWithGoogle(), isFalse);
        expect(auth.errorMessage, 'Profile rejected');
        expect(auth.isAuthenticated, isFalse);
        expect(auth.currentUser, isNull);
        expect(await client.getAuthToken(), isNull);
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          isNull,
        );
      },
    );
  }

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  ]) {
    test(
      'Google exchange $type reports failure without SDK/demo fallback',
      () async {
        dio.httpClientAdapter = FakeApiAdapter(
          (request) => throw DioException(requestOptions: request, type: type),
        );
        expect(await auth.loginWithGoogle(), isFalse);
        expect(auth.isAuthenticated, isFalse);
        expect(auth.errorMessage, isNotEmpty);
        expect(await client.getAuthToken(), isNull);
      },
    );
  }

  for (final code in [
    GoogleFailureCode.configuration,
    GoogleFailureCode.unavailable,
    GoogleFailureCode.network,
    GoogleFailureCode.unsupported,
  ]) {
    test(
      'Google provider failure $code is distinct and does not reach backend',
      () async {
        google.authenticationError = GoogleSignInFailure(code);
        expect(await auth.loginWithGoogle(), isFalse);
        expect(auth.errorMessage, GoogleSignInFailure(code).message);
        expect(adapter.requests, isEmpty);
        expect(auth.isLoading, isFalse);
      },
    );
  }

  test(
    'Remember Me false stores only system JWT in memory and cannot restore it',
    () async {
      expect(await auth.loginWithGoogle(rememberMe: false), isTrue);
      expect(await client.getAuthToken(), systemJwt);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_base_url'), isNull);
    },
  );

  test(
    'Remember Me true can restore only through backend profile verification',
    () async {
      expect(await auth.loginWithGoogle(rememberMe: true), isTrue);
      final restored = AuthProvider(
        authService: AuthService(apiClient: client),
        googleIdentity: google,
      );
      await restored.initAuth();
      expect(restored.isAuthenticated, isTrue);
      expect(restored.currentUser!.accountId, testAccountId);
      expect(google.signIns, 1); // No silent Google reauthentication.
      restored.dispose();
    },
  );

  test('Logout clears system JWT and calls Google signOut', () async {
    expect(await auth.loginWithGoogle(), isTrue);
    await auth.logout();
    expect(google.signOuts, 1);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.currentUser, isNull);
    expect(await client.getAuthToken(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('auth_token'),
      isNull,
    );
  });

  test(
    'Google SDK signOut failure never preserves the system session',
    () async {
      expect(await auth.loginWithGoogle(), isTrue);
      google.signOutError = StateError('sensitive SDK diagnostics');
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(await client.getAuthToken(), isNull);
      expect(auth.errorMessage, isNot(contains('sensitive SDK diagnostics')));
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    },
  );

  test(
    'Email/password still works and never invokes Google authentication',
    () async {
      expect(await auth.login('driver@example.test', 'password'), isTrue);
      expect(adapter.requests.first.uri.path, '/api/Auth/login');
      expect(adapter.requests.first.data, {
        'email': 'driver@example.test',
        'password': 'password',
      });
      expect(google.signIns, 0);
      expect(auth.currentUser!.accountId, testAccountId);
    },
  );

  test(
    'Web credential event uses the same exchange path, not native authenticate()',
    () async {
      expect(
        await auth.loginWithGoogle(
          credential: const GoogleCredential(idToken: googleIdTokenFixture),
        ),
        isTrue,
      );
      expect(google.signIns, 0);
      expect(adapter.requests.first.data, {'idToken': googleIdTokenFixture});
    },
  );

  test(
    'Google result arriving after logout cannot restore a session',
    () async {
      final pending = Completer<ResponseBody>();
      dio.httpClientAdapter = FakeApiAdapter((_) => pending.future);
      final operation = auth.loginWithGoogle();
      await Future<void>.delayed(Duration.zero);
      await auth.logout();
      pending.complete(jsonResponse(exchangeBody));
      expect(await operation, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    },
  );

  for (final pair in [
    (GoogleSignInExceptionCode.canceled, GoogleFailureCode.canceled),
    (
      GoogleSignInExceptionCode.clientConfigurationError,
      GoogleFailureCode.configuration,
    ),
    (
      GoogleSignInExceptionCode.providerConfigurationError,
      GoogleFailureCode.unavailable,
    ),
    (GoogleSignInExceptionCode.uiUnavailable, GoogleFailureCode.unavailable),
  ]) {
    test('SDK error ${pair.$1} maps to safe domain failure ${pair.$2}', () {
      final failure = SdkGoogleIdentity.failureFor(
        GoogleSignInException(
          code: pair.$1,
          description: 'do-not-expose-token',
        ),
      );
      expect(failure.code, pair.$2);
      expect(failure.message, isNot(contains('do-not-expose-token')));
    });
  }
}
