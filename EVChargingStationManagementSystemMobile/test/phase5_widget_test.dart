import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ev_charging_station/main.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/constants/app_theme.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/providers/booking_provider.dart';
import 'package:ev_charging_station/providers/vehicle_provider.dart';
import 'package:ev_charging_station/providers/charging_session_provider.dart';
import 'package:ev_charging_station/providers/notification_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:ev_charging_station/services/booking_service.dart';
import 'package:ev_charging_station/services/notification_service.dart';
import 'package:ev_charging_station/views/auth/login_screen.dart';
import 'package:ev_charging_station/views/home/home_screen.dart';
import 'package:ev_charging_station/views/booking/my_bookings_screen.dart';
import 'package:ev_charging_station/views/booking/checkin_qr_screen.dart';
import 'package:ev_charging_station/views/notifications/notification_screen.dart';
import 'package:ev_charging_station/views/profile/change_password_screen.dart';
import 'support/fake_api.dart';
import 'support/fake_google_identity.dart';
import 'phase5_data_test.dart' show bookingFixture, notificationFixture;
import 'package:ev_charging_station/models/booking_model.dart';

class _EmptyVehicles extends VehicleProvider {
  @override
  Future<void> fetchVehicles() async {}
}

class _EmptyCharging extends ChargingSessionProvider {
  _EmptyCharging() : super(pollInterval: null);
  @override
  Future<bool> refreshSession() async => false;
}

void main() {
  ApiClient client(FutureOr<ResponseBody> Function(RequestOptions) handler) {
    final dio = Dio()..httpClientAdapter = FakeApiAdapter(handler);
    addTearDown(dio.close);
    return ApiClient(dio: dio);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });
  for (final width in [320.0, 768.0, 1440.0]) {
    for (final screen in ['booking', 'notification']) {
      testWidgets('$screen real DTO long text renders at width $width', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final long = List.filled(12, 'Tên trạm và thông tin rất dài').join(' ');
        final api = client(
          (r) => r.path.endsWith('unread-count')
              ? jsonResponse({'count': 1})
              : jsonResponse({
                  'data': screen == 'booking'
                      ? [
                          {
                            ...bookingFixture(),
                            'stationName': long,
                            'location': long,
                            'checkInCode': long,
                          },
                        ]
                      : [
                          {
                            ...notificationFixture(),
                            'title': long,
                            'message': long,
                          },
                        ],
                }),
        );
        final booking = BookingProvider(
          bookingService: BookingService(apiClient: api),
        );
        final notification = NotificationProvider(
          service: NotificationService(apiClient: api),
        );
        addTearDown(booking.dispose);
        addTearDown(notification.dispose);
        if (screen == 'notification') {
          await tester.runAsync(notification.fetchNotifications);
        }
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: booking),
              ChangeNotifierProvider.value(value: notification),
              ChangeNotifierProvider<VehicleProvider>(
                create: (_) => _EmptyVehicles(),
              ),
              ChangeNotifierProvider<ChargingSessionProvider>(
                create: (_) => _EmptyCharging(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: screen == 'booking'
                  ? const MyBookingsScreen()
                  : const NotificationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('8942'), findsNothing);
        expect(find.textContaining('75.000'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'Notification error is visible and retry fetches empty server state',
    (tester) async {
      var fail = true;
      final provider = NotificationProvider(
        service: NotificationService(
          apiClient: client(
            (r) => fail
                ? jsonResponse({'message': 'Offline'}, status: 500)
                : r.path.endsWith('unread-count')
                ? jsonResponse({'count': 0})
                : jsonResponse({'data': []}),
          ),
        ),
      );
      addTearDown(provider.dispose);
      await tester.runAsync(provider.fetchNotifications);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      expect(find.text('Offline'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không có thông báo mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Missing backend check-in code never produces a QR code', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CheckinQrScreen(
          booking: BookingModel.fromJson({
            ...bookingFixture(),
            'checkInCode': null,
          }),
        ),
      ),
    );
    expect(find.textContaining('Máy chủ chưa cung cấp'), findsOneWidget);
    expect(find.text('8942'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Password change preserves spaces and popping during request is safe',
    (tester) async {
      final pending = Completer<ResponseBody>();
      Map? payload;
      final service = AuthService(
        apiClient: client((r) {
          payload = r.data;
          return pending.future;
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(authService: service),
                  ),
                ),
                child: const Text('Open password'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open password'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'OldSecret9!  ');
      await tester.enterText(fields.at(1), 'NewSecret9!  ');
      await tester.enterText(fields.at(2), 'NewSecret9!  ');
      await tester.ensureVisible(find.text('Cập Nhật Mật Khẩu'));
      await tester.tap(find.text('Cập Nhật Mật Khẩu'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(payload?['oldPassword'], 'OldSecret9!  ');
      expect(payload?['newPassword'], 'NewSecret9!  ');
      await tester.pageBack();
      await tester.pumpAndSettle();
      pending.complete(jsonResponse({'message': 'Changed'}));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Logout removes private pushed routes and system back cannot reopen them',
    (tester) async {
      final api = client(
        (r) => r.path.endsWith('/Auth/login')
            ? jsonResponse({
                'token': testToken(),
                'expiration': DateTime.now()
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
              })
            : jsonResponse({'data': testProfile()}),
      );
      late AuthProvider auth;
      await tester.runAsync(() async {
        auth = AuthProvider(
          authService: AuthService(apiClient: api),
          googleIdentity: FakeGoogleIdentity(),
        );
        expect(await auth.login('fixture', 'fixture'), isTrue);
      });
      await tester.pumpWidget(EVChargingApp(authProvider: auth));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      final navigator = Navigator.of(tester.element(find.byType(HomeScreen)));
      unawaited(
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('PRIVATE DETAIL')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE DETAIL'), findsOneWidget);
      await tester.runAsync(auth.logout);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('PRIVATE DETAIL'), findsNothing);
      expect(navigator.canPop(), isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE DETAIL'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
