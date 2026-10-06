import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/charging_session_provider.dart';
import '../providers/notification_provider.dart';
import 'home/home_screen.dart';
import 'map/station_map_screen.dart';
import 'charging/live_charging_screen.dart';
import 'charging/qr_scanner_screen.dart';
import 'booking/my_bookings_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Fetch initial notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chargingProvider = context.watch<ChargingSessionProvider>();
    final isCharging = chargingProvider.isCharging;

    final List<Widget> screens = [
      const HomeScreen(),
      const StationMapScreen(),
      isCharging ? const LiveChargingScreen() : const QrScannerScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          elevation: 0,
          backgroundColor: Theme.of(context).cardColor,
          indicatorColor: AppColors.primary.withOpacity(0.18),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Trang chủ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: AppColors.primary),
              label: 'Bản đồ',
            ),
            NavigationDestination(
              icon: isCharging
                  ? const Badge(
                      label: Text('1'),
                      child: Icon(Icons.bolt, color: AppColors.accent),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
              selectedIcon: Icon(
                isCharging ? Icons.bolt_rounded : Icons.qr_code_scanner_rounded,
                color: isCharging ? AppColors.accent : AppColors.primary,
              ),
              label: isCharging ? 'Đang sạc' : 'Quét QR',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              label: 'Lịch đặt',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
