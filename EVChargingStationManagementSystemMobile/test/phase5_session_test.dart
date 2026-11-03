import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'support/fake_api.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });
  for (final status in [401, 403]) {
    test('Active session HTTP$status has the correct auth lifetime', () async {
      final dio = Dio();
      dio.httpClientAdapter = FakeApiAdapter((r) {
        if (r.path.endsWith('/Auth/login')) {
          return jsonResponse({
            'token': testToken(),
            'expiration': DateTime.now()
                .add(const Duration(hours: 1))
                .toIso8601String(),
          });
        }
        if (r.path.endsWith('/EVDriver/profile')) {
          return jsonResponse({'data': testProfile()});
        }
        return jsonResponse({'message': 'Rejected'}, status: status);
      });
      final api = ApiClient(dio: dio);
      final auth = AuthProvider(authService: AuthService(apiClient: api));
      addTearDown(auth.dispose);
      expect(await auth.login('driver@example.test', 'Fixture only'), isTrue);
      final response = await api.get('/Payment/methods');
      expect(response.statusCode, status);
      await Future<void>.delayed(Duration.zero);
      expect(auth.isAuthenticated, status != 401);
      if (status == 401) {
        expect(await api.getAuthToken(), isNull);
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          isNull,
        );
      }
    });
  }
  test(
    'JWT expiry while app is open invalidates the verified session',
    () async {
      final dio = Dio();
      final expiry = DateTime.now().add(const Duration(seconds: 2));
      dio.httpClientAdapter = FakeApiAdapter(
        (r) => r.path.endsWith('/Auth/login')
            ? jsonResponse({
                'token': testToken(expiresAt: expiry),
                'expiration': expiry.toIso8601String(),
              })
            : jsonResponse({'data': testProfile()}),
      );
      final auth = AuthProvider(
        authService: AuthService(apiClient: ApiClient(dio: dio)),
      );
      addTearDown(auth.dispose);
      expect(await auth.login('fixture', 'fixture'), isTrue);
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(auth.isAuthenticated, isFalse);
    },
  );
  test(
    'A late 401 from the old token does not sign out a newer session',
    () async {
      final pending = Completer<ResponseBody>();
      var generation = 0;
      final dio = Dio();
      dio.httpClientAdapter = FakeApiAdapter((r) {
        if (r.path.endsWith('/Auth/login')) {
          generation++;
          return jsonResponse({
            'token': testToken(
              expiresAt: DateTime.now().add(Duration(hours: generation)),
            ),
            'expiration': DateTime.now()
                .add(Duration(hours: generation))
                .toIso8601String(),
          });
        }
        if (r.path.endsWith('/EVDriver/profile')) {
          return jsonResponse({'data': testProfile()});
        }
        return pending.future;
      });
      final api = ApiClient(dio: dio);
      final auth = AuthProvider(authService: AuthService(apiClient: api));
      addTearDown(auth.dispose);
      expect(await auth.login('fixture', 'fixture'), isTrue);
      final oldRequest = api.get('/Payment/methods');
      await Future<void>.delayed(Duration.zero);
      expect(await auth.login('fixture', 'fixture'), isTrue);
      pending.complete(jsonResponse({'message': 'Expired'}, status: 401));
      await oldRequest;
      expect(auth.isAuthenticated, isTrue);
    },
  );
}
