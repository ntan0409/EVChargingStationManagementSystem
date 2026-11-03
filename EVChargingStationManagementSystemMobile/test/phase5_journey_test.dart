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
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:ev_charging_station/services/driver_journey_service.dart';
import 'package:ev_charging_station/views/profile/profile_completion_screen.dart';
import 'package:ev_charging_station/views/home/home_screen.dart';
import 'package:ev_charging_station/views/widgets/driver_journey_guard.dart';
import 'package:ev_charging_station/views/payment/transaction_history_screen.dart';
import 'support/fake_api.dart';
import 'support/fake_google_identity.dart';
import 'support/phase4_fixtures.dart' as f;

void main() {
  late Dio dio;
  late ApiClient api;
  late FakeApiAdapter adapter;
  late Map<String, dynamic> profile;
  late Map<String, dynamic> vehicle;
  var serverConfirms = true;
  void recompute() {
    final complete =
        serverConfirms &&
        (profile['name'] as String).trim().isNotEmpty &&
        (profile['phoneNumber'] as String).trim().isNotEmpty &&
        (profile['vehicleModelIds'] as List).contains(f.vehicleId) &&
        vehicle['status'] == 'Active' &&
        (vehicle['batteryCapacityKWh'] as num) > 0;
    profile['profileCompleted'] = complete;
    profile['missingRequirements'] = complete
        ? <String>[]
        : ['name', 'phoneNumber', 'supportedVehicle'];
    profile['eligibleVehicleModelIds'] = complete ? [f.vehicleId] : <String>[];
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
    serverConfirms = true;
    vehicle = {...f.vehicleDto(), 'status': 'Active'};
    profile = {
      ...testProfile(),
      'name': '',
      'phoneNumber': '',
      'vehicleModelIds': <String>[],
      'profileCompleted': false,
      'missingRequirements': ['name', 'phoneNumber', 'supportedVehicle'],
      'eligibleVehicleModelIds': <String>[],
    };
    adapter = FakeApiAdapter((r) {
      if (r.path.endsWith('/Auth/login'))
        return jsonResponse({
          'token': testToken(),
          'expiration': DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String(),
        });
      if (r.path.endsWith('/EVDriver/update')) {
        final data = r.data as Map;
        for (final key in ['name', 'phoneNumber', 'vehicleModelIds']) {
          if (data.containsKey(key)) profile[key] = data[key];
        }
        recompute();
        return jsonResponse({'data': profile});
      }
      if (r.path.endsWith('/EVDriver/profile'))
        return jsonResponse({'data': profile});
      if (r.path.endsWith('/VehicleModel'))
        return jsonResponse({
          'data': [vehicle],
        });
      return jsonResponse({'message': 'No current session'}, status: 404);
    });
    dio = Dio()..httpClientAdapter = adapter;
    api = ApiClient(dio: dio);
  });
  tearDown(() => dio.close());
  Future<AuthProvider> authFor(WidgetTester tester, {bool login = true}) async {
    late AuthProvider auth;
    await tester.runAsync(() async {
      auth = AuthProvider(
        authService: AuthService(apiClient: api),
        googleIdentity: FakeGoogleIdentity(),
      );
      if (login) expect(await auth.login('fixture', 'fixture'), isTrue);
    });
    return auth;
  }

  Future<void> openApp(WidgetTester tester, AuthProvider auth) async {
    await tester.pumpWidget(EVChargingApp(authProvider: auth));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets(
    'New authenticated user is redirected to profile completion, not Home',
    (tester) async {
      final auth = await authFor(tester);
      await openApp(tester, auth);
      expect(auth.isAuthenticated, isTrue);
      expect(find.byType(ProfileCompletionScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(
        adapter.requests.where(
          (r) => r.path.endsWith('/Booking') && r.method == 'POST',
        ),
        isEmpty,
      );
      await finish(tester);
    },
  );
  testWidgets(
    'Select Admin catalog, save FK and fields, then server confirmation unlocks Home',
    (tester) async {
      final auth = await authFor(tester);
      await openApp(tester, auth);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Fixture completed name');
      await tester.enterText(fields.at(1), '0900000001');
      await tester.tap(find.text(vehicle['modelName']));
      await tester.pump();
      expect(
        find.text('Xác nhận xe và lưu hồ sơ').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.text('Xác nhận xe và lưu hồ sơ'));
      await tester.pumpAndSettle();
      expect((profile['vehicleModelIds'] as List), contains(f.vehicleId));
      expect(auth.currentUser!.profileCompleted, isTrue);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        adapter.requests.where(
          (r) => r.method == 'POST' && r.path.endsWith('/VehicleModel'),
        ),
        isEmpty,
      );
      expect(
        adapter.requests
            .where((r) => r.path.endsWith('/EVDriver/update'))
            .length,
        2,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );
  testWidgets(
    'Opening and saving form cannot complete a profile when backend refuses confirmation',
    (tester) async {
      serverConfirms = false;
      final auth = await authFor(tester);
      await openApp(tester, auth);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Fixture name');
      await tester.enterText(fields.at(1), '0900000001');
      await tester.tap(find.text(vehicle['modelName']));
      await tester.pump();
      expect(
        find.text('Xác nhận xe và lưu hồ sơ').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.text('Xác nhận xe và lưu hồ sơ'));
      await tester.pumpAndSettle();
      expect(auth.currentUser!.profileCompleted, isFalse);
      expect(find.byType(ProfileCompletionScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      await finish(tester);
    },
  );
  for (final invalid in ['disabled', 'zeroCapacity']) {
    testWidgets('Cannot select $invalid catalog vehicle to bypass completion', (
      tester,
    ) async {
      if (invalid == 'disabled')
        vehicle['status'] = 'Inactive';
      else
        vehicle['batteryCapacityKWh'] = 0;
      final auth = await authFor(tester);
      await openApp(tester, auth);
      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, vehicle['modelName']),
      );
      expect(tile.onTap, isNull);
      expect(find.textContaining('Cần Admin xác nhận'), findsOneWidget);
      expect(auth.currentUser!.profileCompleted, isFalse);
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      await finish(tester);
    });
  }
  for (final completed in [false, true]) {
    testWidgets(
      'Restart ignores local completion bool and restores backend completed=$completed',
      (tester) async {
        if (completed) profile = testProfile();
        SharedPreferences.setMockInitialValues({
          'auth_token': testToken(),
          'auth_base_url': testBaseUrl,
          'profileCompleted': true,
        });
        final auth = await authFor(tester, login: false);
        await openApp(tester, auth);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.currentUser!.profileCompleted, completed);
        expect(
          find.byType(ProfileCompletionScreen),
          completed ? findsNothing : findsOneWidget,
        );
        expect(
          find.byType(HomeScreen),
          completed ? findsOneWidget : findsNothing,
        );
        await finish(tester);
      },
    );
  }
  testWidgets(
    'Incomplete profile may still open authenticated transaction history',
    (tester) async {
      final auth = await authFor(tester);
      await openApp(tester, auth);
      await tester.ensureVisible(find.text('Xem lịch sử giao dịch'));
      await tester.tap(find.text('Xem lịch sử giao dịch'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );
  for (final prerequisite in [
    'missingProfile',
    'missingVehicle',
    'noBooking',
    'notCheckedIn',
    'wrongConnector',
  ]) {
    testWidgets('Direct route cannot bypass $prerequisite', (tester) async {
      final auth = await authFor(tester);
      final complete = ![
        'missingProfile',
        'missingVehicle',
      ].contains(prerequisite);
      final journeyApi = Dio()
        ..httpClientAdapter = FakeApiAdapter(
          (_) => jsonResponse({
            'data': {
              'accountId': testAccountId,
              'profileCompleted': complete,
              'canBook': complete,
              'canChangeVehicle': true,
              'missingRequirements': complete
                  ? <String>[]
                  : ['supportedVehicle'],
              'eligibleVehicleModelIds': complete ? [f.vehicleId] : <String>[],
              'activeBooking':
                  ['notCheckedIn', 'wrongConnector'].contains(prerequisite)
                  ? {
                      'id': f.sessionId,
                      'stationId': f.stationId,
                      'vehicleModelId': f.vehicleId,
                      'connectorId': prerequisite == 'wrongConnector'
                          ? f.otherId
                          : f.connectorId,
                      'status': prerequisite == 'notCheckedIn'
                          ? 'Scheduled'
                          : 'InProgress',
                      'startTime': '2026-11-03T10:00:00',
                      'endTime': '2026-11-03T11:00:00',
                    }
                  : null,
              'currentSessionId': null,
              'currentSessionStatus': null,
            },
          }),
        );
      addTearDown(journeyApi.close);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: DriverJourneyGuard(
              step: complete
                  ? DriverJourneyStep.charging
                  : DriverJourneyStep.booking,
              connectorId: f.connectorId,
              service: DriverJourneyService(
                apiClient: ApiClient(dio: journeyApi),
              ),
              builder: (_, state) => const Text('PROTECTED CONTENT'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PROTECTED CONTENT'), findsNothing);
      if (!complete)
        expect(find.byType(ProfileCompletionScreen), findsOneWidget);
      else
        expect(
          find.textContaining('Cần lịch đặt của bạn đã check-in'),
          findsOneWidget,
        );
      expect(tester.takeException(), isNull);
      await finish(tester);
      auth.dispose();
    });
  }
  testWidgets(
    'Server profile change invalidates cached eligibility without logging out',
    (tester) async {
      profile = testProfile();
      final auth = await authFor(tester);
      await openApp(tester, auth);
      expect(find.byType(HomeScreen), findsOneWidget);
      profile = {
        ...profile,
        'profileCompleted': false,
        'missingRequirements': ['supportedVehicle'],
        'eligibleVehicleModelIds': <String>[],
      };
      await tester.runAsync(auth.refreshProfile);
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isTrue);
      expect(find.byType(ProfileCompletionScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      await finish(tester);
    },
  );
}
