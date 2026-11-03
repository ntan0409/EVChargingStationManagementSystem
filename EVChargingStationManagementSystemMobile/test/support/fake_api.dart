import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

const testBaseUrl = 'https://api.example.test/api';
const testAccountId = '10000000-0000-0000-0000-000000000001';
const testDriverId = '20000000-0000-0000-0000-000000000001';

// Synthetic token for fake-adapter tests only. The signature is deliberately
// not cryptographic; production must obtain verification from the backend.
String testToken({
  DateTime? expiresAt,
  String accountId = testAccountId,
  String role = 'EVDriver',
}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'userId': accountId, 'email': 'driver@example.test', 'name': 'Driver From Backend', 'role': role, 'exp': (expiresAt ?? DateTime.now().add(const Duration(hours: 1))).millisecondsSinceEpoch ~/ 1000})}.${base64Url.encode(List<int>.filled(32, 42)).replaceAll('=', '')}';
}

Map<String, dynamic> testProfile({
  String accountId = testAccountId,
  String name = 'Driver From Backend',
}) => {
  'id': testDriverId,
  'accountId': accountId,
  'name': name,
  'email': 'driver@example.test',
  'phoneNumber': '0912345678',
  'score': 15,
  'rankingName': null,
  // A completed profile fixture under the server journey contract. Incomplete
  // journey scenarios override these fields explicitly; never used at runtime.
  'vehicleModelIds': <String>['b0000000-0000-0000-0000-000000000001'],
  'profileCompleted': true,
  'missingRequirements': <String>[],
  'eligibleVehicleModelIds': <String>['b0000000-0000-0000-0000-000000000001'],
};

ResponseBody jsonResponse(Object? body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

class FakeApiAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];
  FakeApiAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
