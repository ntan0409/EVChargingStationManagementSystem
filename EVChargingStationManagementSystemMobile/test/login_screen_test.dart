import 'package:dio/dio.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/constants/app_theme.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/providers/auth_provider.dart';
import 'package:ev_charging_station/services/auth_service.dart';
import 'package:ev_charging_station/views/auth/login_screen.dart';
import 'package:ev_charging_station/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_api.dart';

class _RememberProvider extends AuthProvider {
  bool? remembered;
  @override
  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    remembered = rememberMe;
    return false;
  }
}

void main() {
  testWidgets(
    'Login HTTP401 stays on Login with server error and empty initial credentials',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ApiConstants.setBaseUrl(testBaseUrl);
      final dio = Dio()
        ..httpClientAdapter = FakeApiAdapter(
          (_) => jsonResponse({'message': 'Credentials rejected'}, status: 401),
        );
      final provider = AuthProvider(
        authService: AuthService(apiClient: ApiClient(dio: dio)),
      );
      addTearDown(provider.dispose);
      addTearDown(dio.close);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        isEmpty,
      );
      expect(find.text('Đăng nhập nhanh (Tài khoản Demo)'), findsNothing);
      await tester.enterText(fields.at(0), 'driver@example.test');
      await tester.enterText(fields.at(1), 'wrong-password');
      final button = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.text('Credentials rejected'), findsOneWidget);
      expect(provider.isAuthenticated, isFalse);
    },
  );

  testWidgets('Remember Me checkbox is passed into provider login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final provider = _RememberProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'driver@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final button = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(provider.remembered, isFalse);
  });
}
