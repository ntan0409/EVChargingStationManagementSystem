import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/core/network/api_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });

  test(
    'Platform defaults use HTTP5058 and emulator host only on Android native',
    () {
      expect(
        ApiConstants.developmentBaseUrl(TargetPlatform.android),
        'http://10.0.2.2:5058/api',
      );
      expect(
        ApiConstants.developmentBaseUrl(TargetPlatform.android, isWeb: true),
        'http://localhost:5058/api',
      );
      expect(
        ApiConstants.developmentBaseUrl(TargetPlatform.windows),
        'http://localhost:5058/api',
      );
    },
  );

  for (final base in [
    'https://api.example.test',
    '$testBaseUrl/',
    '$testBaseUrl/api/',
    '  $testBaseUrl  ',
  ]) {
    test('Base normalizes once: $base', () {
      expect(ApiConstants.normalizeBaseUrl(base), testBaseUrl);
      for (final endpoint in [
        '/Auth/login',
        'Auth/login',
        '/api/Auth/login',
        '/api/api/Auth/login',
      ]) {
        expect(
          ApiConstants.resolveEndpoint(endpoint, baseUrl: base),
          '$testBaseUrl/Auth/login',
        );
      }
    });
  }

  test('Endpoint joining preserves deployment prefix and encoded query', () {
    expect(
      ApiConstants.resolveEndpoint(
        '/api/Auth/resend-confirm-email?Email=a%2Bb%40example.test',
        baseUrl: 'https://host.example.test/gateway/api/',
      ),
      'https://host.example.test/gateway/api/Auth/resend-confirm-email?Email=a%2Bb%40example.test',
    );
  });

  for (final invalid in [
    '',
    'localhost:5058/api',
    'ftp://host/api',
    'https://user:password@host/api',
    'https://host/api?x=1',
    'https://host/api#secret',
    'http://host:70000/api',
  ]) {
    test(
      'Invalid server setting is rejected: ${invalid.isEmpty ? "empty" : invalid.split(":").first}',
      () async {
        await expectLater(
          ApiConstants.setBaseUrl(invalid),
          throwsFormatException,
        );
        expect(ApiConstants.baseUrl, testBaseUrl);
      },
    );
  }

  test('Release policy rejects HTTP and accepts explicit HTTPS', () {
    expect(
      () => ApiConstants.normalizeBaseUrl(
        'http://10.0.2.2:5058/api',
        requireHttps: true,
      ),
      throwsFormatException,
    );
    expect(
      ApiConstants.normalizeBaseUrl(testBaseUrl, requireHttps: true),
      testBaseUrl,
    );
  });

  test('Settings initialize from the single stored base URL', () async {
    await ApiConstants.setBaseUrl('https://new.example.test/api/api/');
    await ApiConstants.init();
    expect(ApiConstants.baseUrl, 'https://new.example.test/api');
  });

  test(
    'Requests use current configured base and never duplicate api prefix',
    () async {
      final adapter = FakeApiAdapter((_) => jsonResponse({'data': 'ok'}));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio);
      expect((await client.get<String>('/api/api/Test')).data, 'ok');
      await ApiConstants.setBaseUrl('https://new.example.test');
      await client.post('/api/Test');
      expect(adapter.requests.first.uri.toString(), '$testBaseUrl/Test');
      expect(
        adapter.requests.last.uri.toString(),
        'https://new.example.test/api/Test',
      );
      dio.close();
    },
  );

  test('Changing API host does not send previous host token', () async {
    final adapter = FakeApiAdapter((_) => jsonResponse({}));
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(dio: dio)..setAuthToken(testToken());
    await ApiConstants.setBaseUrl('https://other.example.test/api');
    await client.get('/EVDriver/profile');
    expect(adapter.requests.single.headers['Authorization'], isNull);
    dio.close();
  });

  test(
    'HTTP validation error keeps status and field details instead of generic title',
    () async {
      final details = {
        'Email': ['Email is invalid'],
        'Password': ['Password is required'],
      };
      final dio = Dio()
        ..httpClientAdapter = FakeApiAdapter(
          (_) => jsonResponse({
            'title': 'One or more validation errors occurred.',
            'errors': details,
          }, status: 400),
        );
      final response = await ApiClient(dio: dio).post('/Auth/login');
      expect(response.success, isFalse);
      expect(response.statusCode, 400);
      expect(response.errorType, ApiErrorType.http);
      expect(response.errors, details);
      expect(response.message, contains('Email is invalid'));
      expect(response.message, contains('Password is required'));
      dio.close();
    },
  );

  test('Identity error arrays retain descriptions', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeApiAdapter(
        (_) => jsonResponse([
          {'code': 'DuplicateEmail', 'description': 'Email already exists'},
        ], status: 409),
      );
    final response = await ApiClient(dio: dio).post('/Auth/register');
    expect(response.message, 'Email already exists');
    expect(response.statusCode, 409);
    expect(response.errors, isList);
    dio.close();
  });

  for (final pair in [
    (DioExceptionType.connectionError, ApiErrorType.network),
    (DioExceptionType.connectionTimeout, ApiErrorType.timeout),
    (DioExceptionType.receiveTimeout, ApiErrorType.timeout),
    (DioExceptionType.badCertificate, ApiErrorType.tls),
    (DioExceptionType.cancel, ApiErrorType.cancelled),
  ]) {
    test('API error classification ${pair.$1}', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeApiAdapter(
          (request) =>
              throw DioException(requestOptions: request, type: pair.$1),
        );
      final response = await ApiClient(dio: dio).get('/Test');
      expect(response.success, isFalse);
      expect(response.errorType, pair.$2);
      expect(response.statusCode, isNull);
      expect(response.data, isNull);
      dio.close();
    });
  }

  test('Malformed JSON in an HTTP failure keeps the HTTP status', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeApiAdapter(
        (_) => ResponseBody.fromString(
          '{broken',
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
    final response = await ApiClient(dio: dio).get('/Test');
    expect(response.success, isFalse);
    expect(response.statusCode, 500);
    expect(response.errorType, ApiErrorType.http);
    dio.close();
  });

  test(
    'Native TLS handshake failure is classified without leaking exception text',
    () async {
      final dio = Dio()
        ..httpClientAdapter = FakeApiAdapter(
          (request) => throw DioException(
            requestOptions: request,
            type: DioExceptionType.unknown,
            error: const HandshakeException('sensitive certificate details'),
          ),
        );
      final result = await ApiClient(dio: dio).get('/Test');
      expect(result.success, isFalse);
      expect(result.errorType, ApiErrorType.tls);
      expect(result.message, isNot(contains('sensitive certificate details')));
      dio.close();
    },
  );
}
