import 'package:flutter_test/flutter_test.dart';
import '../lib/core/utils/validators.dart';

void main() {
  test('Accepts demo addresses and long email domain suffixes', () {
    expect(Validators.email('driver1@evcsms-demo.invalid'), isNull);
    expect(Validators.email('member@example.technology'), isNull);
    expect(Validators.email('member@example.com'), isNull);
    expect(Validators.email('member@'), isNotNull);
    expect(Validators.email('member@example.'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });
}
