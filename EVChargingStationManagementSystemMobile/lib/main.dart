import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/api_constants.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/charging_session_provider.dart';
import 'providers/feedback_report_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/station_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/voucher_provider.dart';
import 'views/splash/splash_screen.dart';
import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dynamic API Configuration
  await ApiConstants.init();

  if (!kIsWeb) {
    // Set Preferred Orientations & System UI
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(const EVChargingApp());
}

class EVChargingApp extends StatefulWidget {
  final AuthProvider? authProvider;
  const EVChargingApp({super.key, this.authProvider});

  @override
  State<EVChargingApp> createState() => _EVChargingAppState();
}

class _EVChargingAppState extends State<EVChargingApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _hasPrivateSession = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => widget.authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, auth, provider) => provider!
            ..bindAccount(
              auth.isAuthenticated ? auth.currentUser?.accountId : null,
            ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChargingSessionProvider>(
          create: (_) => ChargingSessionProvider(),
          update: (_, auth, provider) => provider!
            ..bindAccount(
              auth.isAuthenticated ? auth.currentUser?.accountId : null,
            ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, VehicleProvider>(
          create: (_) => VehicleProvider(),
          update: (_, auth, provider) => provider!
            ..bindAccount(
              auth.isAuthenticated ? auth.currentUser?.accountId : null,
            ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, VoucherProvider>(
          create: (_) => VoucherProvider(),
          update: (_, auth, provider) => provider!
            ..bindAccount(
              auth.isAuthenticated ? auth.currentUser?.accountId : null,
            ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (_) => PaymentProvider(),
          update: (_, auth, provider) => provider!
            ..bindAccount(
              auth.isAuthenticated ? auth.currentUser?.accountId : null,
            ),
        ),
        ChangeNotifierProvider(create: (_) => FeedbackReportProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, provider) => provider!
            ..bindAccount(
              auth.isAuthenticated ? auth.currentUser?.accountId : null,
            ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            builder: (context, child) {
              final auth = context.watch<AuthProvider>();
              if (auth.isAuthenticated) _hasPrivateSession = true;
              if (_hasPrivateSession &&
                  !auth.isAuthenticated &&
                  !auth.isLoading) {
                _hasPrivateSession = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !auth.isAuthenticated && !auth.isLoading) {
                    _navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                });
              }
              return child ?? const SizedBox.shrink();
            },
            title: 'EV Charging Station',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
