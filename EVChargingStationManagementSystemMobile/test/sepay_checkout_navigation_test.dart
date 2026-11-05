import 'package:flutter_test/flutter_test.dart';
import 'package:ev_charging_station/views/payment/sepay_checkout_screen.dart';

void main() {
  final initial = Uri.parse(
    'http://10.0.2.2:5058/api/Payment/sepay-sandbox/checkout?ticket=test',
  );
  test('Allows exact backend capability form and sandbox card pages', () {
    expect(isSePayCheckoutNavigationAllowed(initial, initial), isTrue);
    expect(
      isSePayCheckoutNavigationAllowed(
        Uri.parse('https://pay-sandbox.sepay.vn/v1/mpgs/checkout?order=test'),
        initial,
      ),
      isTrue,
    );
  });
  for (final url in [
    'http://pay-sandbox.sepay.vn/v1/checkout',
    'https://pay.sepay.vn/v1/checkout',
    'https://pay-sandbox.sepay.vn.evil.test/',
    'https://user@pay-sandbox.sepay.vn/',
    'https://pay-sandbox.sepay.vn:444/',
    'intent://payment',
    'file:///sdcard/test',
    'http://10.0.2.2:5058/api/other',
    'http://10.0.2.2:5058/api/Payment/sepay-sandbox/checkout?ticket=other',
  ]) {
    test('Blocks checkout escape $url', () {
      expect(
        isSePayCheckoutNavigationAllowed(Uri.parse(url), initial),
        isFalse,
      );
    });
  }
}
