import 'package:dio/dio.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/constants/app_theme.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:ev_charging_station/services/google_identity.dart';
import 'package:ev_charging_station/views/auth/login_screen.dart';
import 'package:ev_charging_station/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_api.dart';
import 'support/fake_google_identity.dart';

void main() {
  for (final canceled in [true, false]) {
    testWidgets(
      'Google button ${canceled ? "cancellation is quiet" : "backend rejection stays at Login"}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await ApiConstants.setBaseUrl(testBaseUrl);
        final google = FakeGoogleIdentity();
        if (canceled) {
          google.credential = const GoogleCredential(
            failure: GoogleSignInFailure(GoogleFailureCode.canceled),
          );
        }
        var calls = 0;
        final dio = Dio()
          ..httpClientAdapter = FakeApiAdapter((request) {
            calls++;
            expect(request.path, contains('/Auth/login-google'));
            return jsonResponse({
              'message': 'Google account rejected',
            }, status: 401);
          });
        final auth = AuthProvider(
          authService: AuthService(apiClient: ApiClient(dio: dio)),
          googleIdentity: google,
        );
        addTearDown(auth.dispose);
        addTearDown(dio.close);
        addTearDown(google.events.close);
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const LoginScreen(),
            ),
          ),
        );
        final button = find.widgetWithText(
          OutlinedButton,
          'Continue with Google',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(google.signIns, 1);
        expect(calls, canceled ? 0 : 1);
        expect(auth.isAuthenticated, isFalse);
        expect(find.byType(MainNavigationScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          find.text('Google account rejected'),
          canceled ? findsNothing : findsOneWidget,
        );
        if (canceled) expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
