import 'package:dio/dio.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/constants/app_theme.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/models/vehicle_model.dart';
import 'package:ev_charging_station/models/station_model.dart';
import 'package:ev_charging_station/models/charging_session_model.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/providers/booking_provider.dart';
import 'package:ev_charging_station/providers/charging_session_provider.dart';
import 'package:ev_charging_station/providers/notification_provider.dart';
import 'package:ev_charging_station/providers/station_provider.dart';
import 'package:ev_charging_station/providers/theme_provider.dart';
import 'package:ev_charging_station/providers/vehicle_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:ev_charging_station/views/auth/login_screen.dart';
import 'package:ev_charging_station/views/home/home_screen.dart';
import 'package:ev_charging_station/views/main_navigation_screen.dart';
import 'package:ev_charging_station/views/profile/change_password_screen.dart';
import 'package:ev_charging_station/views/profile/profile_screen.dart';
import 'package:ev_charging_station/views/map/station_map_screen.dart';
import 'package:ev_charging_station/views/charging/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_api.dart';

class _Stations extends StationProvider {
  int fetches = 0;
  @override
  List<StationModel> get stations => [
    StationModel(
      id: 'test-station',
      stationName: 'Trạm sạc có tên rất dài để kiểm tra bố cục',
      location: 'Địa chỉ trạm sạc dài trên màn hình hẹp',
      province: 'TP.HCM',
      latitude: 10.7769,
      longitude: 106.7009,
      pricePerKWh: 12345,
      distanceKm: 12.34,
      totalCarChargingConnectors: 12,
      availableCarConnectors: 5,
    ),
  ];
  @override
  Future<void> fetchStations() async {
    fetches++;
  }
}

class _Vehicles extends VehicleProvider {
  int fetches = 0;
  @override
  Future<void> fetchVehicles() async {
    fetches++;
  }

  @override
  VehicleModel? get selectedVehicle => VehicleModel(
    id: 'test-vehicle',
    modelName: 'Xe điện với tên mẫu xe dài để kiểm tra màn hình nhỏ',
    batteryCapacityKWh: 87,
  );
}

class _Notifications extends NotificationProvider {
  int fetches = 0;
  @override
  Future<void> fetchNotifications() async {
    fetches++;
  }
}

class _Bookings extends BookingProvider {
  int fetches = 0;
  @override
  Future<void> fetchMyBookings() async {
    fetches++;
  }
}

class _ActiveCharging extends ChargingSessionProvider {
  @override
  bool get isCharging => true;
  @override
  ChargingSessionModel? get currentSession => ChargingSessionModel(
    id: '30000000-0000-0000-0000-000000000001',
    chargingPostId: '40000000-0000-0000-0000-000000000001',
    status: 'Charging',
    currentBatteryPercent: 40,
    totalEnergyConsumedKWh: 15.5,
    cost: 1234567,
  );
}

Future<
  ({
    AuthProvider auth,
    _Stations stations,
    _Vehicles vehicles,
    _Notifications notifications,
    _Bookings bookings,
  })
>
mount(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  bool dark = false,
  bool authenticated = true,
  int profileStatus = 200,
  double textScale = 1,
  String name = 'Tên người dùng rất dài để kiểm tra bố cục',
  ChargingSessionProvider? chargingProvider,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final auth = (await tester.runAsync(() async {
    await ApiConstants.setBaseUrl(testBaseUrl);
    final token = testToken();
    final dio = Dio()
      ..httpClientAdapter = FakeApiAdapter(
        (request) => request.uri.path.endsWith('/profile')
            ? jsonResponse({
                'data': testProfile(name: name),
              }, status: profileStatus)
            : jsonResponse({'token': token}),
      );
    addTearDown(dio.close);
    final provider = AuthProvider(
      authService: AuthService(apiClient: ApiClient(dio: dio)),
    );
    if (authenticated) {
      await provider.login(
        'driver@example.test',
        'test-password',
        rememberMe: false,
      );
    }
    return provider;
  }))!;
  final stations = _Stations();
  final vehicles = _Vehicles();
  final notifications = _Notifications();
  final bookings = _Bookings();
  final charging = chargingProvider ?? ChargingSessionProvider();
  final theme = ThemeProvider();
  for (final provider in [
    auth,
    stations,
    vehicles,
    notifications,
    bookings,
    charging,
    theme,
  ]) {
    addTearDown(provider.dispose);
  }
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<StationProvider>.value(value: stations),
        ChangeNotifierProvider<VehicleProvider>.value(value: vehicles),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notifications,
        ),
        ChangeNotifierProvider<BookingProvider>.value(value: bookings),
        ChangeNotifierProvider<ChargingSessionProvider>.value(value: charging),
        ChangeNotifierProvider<ThemeProvider>.value(value: theme),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump();
  return (
    auth: auth,
    stations: stations,
    vehicles: vehicles,
    notifications: notifications,
    bookings: bookings,
  );
}

void main() {
  testWidgets('Live banner keeps full-width button bounded on a small screen', (
    tester,
  ) async {
    await mount(
      tester,
      const HomeScreen(),
      size: const Size(320, 800),
      chargingProvider: _ActiveCharging(),
    );
    final button = find.widgetWithText(
      ElevatedButton,
      'Mở Bảng Điều Khiển Sạc (Live Telemetry)',
    );
    final width = tester.getSize(button).width;
    expect(width.isFinite, isTrue);
    expect(width, 248);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Home width=$width dark=$dark has finite promo button and no layout errors',
        (tester) async {
          await mount(
            tester,
            const HomeScreen(),
            size: Size(width, 900),
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          final button = find.widgetWithText(ElevatedButton, 'Nhận ngay');
          final size = tester.getSize(button);
          expect(size.width.isFinite, isTrue);
          expect(size.width, greaterThan(0));
          expect(size.width, lessThan(width));
          await tester.ensureVisible(button);
          await tester.pump();
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets(
        'Profile width=$width dark=$dark renders menu Material without errors',
        (tester) async {
          await mount(
            tester,
            const ProfileScreen(),
            size: Size(width, 900),
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          final tiles = find.byType(ListTile);
          expect(tiles, findsWidgets);
          for (final element in tiles.evaluate()) {
            expect(Material.of(element), isNotNull);
          }
        },
      );
    }
  }

  testWidgets(
    'Home/Profile small screen support larger text and empty display name',
    (tester) async {
      await mount(
        tester,
        const HomeScreen(),
        size: const Size(320, 640),
        textScale: 1.3,
        name: '',
      );
      expect(tester.takeException(), isNull);
      await mount(
        tester,
        const ProfileScreen(),
        size: const Size(320, 640),
        textScale: 1.3,
        name: '',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile menu tap navigates and logout dialog buttons are bounded',
    (tester) async {
      await mount(tester, const ProfileScreen());
      final tile = find.widgetWithText(ListTile, 'Đổi mật khẩu');
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      final logout = find.widgetWithText(OutlinedButton, 'Đăng Xuất Tài Khoản');
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'Navigation lazy loads tabs once and preserves Home/Profile scroll positions',
    (tester) async {
      final state = await mount(tester, const MainNavigationScreen());
      expect(state.auth.isAuthenticated, isTrue);
      expect(state.stations.fetches, 1);
      expect(state.vehicles.fetches, 1);
      expect(state.notifications.fetches, 1);
      expect(state.bookings.fetches, 0);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
      final homeScroll = find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(homeScroll, const Offset(0, -250));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(of: homeScroll, matching: find.byType(Scrollable))
          .first;
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      await tester.tap(find.text('Lịch đặt'));
      await tester.pumpAndSettle();
      expect(state.bookings.fetches, 1);
      await tester.tap(find.text('Tài khoản'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        closeTo(offset, 0.1),
      );
      await tester.tap(find.text('Lịch đặt'));
      await tester.pumpAndSettle();
      expect(state.bookings.fetches, 1);
      expect(state.notifications.fetches, 1);
      expect(state.stations.fetches, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Navigation with no verified session renders Login without fetching tab data',
    (tester) async {
      final state = await mount(
        tester,
        const MainNavigationScreen(),
        authenticated: false,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen, skipOffstage: false), findsNothing);
      expect(state.stations.fetches, 0);
      expect(state.bookings.fetches, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile initial tab is lazy and preserves its scroll state', (
    tester,
  ) async {
    final state = await mount(
      tester,
      const MainNavigationScreen(initialIndex: 4),
    );
    expect(state.stations.fetches, 0);
    expect(state.vehicles.fetches, 0);
    expect(state.notifications.fetches, 0);
    expect(state.bookings.fetches, 0);
    final scroll = find.byKey(const PageStorageKey('profile-scroll'));
    await tester.drag(scroll, const Offset(0, -250));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(of: scroll, matching: find.byType(Scrollable))
        .first;
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      closeTo(offset, 0.1),
    );
    expect(state.stations.fetches, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Map and scanner are unmounted until selected; scanner is released on leaving',
    (tester) async {
      final state = await mount(tester, const MainNavigationScreen());
      expect(find.byType(StationMapScreen, skipOffstage: false), findsNothing);
      expect(find.byType(QrScannerScreen, skipOffstage: false), findsNothing);
      await tester.tap(find.text('Bản đồ'));
      await tester.pumpAndSettle();
      expect(find.byType(StationMapScreen), findsOneWidget);
      expect(state.stations.fetches, 2);
      await tester.tap(find.text('Quét QR'));
      await tester.pumpAndSettle();
      expect(find.byType(QrScannerScreen), findsOneWidget);
      await tester.tap(find.text('Tài khoản'));
      await tester.pumpAndSettle();
      expect(find.byType(QrScannerScreen, skipOffstage: false), findsNothing);
      await tester.tap(find.text('Bản đồ'));
      await tester.pumpAndSettle();
      expect(state.stations.fetches, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Navigation rejected by backend profile stays at Login', (
    tester,
  ) async {
    final state = await mount(
      tester,
      const MainNavigationScreen(),
      profileStatus: 401,
    );
    expect(state.auth.isAuthenticated, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen, skipOffstage: false), findsNothing);
    expect(state.stations.fetches, 0);
    expect(tester.takeException(), isNull);
  });
}
