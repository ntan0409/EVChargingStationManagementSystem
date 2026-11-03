import 'dart:async';
import 'package:dio/dio.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/core/network/api_response.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeApiAdapter adapter;
  late Dio dio;
  late ApiClient client;
  late AuthProvider provider;
  late String token;
  int? loginStatus;
  int profileStatus = 200;
  Object? loginBody;
  Object? profileBody;

  Future<void> seedSession(String value, {String base = testBaseUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', value);
    await prefs.setString('auth_base_url', base);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
    token = testToken();
    loginStatus = 200;
    profileStatus = 200;
    loginBody = {
      'token': token,
      'expiration': DateTime.now()
          .add(const Duration(hours: 1))
          .toUtc()
          .toIso8601String(),
    };
    profileBody = {'data': testProfile(), 'message': 'Read'};
    adapter = FakeApiAdapter((request) {
      if (request.uri.path.endsWith('/profile')) {
        return jsonResponse(profileBody, status: profileStatus);
      }
      return jsonResponse(loginBody, status: loginStatus!);
    });
    dio = Dio()..httpClientAdapter = adapter;
    client = ApiClient(dio: dio);
    provider = AuthProvider(authService: AuthService(apiClient: client));
  });

  test(
    'initAuth network failure does not restore a remembered session',
    () async {
      await seedSession(token);
      dio.httpClientAdapter = FakeApiAdapter(
        (request) => throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        ),
      );
      await provider.initAuth();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.errorMessage, contains('Không thể kết nối'));
      expect(await client.getAuthToken(), isNull);
    },
  );

  test(
    'Corrupt token storage fails closed without constructing a profile',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 123,
        'auth_base_url': testBaseUrl,
      });
      await provider.initAuth();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(adapter.requests, isEmpty);
      expect(provider.errorMessage, isNotEmpty);
    },
  );

  test(
    'Missing profile data never fabricates a user or retains a token',
    () async {
      profileBody = {'message': 'No profile', 'data': null};
      expect(await provider.login('driver@example.test', 'password'), isFalse);
      expect(provider.currentUser, isNull);
      expect(await client.getAuthToken(), isNull);
    },
  );

  test('Malformed registration success response is failure', () async {
    loginBody = {'unexpected': 'body'};
    expect(
      await provider.register(
        email: 'new@example.test',
        password: 'password',
        name: 'New',
        phone: '0912345678',
      ),
      isFalse,
    );
    expect(provider.isAuthenticated, isFalse);
  });

  tearDown(() {
    provider.dispose();
    dio.close(force: true);
  });

  for (final status in [400, 401, 403, 409, 500]) {
    test('Login HTTP $status is failure; no fake user/token', () async {
      loginStatus = status;
      loginBody = {'message': 'Login rejected $status'};
      expect(
        await provider.login('driver@example.test', 'wrong password'),
        isFalse,
      );
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.errorMessage, 'Login rejected $status');
      expect(provider.isLoading, isFalse);
      expect(await client.getAuthToken(), isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    });
  }

  test(
    'Login valid response loads verified backend profile and persists exact token',
    () async {
      expect(
        await provider.login('driver@example.test', ' password with spaces '),
        isTrue,
      );
      expect(provider.currentUser!.id, testDriverId);
      expect(provider.currentUser!.accountId, testAccountId);
      expect(provider.currentUser!.name, 'Driver From Backend');
      expect(provider.currentUser!.score, 15);
      expect(provider.isAuthenticated, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), token);
      expect(prefs.getString('auth_base_url'), testBaseUrl);
      expect(prefs.getString('user_id'), isNull);
      expect(adapter.requests.first.method, 'POST');
      expect(adapter.requests.first.uri.toString(), '$testBaseUrl/Auth/login');
      expect(adapter.requests.first.data, {
        'email': 'driver@example.test',
        'password': ' password with spaces ',
      });
      expect(adapter.requests.first.headers['Authorization'], isNull);
      expect(adapter.requests.last.uri.path, '/api/EVDriver/profile');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer $token');
    },
  );

  for (final body in [
    <String, dynamic>{},
    {'token': ''},
    {'token': 123},
    {'token': 'not-a-jwt'},
    null,
  ]) {
    test(
      'Malformed login body ${body.runtimeType}: no authentication or profile request',
      () async {
        loginBody = body;
        expect(
          await provider.login('driver@example.test', 'password'),
          isFalse,
        );
        expect(provider.isAuthenticated, isFalse);
        expect(provider.currentUser, isNull);
        expect(adapter.requests.length, 1);
        expect(await client.getAuthToken(), isNull);
      },
    );
  }

  test('Expired login JWT is rejected without profile request', () async {
    loginBody = {
      'token': testToken(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    };
    expect(await provider.login('driver@example.test', 'password'), isFalse);
    expect(adapter.requests.length, 1);
  });

  test('Malformed JSON keeps HTTP status and does not authenticate', () async {
    dio.httpClientAdapter = FakeApiAdapter(
      (_) => ResponseBody.fromString(
        '{broken',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    final response = await AuthService(
      apiClient: client,
    ).login('driver@example.test', 'password');
    expect(response.success, isFalse);
    expect(response.statusCode, 200);
    expect(response.errorType, ApiErrorType.parse);
    expect(await provider.login('driver@example.test', 'password'), isFalse);
  });

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badCertificate,
  ]) {
    test('Login $type fails without sensitive exception text', () async {
      dio.httpClientAdapter = FakeApiAdapter(
        (request) => throw DioException(
          requestOptions: request,
          type: type,
          error: 'sensitive-request-do-not-display',
        ),
      );
      expect(await provider.login('driver@example.test', 'password'), isFalse);
      expect(provider.errorMessage, isNotEmpty);
      expect(provider.errorMessage, isNot(contains('sensitive-request')));
      expect(provider.isAuthenticated, isFalse);
      expect(await client.getAuthToken(), isNull);
    });
  }

  for (final status in [401, 403, 404, 500]) {
    test(
      'Backend profile HTTP $status prevents login despite structurally valid JWT',
      () async {
        profileStatus = status;
        profileBody = {'message': 'Profile rejected $status'};
        expect(
          await provider.login('driver@example.test', 'password'),
          isFalse,
        );
        expect(provider.errorMessage, 'Profile rejected $status');
        expect(provider.currentUser, isNull);
        expect(await client.getAuthToken(), isNull);
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          isNull,
        );
      },
    );
  }

  test(
    'Profile missing or for a different account cannot authenticate',
    () async {
      profileBody = {'data': {}};
      expect(await provider.login('driver@example.test', 'password'), isFalse);
      profileBody = {
        'data': testProfile(accountId: '30000000-0000-0000-0000-000000000001'),
      };
      expect(await provider.login('driver@example.test', 'password'), isFalse);
      expect(provider.isAuthenticated, isFalse);
    },
  );

  test(
    'Remember Me false uses memory only and clears an older saved session',
    () async {
      await seedSession('old-token');
      expect(
        await provider.login(
          'driver@example.test',
          'password',
          rememberMe: false,
        ),
        isTrue,
      );
      expect(await client.getAuthToken(), token);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
      final restored = AuthProvider(
        authService: AuthService(
          apiClient: ApiClient(dio: Dio()..httpClientAdapter = adapter),
        ),
      );
      await restored.initAuth();
      expect(restored.isAuthenticated, isFalse);
      restored.dispose();
    },
  );

  for (final value in [
    'mock-jwt-token-demo',
    'audit-local-token',
    '',
    'a.b.c',
  ]) {
    test('initAuth rejects saved invalid/demo token ($value)', () async {
      await seedSession(value);
      await provider.initAuth();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(adapter.requests, isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    });
  }

  test('initAuth rejects expired JWT without calling backend', () async {
    await seedSession(
      testToken(expiresAt: DateTime.now().subtract(const Duration(hours: 1))),
    );
    await provider.initAuth();
    expect(provider.isAuthenticated, isFalse);
    expect(adapter.requests, isEmpty);
  });

  test('initAuth does not restore a token saved for another API', () async {
    await seedSession(token, base: 'https://other.example.test/api');
    await provider.initAuth();
    expect(provider.isAuthenticated, isFalse);
    expect(adapter.requests, isEmpty);
  });

  test(
    'initAuth only authenticates after backend profile verifies a remembered JWT',
    () async {
      await seedSession(token);
      await provider.initAuth();
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser!.accountId, testAccountId);
      expect(adapter.requests.single.uri.path, '/api/EVDriver/profile');
    },
  );

  test(
    'initAuth rejects revoked JWT even if it decodes and has not expired',
    () async {
      await seedSession(token);
      profileStatus = 401;
      profileBody = {'message': 'Revoked'};
      await provider.initAuth();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, 'Revoked');
      expect(await client.getAuthToken(), isNull);
    },
  );

  test(
    'Logout clears memory, persistent token and legacy profile fields',
    () async {
      expect(await provider.login('driver@example.test', 'password'), isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', 'stale profile');
      await provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(await client.getAuthToken(), isNull);
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_base_url'), isNull);
      expect(prefs.getString('user_name'), isNull);
      await AuthService(apiClient: client).getProfile();
      expect(adapter.requests.last.headers['Authorization'], isNull);
    },
  );

  test(
    'Register 409 keeps an existing session and profile unchanged',
    () async {
      expect(await provider.login('driver@example.test', 'password'), isTrue);
      final current = provider.currentUser;
      loginStatus = 409;
      loginBody = {'message': 'Email already exists'};
      expect(
        await provider.register(
          email: 'driver@example.test',
          password: 'password',
          name: 'Test',
          phone: '0912345678',
        ),
        isFalse,
      );
      expect(provider.currentUser, same(current));
      expect(provider.isAuthenticated, isTrue);
      expect(provider.errorMessage, 'Email already exists');
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        token,
      );
      expect(adapter.requests.last.headers['Authorization'], isNull);
    },
  );

  test('Register success does not log in automatically', () async {
    loginBody = {'message': 'Confirm your email'};
    expect(
      await provider.register(
        email: 'new@example.test',
        password: 'password',
        name: 'New',
        phone: '0912345678',
      ),
      isTrue,
    );
    expect(provider.isAuthenticated, isFalse);
    expect(await client.getAuthToken(), isNull);
  });

  test(
    'Profile update sends DriverId contract and does not update locally on failure',
    () async {
      expect(await provider.login('driver@example.test', 'password'), isTrue);
      loginStatus = 409;
      loginBody = {'message': 'Update rejected'};
      expect(
        await provider.updateProfile(name: 'New name', phone: '0912345678'),
        isFalse,
      );
      expect(provider.currentUser!.name, 'Driver From Backend');
      expect(adapter.requests.last.method, 'PUT');
      expect(adapter.requests.last.data['driverId'], testDriverId);
      expect(adapter.requests.last.data.containsKey('id'), isFalse);
      loginStatus = 200;
      loginBody = {'data': testProfile(name: 'Backend updated')};
      expect(
        await provider.updateProfile(name: 'New name', phone: '0912345678'),
        isTrue,
      );
      expect(provider.currentUser!.name, 'Backend updated');
    },
  );

  test(
    'Dispose during a request does not publish state or save token',
    () async {
      final pending = Completer<ResponseBody>();
      dio.httpClientAdapter = FakeApiAdapter((_) => pending.future);
      final operation = provider.login('driver@example.test', 'password');
      await Future<void>.delayed(Duration.zero);
      provider.dispose();
      pending.complete(jsonResponse(loginBody));
      expect(await operation, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
      // Replace the disposed provider so tearDown owns a live instance.
      provider = AuthProvider(authService: AuthService(apiClient: client));
    },
  );

  test(
    'Logout during pending login prevents a late response from restoring session',
    () async {
      final pending = Completer<ResponseBody>();
      dio.httpClientAdapter = FakeApiAdapter((_) => pending.future);
      final operation = provider.login('driver@example.test', 'password');
      await Future<void>.delayed(Duration.zero);
      await provider.logout();
      pending.complete(jsonResponse(loginBody));
      expect(await operation, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    },
  );
}
