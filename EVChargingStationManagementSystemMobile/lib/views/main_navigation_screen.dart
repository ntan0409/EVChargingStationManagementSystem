import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/charging_session_provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
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

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  late final Set<int> _visited;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _visited = {_currentIndex};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        context.read<ChargingSessionProvider>().restoreSession();
      }
    });
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    await auth.refreshProfile();
    if (mounted && auth.isAuthenticated)
      context.read<ChargingSessionProvider>().restoreSession();
  }

  Widget _tab(int index, bool isCharging) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    // Camera/live view is released when hidden. Charging state belongs to its
    // provider; other tabs keep their widget/scroll state after first visit.
    if (index == 2 && _currentIndex != 2) return const SizedBox.shrink();
    final screen = switch (index) {
      0 => HomeScreen(onShowMap: () => _selectTab(1)),
      1 => const StationMapScreen(),
      2 => isCharging ? const LiveChargingScreen() : const QrScannerScreen(),
      3 => const MyBookingsScreen(),
      _ => const ProfileScreen(),
    };
    return TickerMode(
      enabled: index == _currentIndex,
      child: KeyedSubtree(key: ValueKey('main-tab-$index'), child: screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return auth.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const LoginScreen();
    }
    final chargingProvider = context.watch<ChargingSessionProvider>();
    final isCharging = chargingProvider.isCharging;
    final hasSession =
        chargingProvider.currentSession != null &&
        chargingProvider.currentSession!.status != 'Paid';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, (index) => _tab(index, hasSession)),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _selectTab,
              elevation: 0,
              height: 64,
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
                  label: isCharging
                      ? 'Đang sạc'
                      : hasSession
                      ? 'Hóa đơn'
                      : 'Quét QR',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Lịch đặt',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Tài khoản',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
