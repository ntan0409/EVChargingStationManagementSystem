import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/constants/app_theme.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/core/utils/formatters.dart';
import 'package:ev_charging_station/models/charging_session_model.dart';
import 'package:ev_charging_station/providers/charging_session_provider.dart';
import 'package:ev_charging_station/providers/payment_provider.dart';
import 'package:ev_charging_station/providers/station_provider.dart';
import 'package:ev_charging_station/providers/voucher_provider.dart';
import 'package:ev_charging_station/services/charging_service.dart';
import 'package:ev_charging_station/services/payment_service.dart';
import 'package:ev_charging_station/services/station_service.dart';
import 'package:ev_charging_station/services/voucher_service.dart';
import 'package:ev_charging_station/views/charging/live_charging_screen.dart';
import 'package:ev_charging_station/views/payment/payment_checkout_screen.dart';
import 'package:ev_charging_station/views/payment/payment_status_screen.dart';
import 'package:ev_charging_station/views/payment/transaction_history_screen.dart';
import 'package:ev_charging_station/views/station/station_detail_screen.dart';
import 'package:ev_charging_station/views/vouchers/voucher_list_screen.dart';
import 'support/fake_api.dart';
import 'support/phase4_fixtures.dart';

class _ScreenSession extends ChargingSessionProvider {
  ChargingSessionModel? snapshot = ChargingSessionModel.fromJson(
    sessionDto(status: 'Completed', cost: 999999),
  );
  int resets = 0;
  @override
  ChargingSessionModel? get currentSession => snapshot;
  @override
  bool get isCharging => snapshot?.status == 'Charging';
  @override
  void resetSession() {
    snapshot = null;
    resets++;
    notifyListeners();
  }
}

void main() {
  late FakeApiAdapter adapter;
  ApiClient client(FutureOr<ResponseBody> Function(RequestOptions) handler) {
    adapter = FakeApiAdapter(handler);
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(dio.close);
    return ApiClient(dio: dio);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });
  Future<void> mount(
    WidgetTester tester,
    Widget screen,
    ApiClient api, {
    ChargingSessionProvider? charging,
    PaymentProvider? payment,
    VoucherProvider? voucher,
    StationProvider? stations,
  }) async {
    final chargeProvider = charging ?? _ScreenSession();
    final payProvider =
        payment ??
        PaymentProvider(paymentService: PaymentService(apiClient: api));
    final voucherProvider =
        voucher ??
        VoucherProvider(voucherService: VoucherService(apiClient: api));
    final stationProvider =
        stations ??
        StationProvider(stationService: StationService(apiClient: api));
    addTearDown(chargeProvider.dispose);
    addTearDown(payProvider.dispose);
    addTearDown(voucherProvider.dispose);
    addTearDown(stationProvider.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ChargingSessionProvider>.value(
            value: chargeProvider,
          ),
          ChangeNotifierProvider<PaymentProvider>.value(value: payProvider),
          ChangeNotifierProvider<VoucherProvider>.value(value: voucherProvider),
          ChangeNotifierProvider<StationProvider>.value(value: stationProvider),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
      ),
    );
  }

  ResponseBody readData(
    RequestOptions r, {
    bool pending = false,
    bool vnpay = false,
  }) {
    if (r.uri.path.endsWith('/methods')) {
      return jsonResponse({
        'data': [
          {
            'id': vnpay ? 'VNPay' : 'Offline',
            'name': 'Backend payment method',
            'available': true,
          },
        ],
      });
    }
    if (r.uri.path.contains('/Payment/session/')) {
      return jsonResponse({
        'data': quoteDto(paymentStatus: pending ? 'Initiated' : null),
      });
    }
    if (r.uri.path.endsWith('/profile')) {
      return jsonResponse({
        'data': {...testProfile(), 'score': 250},
      });
    }
    return jsonResponse({'data': []});
  }

  testWidgets(
    'History shows loading then backend empty, never sample receipts',
    (tester) async {
      final response = Completer<ResponseBody>();
      final api = client((_) => response.future);
      await mount(tester, const TransactionHistoryScreen(), api);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete(jsonResponse({'data': []}));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có giao dịch nào'), findsOneWidget);
      expect(find.textContaining('Landmark'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'History error can retry to a genuine DTO row without fabricated details',
    (tester) async {
      var failing = true;
      final api = client(
        (_) => failing
            ? jsonResponse({'message': 'History unavailable'}, status: 500)
            : jsonResponse({
                'data': [
                  {
                    ...transactionDto(),
                    'chargingSessionId': '4b4e827e-2a9a-4c5c-a006-801cd15fce80',
                    'paymentMethod': 'OFFLINE',
                    'paymentReference': 'CASH-FIXTURE-REFERENCE',
                  },
                ],
              }),
      );
      await mount(tester, const TransactionHistoryScreen(), api);
      await tester.pumpAndSettle();
      expect(find.text('History unavailable'), findsOneWidget);
      expect(find.text('Chưa có giao dịch nào'), findsNothing);
      failing = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('UNIT-LEDGER-REFERENCE'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsOneWidget);
      expect(
        find.text('Tham chiếu thanh toán: CASH-FIXTURE-REFERENCE'),
        findsOneWidget,
      );
      expect(
        find.textContaining('4b4e827e-2a9a-4c5c-a006-801cd15fce80'),
        findsOneWidget,
      );
      expect(find.textContaining('Điện nạp:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Offline API failure stays at checkout, keeps session and never shows success',
    (tester) async {
      final api = client(
        (r) => r.method == 'POST'
            ? jsonResponse({'message': 'Offline rejected'}, status: 500)
            : readData(r),
      );
      final charging = _ScreenSession();
      await mount(
        tester,
        const PaymentCheckoutScreen(),
        api,
        charging: charging,
      );
      await tester.pumpAndSettle();
      expect(find.text(Formatters.formatCurrency(55000)), findsOneWidget);
      expect(find.text(Formatters.formatCurrency(999999)), findsNothing);
      final button = find.widgetWithText(
        ElevatedButton,
        'Tạo yêu cầu thanh toán',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentStatusScreen), findsNothing);
      expect(charging.resets, 0);
      expect(charging.currentSession, isNotNull);
      expect(find.text('Offline rejected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Offline acknowledged request navigates to Pending and does not clear session',
    (tester) async {
      var pending = false;
      final api = client((r) {
        if (r.method == 'POST') {
          pending = true;
          return jsonResponse({'data': paymentDto()});
        }
        return readData(r, pending: pending);
      });
      final charging = _ScreenSession();
      await mount(
        tester,
        const PaymentCheckoutScreen(),
        api,
        charging: charging,
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        ElevatedButton,
        'Tạo yêu cầu thanh toán',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Đang chờ xác nhận thanh toán'), findsOneWidget);
      expect(find.text('Thanh toán đã được xác nhận'), findsNothing);
      expect(charging.resets, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Failure to launch backend VNPay URL never becomes success or re-POST',
    (tester) async {
      var pending = false;
      final api = client((r) {
        if (r.method == 'POST') {
          pending = true;
          return jsonResponse({
            'data':
                'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_SecureHash=unit-only',
          });
        }
        return readData(r, pending: pending, vnpay: true);
      });
      final charging = _ScreenSession();
      await mount(
        tester,
        PaymentCheckoutScreen(paymentLauncher: (_) async => false),
        api,
        charging: charging,
      );
      await tester.pumpAndSettle();
      final create = find.widgetWithText(
        ElevatedButton,
        'Tạo yêu cầu thanh toán',
      );
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final open = find.widgetWithText(ElevatedButton, 'Mở VNPAY Sandbox');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentStatusScreen), findsNothing);
      expect(charging.resets, 0);
      expect(adapter.requests.where((r) => r.method == 'POST').length, 1);
      expect(
        find.textContaining('Không mở được cổng thanh toán.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final status in ['Failed', 'Cancelled', 'Successed']) {
    testWidgets(
      'Status $status is backend-derived and clears session only for confirmed Paid',
      (tester) async {
        final api = client(
          (_) => jsonResponse({
            'data': quoteDto(
              sessionStatus: status == 'Successed' ? 'Paid' : 'Completed',
              paymentStatus: status,
            ),
          }),
        );
        final charging = _ScreenSession();
        await mount(
          tester,
          const PaymentStatusScreen(sessionId: sessionId),
          api,
          charging: charging,
        );
        await tester.pumpAndSettle();
        expect(charging.resets, status == 'Successed' ? 1 : 0);
        expect(
          find.text('Thanh toán đã được xác nhận'),
          status == 'Successed' ? findsOneWidget : findsNothing,
        );
        if (status == 'Failed') {
          expect(find.text('Thanh toán thất bại'), findsOneWidget);
        }
        if (status == 'Cancelled') {
          expect(find.text('Giao dịch đã hủy'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Payment verification timeout/error is not a paid receipt', (
    tester,
  ) async {
    final api = client(
      (_) => jsonResponse({'message': 'Cannot verify payment'}, status: 500),
    );
    final charging = _ScreenSession();
    await mount(
      tester,
      const PaymentStatusScreen(sessionId: sessionId),
      api,
      charging: charging,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cannot verify payment'), findsOneWidget);
    expect(find.text('Thanh toán đã được xác nhận'), findsNothing);
    expect(charging.resets, 0);
  });
  testWidgets('Failed stop remains on Live screen instead of checkout', (
    tester,
  ) async {
    final api = client(
      (r) => r.method == 'POST'
          ? jsonResponse({'data': sessionDto()})
          : jsonResponse({'message': 'Stop not accepted'}, status: 500),
    );
    final charging = ChargingSessionProvider(
      chargingService: ChargingService(apiClient: api),
      pollInterval: null,
    );
    await tester.runAsync(
      () => charging.startCharging(
        connectorId: connectorId,
        batteryCapacityKWh: 80,
        initialBatteryLevelPercent: 20,
        expectedEnergiesKWh: 80,
      ),
    );
    await mount(tester, const LiveChargingScreen(), api, charging: charging);
    await tester.pumpAndSettle();
    final stop = find.widgetWithText(ElevatedButton, 'Dừng sạc với số đo thực');
    await tester.ensureVisible(stop);
    await tester.pumpAndSettle();
    expect(stop.hitTestable(), findsOneWidget);
    await tester.tap(stop);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '10');
    await tester.tap(find.text('Gửi yêu cầu dừng'));
    await tester.pumpAndSettle();
    expect(charging.isCharging, isTrue);
    expect(find.byType(PaymentCheckoutScreen), findsNothing);
    expect(find.text('Stop not accepted'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Voucher redemption rejection is visible and does not claim copied/redeemed success',
    (tester) async {
      final api = client((r) {
        if (r.method == 'POST') {
          return jsonResponse({'message': 'Voucher expired'}, status: 409);
        }
        if (r.uri.path.endsWith('/profile')) {
          return jsonResponse({
            'data': {...testProfile(), 'score': 250},
          });
        }
        return jsonResponse({
          'data': r.uri.path.endsWith('/my') ? [] : [voucherDto()],
        });
      });
      await mount(tester, const VoucherListScreen(), api);
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        OutlinedButton,
        'Đổi voucher trên máy chủ',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Voucher expired'), findsWidgets);
      expect(find.textContaining('Đã sao chép'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Station detail failure has error/retry rather than endless spinner',
    (tester) async {
      final api = client(
        (_) => jsonResponse({'message': 'Station unavailable'}, status: 500),
      );
      await mount(tester, const StationDetailScreen(stationId: stationId), api);
      await tester.pumpAndSettle();
      expect(find.text('Station unavailable'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
