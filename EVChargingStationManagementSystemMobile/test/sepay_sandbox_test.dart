import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/services/payment_service.dart';
import 'support/fake_api.dart';
import 'support/phase4_fixtures.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });
  PaymentService service(Object response) {
    final dio = Dio()
      ..httpClientAdapter = FakeApiAdapter(
        (_) => jsonResponse({'data': response}),
      );
    addTearDown(dio.close);
    return PaymentService(apiClient: ApiClient(dio: dio));
  }

  test('Checkout retains the configured reachable API host', () async {
    final result = await service(
      'Payment/sepay-sandbox/checkout?ticket=protected',
    ).sandboxLink(sessionId);
    expect(result.success, isTrue);
    expect(
      result.data,
      '$testBaseUrl/Payment/sepay-sandbox/checkout?ticket=protected',
    );
  });
  for (final bad in [
    'https://evil.test/pay?ticket=abc',
    '//evil.test/pay?ticket=abc',
    'Payment/other?ticket=abc',
    'Payment/sepay-sandbox/checkout',
  ]) {
    test('Reject unexpected checkout link $bad', () async {
      expect((await service(bad).sandboxLink(sessionId)).success, isFalse);
    });
  }
}
