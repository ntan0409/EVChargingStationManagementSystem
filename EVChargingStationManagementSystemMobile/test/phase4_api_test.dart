import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/core/network/api_response.dart';
import 'package:ev_charging_station/models/payment_model.dart';
import 'package:ev_charging_station/models/transaction_model.dart';
import 'package:ev_charging_station/models/voucher_model.dart';
import 'package:ev_charging_station/providers/charging_session_provider.dart';
import 'package:ev_charging_station/providers/payment_provider.dart';
import 'package:ev_charging_station/providers/voucher_provider.dart';
import 'package:ev_charging_station/services/charging_service.dart';
import 'package:ev_charging_station/services/payment_service.dart';
import 'package:ev_charging_station/services/station_service.dart';
import 'package:ev_charging_station/services/vehicle_service.dart';
import 'package:ev_charging_station/services/voucher_service.dart';
import 'support/fake_api.dart';
import 'support/phase4_fixtures.dart';

void main() {
  late FakeApiAdapter adapter;
  ApiClient client(FutureOr<ResponseBody> Function(RequestOptions) handler) {
    adapter = FakeApiAdapter(handler);
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(dio.close);
    return ApiClient(dio: dio);
  }

  Future<bool> start(ChargingSessionProvider provider) =>
      provider.startCharging(
        connectorId: connectorId,
        batteryCapacityKWh: 80,
        initialBatteryLevelPercent: 20,
        expectedEnergiesKWh: 80,
        vehicleModelId: vehicleId,
      );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });

  for (final status in [400, 401, 403, 409, 500]) {
    test('Charging rejection HTTP$status has no fake session', () async {
      final service = ChargingService(
        apiClient: client(
          (_) => jsonResponse({'message': 'Rejected'}, status: status),
        ),
      );
      final result = await service.startSession(
        connectorId: connectorId,
        batteryCapacityKWh: 80,
        initialBatteryLevelPercent: 20,
        expectedEnergiesKWh: 80,
      );
      expect(result.success, isFalse);
      expect(result.data, isNull);
      expect(result.statusCode, status);
      expect(
        (adapter.requests.single.data as Map).containsKey('phone'),
        isFalse,
      );
    });
  }
  test(
    'Start keeps server ID and snapshot; ignores caller display price',
    () async {
      final provider = ChargingSessionProvider(
        pollInterval: null,
        chargingService: ChargingService(
          apiClient: client(
            (_) => jsonResponse({'data': sessionDto(cost: 123)}),
          ),
        ),
      );
      addTearDown(provider.dispose);
      expect(
        await provider.startCharging(
          connectorId: connectorId,
          batteryCapacityKWh: 80,
          initialBatteryLevelPercent: 20,
          expectedEnergiesKWh: 80,
          price: 999999,
        ),
        isTrue,
      );
      expect(provider.currentSession!.id, sessionId);
      expect(provider.currentSession!.cost, 123);
      expect(provider.currentSession!.hasMeasuredBatteryPercent, isFalse);
    },
  );
  for (final bad in [
    <String, dynamic>{},
    {...sessionDto(), 'id': 'sess-local'},
    {...sessionDto(), 'status': null},
  ]) {
    test('Malformed session is rejected: ${bad['id']}', () async {
      final result =
          await ChargingService(
            apiClient: client((_) => jsonResponse({'data': bad})),
          ).startSession(
            connectorId: connectorId,
            batteryCapacityKWh: 80,
            initialBatteryLevelPercent: 20,
            expectedEnergiesKWh: 80,
          );
      expect(result.success, isFalse);
      expect(result.errorType, ApiErrorType.parse);
    });
  }
  test('Stop sends explicit measured energy and query session ID', () async {
    final service = ChargingService(
      apiClient: client(
        (_) => jsonResponse({
          'data': sessionDto(status: 'Completed', energy: 12.5),
        }),
      ),
    );
    final result = await service.stopSession(
      sessionId,
      energyDeliveredKWh: 12.5,
    );
    expect(result.success, isTrue);
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.queryParameters, {'sessionId': sessionId});
    expect(adapter.requests.single.data, {'energyDeliveredKWh': 12.5});
  });
  for (final energy in [null, -1.0, double.nan, double.infinity]) {
    test(
      'Stop rejects missing/nonfinite/negative meter value $energy',
      () async {
        final service = ChargingService(
          apiClient: client((_) => throw StateError('Must not call API')),
        );
        expect(
          (await service.stopSession(
            sessionId,
            energyDeliveredKWh: energy,
          )).success,
          isFalse,
        );
        expect(adapter.requests, isEmpty);
      },
    );
  }
  test('Failed stop preserves active session and server cost', () async {
    final provider = ChargingSessionProvider(
      pollInterval: null,
      chargingService: ChargingService(
        apiClient: client(
          (request) => request.method == 'POST'
              ? jsonResponse({'data': sessionDto()})
              : jsonResponse({'message': 'Stop rejected'}, status: 500),
        ),
      ),
    );
    addTearDown(provider.dispose);
    expect(await start(provider), isTrue);
    expect(await provider.stopCharging(energyDeliveredKWh: 10), isFalse);
    expect(provider.isCharging, isTrue);
    expect(provider.currentSession!.cost, 50000);
    expect(provider.errorMessage, 'Stop rejected');
  });
  test(
    'Successful stop uses backend Completed and bill, not local calculation',
    () async {
      final provider = ChargingSessionProvider(
        pollInterval: null,
        chargingService: ChargingService(
          apiClient: client(
            (request) => jsonResponse({
              'data': request.method == 'POST'
                  ? sessionDto()
                  : sessionDto(status: 'Completed', energy: 12, cost: 77777),
            }),
          ),
        ),
      );
      addTearDown(provider.dispose);
      await start(provider);
      expect(await provider.stopCharging(energyDeliveredKWh: 12), isTrue);
      expect(provider.currentSession!.cost, 77777);
      expect(provider.isCharging, isFalse);
    },
  );
  test(
    'Polling performs only GET and never synthesizes energy or completion',
    () async {
      final provider = ChargingSessionProvider(
        pollInterval: const Duration(milliseconds: 5),
        chargingService: ChargingService(
          apiClient: client((_) => jsonResponse({'data': sessionDto()})),
        ),
      );
      addTearDown(provider.dispose);
      await start(provider);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
      expect(adapter.requests.any((r) => r.method == 'GET'), isTrue);
      expect(provider.currentSession!.totalEnergyConsumedKWh, 10);
      expect(provider.currentSession!.cost, 50000);
      expect(provider.isCharging, isTrue);
    },
  );
  test(
    'Create session is single-flight and late result after reset is ignored',
    () async {
      final completer = Completer<ResponseBody>();
      final provider = ChargingSessionProvider(
        pollInterval: null,
        chargingService: ChargingService(
          apiClient: client((_) => completer.future),
        ),
      );
      addTearDown(provider.dispose);
      final first = start(provider);
      expect(await start(provider), isFalse);
      provider.resetSession();
      completer.complete(jsonResponse({'data': sessionDto()}));
      expect(await first, isFalse);
      expect(provider.currentSession, isNull);
      expect(adapter.requests.length, 1);
    },
  );
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  ]) {
    test(
      'Ambiguous charging $type requires GET reconciliation, no mutation retry',
      () async {
        final provider = ChargingSessionProvider(
          pollInterval: null,
          chargingService: ChargingService(
            apiClient: client((request) {
              if (request.method == 'GET') {
                return jsonResponse({
                  'message': 'No current session',
                }, status: 404);
              }
              throw DioException(requestOptions: request, type: type);
            }),
          ),
        );
        addTearDown(provider.dispose);
        expect(await start(provider), isFalse);
        expect(provider.needsReconciliation, isTrue);
        expect(await start(provider), isFalse);
        expect(adapter.requests.length, 1);
        expect(await provider.restoreSession(), isTrue);
        expect(provider.needsReconciliation, isFalse);
        expect(adapter.requests.last.method, 'GET');
      },
    );
  }
  test('Session lookup cannot accept another session ID', () async {
    final service = ChargingService(
      apiClient: client(
        (_) => jsonResponse({
          'data': {...sessionDto(), 'id': otherId},
        }),
      ),
    );
    expect((await service.getSessionById(sessionId)).success, isFalse);
  });

  for (final status in [400, 401, 403, 409, 500]) {
    test('Payment HTTP$status never generates a URL', () async {
      final provider = PaymentProvider(
        paymentService: PaymentService(
          apiClient: client(
            (_) => jsonResponse({'message': 'No payment'}, status: status),
          ),
        ),
      );
      addTearDown(provider.dispose);
      expect(await provider.generateVNPayUrl(sessionId), isNull);
      expect(provider.vnpayUrl, isNull);
      expect(provider.errorMessage, 'No payment');
      expect(adapter.requests.length, 1);
    });
  }
  for (final url in [
    null,
    '',
    'http://gateway.invalid',
    'javascript:alert(1)',
    'https://gateway.invalid/no-signature',
  ]) {
    test('Malformed payment URL is not accepted: $url', () async {
      final service = PaymentService(
        apiClient: client((_) => jsonResponse({'data': url})),
      );
      expect((await service.createVNPayUrl(sessionId)).success, isFalse);
    });
  }
  test(
    'Offline failure cannot add a local ledger row or claim success',
    () async {
      final provider = PaymentProvider(
        paymentService: PaymentService(
          apiClient: client(
            (_) => jsonResponse({'message': 'Not created'}, status: 500),
          ),
        ),
      );
      addTearDown(provider.dispose);
      expect(
        await provider.processOfflinePayment(
          sessionId,
          1,
          'Ignored label',
          999,
        ),
        isFalse,
      );
      expect(provider.history, isEmpty);
      expect(provider.errorMessage, 'Not created');
    },
  );
  test(
    'Acknowledged offline request remains Initiated and never creates history locally',
    () async {
      final provider = PaymentProvider(
        paymentService: PaymentService(
          apiClient: client((_) => jsonResponse({'data': paymentDto()})),
        ),
      );
      addTearDown(provider.dispose);
      expect(
        await provider.processOfflinePayment(sessionId, 1, 'Ignored', 999),
        isTrue,
      );
      expect(provider.history, isEmpty);
      expect(adapter.requests.single.queryParameters, {'sessionId': sessionId});
      expect(adapter.requests.single.data, isNull);
    },
  );
  for (final status in [
    'Initiated',
    'Successed',
    'Failed',
    'Cancelled',
    'Unknown',
  ]) {
    test('Payment state $status requires matching server Paid session', () {
      final pendingSession = SessionPaymentModel.fromJson(
        quoteDto(paymentStatus: status),
      );
      final paidSession = SessionPaymentModel.fromJson(
        quoteDto(sessionStatus: 'Paid', paymentStatus: status),
      );
      expect(pendingSession.isPaid, isFalse);
      expect(paidSession.isPaid, status == 'Successed');
    });
  }
  test('Missing payment status never defaults to Paid', () {
    expect(
      () => PaymentModel.fromJson({...paymentDto(), 'status': null}),
      throwsFormatException,
    );
  });
  test('Mismatched invoice/payment session is rejected', () {
    expect(
      () => SessionPaymentModel.fromJson({
        ...quoteDto(),
        'payment': {...paymentDto(), 'chargingSessionId': otherId},
      }),
      throwsFormatException,
    );
  });
  test('Inconsistent quote and payment amounts are rejected', () {
    expect(
      () => SessionPaymentModel.fromJson({
        ...quoteDto(),
        'payment': paymentDto(),
        'amount': 1,
      }),
      throwsFormatException,
    );
  });
  for (final status in [200, 404, 500]) {
    test(
      'History HTTP$status distinguishes empty collection from failure',
      () async {
        final result = await PaymentService(
          apiClient: client(
            (_) => jsonResponse(
              status == 200 ? {'data': []} : {'message': 'No rows'},
              status: status,
            ),
          ),
        ).getPaymentHistory();
        expect(result.success, status != 500);
        if (status == 500) {
          expect(result.data, isNull);
        } else {
          expect(result.data, isEmpty);
        }
      },
    );
  }
  test(
    'History maps a ledger entry without invented session, date or station',
    () async {
      final result = await PaymentService(
        apiClient: client(
          (_) => jsonResponse({
            'data': [transactionDto()],
          }),
        ),
      ).getPaymentHistory();
      expect(result.data!.single.referenceCode, 'UNIT-LEDGER-REFERENCE');
      expect(result.data!.single.paymentId, paymentId);
      expect(result.data!.single.id, transactionId);
      final minimal = TransactionModel.fromJson({
        'id': transactionId,
        'referenceCode': 'Server-ref',
        'amount': -12,
        'transactionType': 'Adjustment',
        'status': 'Completed',
      });
      expect(minimal.amount, -12);
      expect(minimal.initiatedAt, isNull);
    },
  );
  test('Payment timeout produces failure and does not auto-retry', () async {
    final service = PaymentService(
      apiClient: client(
        (r) => throw DioException(
          requestOptions: r,
          type: DioExceptionType.receiveTimeout,
        ),
      ),
    );
    expect(
      (await service.createVNPayUrl(sessionId)).errorType,
      ApiErrorType.timeout,
    );
    expect(adapter.requests.length, 1);
  });

  for (final type in ['Discount', 'Amount']) {
    test(
      'Voucher $type reads backend value/type/points without fabricated cap',
      () {
        final voucher = VoucherModel.fromJson(voucherDto(type: type));
        expect(voucher.voucherType, type);
        expect(voucher.pointsRequired, 100);
        expect(voucher.isValid, isTrue);
      },
    );
  }
  test('Expired/unknown/incomplete voucher cannot look valid', () {
    expect(VoucherModel.fromJson(voucherDto(expired: true)).isValid, isFalse);
    expect(
      () => VoucherModel.fromJson({...voucherDto(), 'voucherType': 'Mystery'}),
      throwsFormatException,
    );
    expect(
      () => VoucherModel.fromJson({...voucherDto(), 'validTo': null}),
      throwsFormatException,
    );
  });
  for (final status in [401, 500]) {
    test(
      'Voucher API HTTP$status returns failure without demo vouchers',
      () async {
        final result = await VoucherService(
          apiClient: client(
            (_) => jsonResponse({'message': 'Unavailable'}, status: status),
          ),
        ).getAvailableVouchers();
        expect(result.success, isFalse);
        expect(result.data, isNull);
      },
    );
  }
  test(
    'Use voucher sends owned voucher ID and session ID, validates Used confirmation',
    () async {
      final service = VoucherService(
        apiClient: client(
          (_) => jsonResponse({'data': ownedDto(status: 'Used')}),
        ),
      );
      expect((await service.useVoucher(ownedId, sessionId)).success, isTrue);
      expect(
        adapter.requests.single.uri.path,
        '/api/Voucher/use/$ownedId/$sessionId',
      );
    },
  );
  test(
    'Voucher cannot be treated as applied from an unconfirmed or foreign response',
    () async {
      final service = VoucherService(
        apiClient: client((_) => jsonResponse({'data': ownedDto()})),
      );
      expect((await service.useVoucher(ownedId, sessionId)).success, isFalse);
    },
  );
  test(
    'Redeem rejection keeps server error and does not insert an owned voucher',
    () async {
      final provider = VoucherProvider(
        voucherService: VoucherService(
          apiClient: client(
            (_) => jsonResponse({
              'message': 'Expired or insufficient points',
            }, status: 409),
          ),
        ),
      );
      addTearDown(provider.dispose);
      expect(await provider.redeemVoucher(voucherId), isFalse);
      expect(provider.ownedVouchers, isEmpty);
      expect(provider.errorMessage, 'Expired or insufficient points');
    },
  );
  test(
    'Successful redemption refreshes catalog, ownership and balance from backend',
    () async {
      final provider = VoucherProvider(
        voucherService: VoucherService(
          apiClient: client((r) {
            if (r.method == 'POST') return jsonResponse({'data': ownedDto()});
            if (r.uri.path.endsWith('/profile')) {
              return jsonResponse({
                'data': {...testProfile(), 'score': 150},
              });
            }
            return jsonResponse({
              'data': r.uri.path.endsWith('/my')
                  ? [ownedDto()]
                  : [voucherDto()],
            });
          }),
        ),
      );
      addTearDown(provider.dispose);
      expect(await provider.redeemVoucher(voucherId), isTrue);
      expect(provider.points, 150);
      expect(provider.ownedVouchers.single.id, ownedId);
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
    },
  );
  test(
    'Account change clears private payment/voucher/session state and ignores late response',
    () async {
      final completer = Completer<ResponseBody>();
      final provider = PaymentProvider(
        paymentService: PaymentService(
          apiClient: client((_) => completer.future),
        ),
      );
      addTearDown(provider.dispose);
      provider.bindAccount(testAccountId);
      final request = provider.fetchHistory();
      provider.bindAccount(otherId);
      completer.complete(
        jsonResponse({
          'data': [transactionDto()],
        }),
      );
      await request;
      expect(provider.history, isEmpty);
    },
  );

  test('Station HTTP500/empty response never becomes demo stations', () async {
    final service = StationService(
      apiClient: client(
        (_) => jsonResponse({'message': 'No backend'}, status: 500),
      ),
    );
    expect((await service.getStations()).success, isFalse);
    expect((await service.getStationById(stationId)).success, isFalse);
  });
  test(
    'Station details hydrate post connectors and QR resolves real parent chain',
    () async {
      final service = StationService(
        apiClient: client(
          (r) => jsonResponse({
            'data': r.uri.path.contains('/Connector/')
                ? connectorDto()
                : r.uri.path.contains('/ChargingPost/')
                ? postDto()
                : stationDto(detail: true),
          }),
        ),
      );
      final detail = await service.getStationById(stationId);
      expect(detail.success, isTrue);
      expect(
        detail.data!.chargingPosts.single.connectors.single.canStart,
        isTrue,
      );
      expect(detail.data!.chargingPosts.single.connectors.single.type, 'CCS2');
      final location = await service.resolveConnector(connectorId);
      expect(location.data!.station.id, stationId);
      expect(location.data!.connector.id, connectorId);
    },
  );
  test(
    'Unknown QR format is rejected before API and cannot construct a fake connector',
    () async {
      final service = StationService(
        apiClient: client((_) => throw StateError('No request expected')),
      );
      expect((await service.resolveConnector('CONN-01')).success, isFalse);
      expect(adapter.requests, isEmpty);
    },
  );
  test('Vehicle API failure has no catalog fallback', () async {
    final result = await VehicleService(
      apiClient: client(
        (_) => jsonResponse({'message': 'No vehicles'}, status: 500),
      ),
    ).getVehicleModels();
    expect(result.success, isFalse);
    expect(result.data, isNull);
  });
  test(
    'Driver with an empty server garage remains empty, not the global catalog',
    () async {
      final result = await VehicleService(
        apiClient: client(
          (_) => jsonResponse({
            'data': {
              ...testProfile(),
              'vehicleModelIds': <String>[],
              'profileCompleted': false,
              'eligibleVehicleModelIds': <String>[],
            },
          }),
        ),
      ).getMyVehicleModels();
      expect(result.success, isTrue);
      expect(result.data, isEmpty);
      expect(adapter.requests.length, 1);
    },
  );
}
