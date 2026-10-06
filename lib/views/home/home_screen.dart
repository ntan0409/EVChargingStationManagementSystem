import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../charging/live_charging_screen.dart';
import '../charging/qr_scanner_screen.dart';
import '../booking/create_booking_screen.dart';
import '../garage/my_vehicles_screen.dart';
import '../vouchers/voucher_list_screen.dart';
import '../feedback_report/create_report_screen.dart';
import '../notifications/notification_screen.dart';
import '../station/station_detail_screen.dart';
import '../widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StationProvider>(context, listen: false).fetchStations();
      Provider.of<VehicleProvider>(context, listen: false).fetchVehicles();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final stationProvider = context.watch<StationProvider>();
    final chargingProvider = context.watch<ChargingSessionProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();

    final user = authProvider.currentUser;
    final selectedCar = vehicleProvider.selectedVehicle;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await stationProvider.fetchStations();
            await vehicleProvider.fetchVehicles();
            await notifProvider.fetchNotifications();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              user?.name ?? 'Tài xế EV',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: notifProvider.unreadCount > 0,
                        label: Text('${notifProvider.unreadCount}'),
                        child: const Icon(Icons.notifications_outlined, size: 26),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Active Charging Card Banner (if charging)
                if (chargingProvider.isCharging) ...[
                  _buildLiveChargingBanner(context, chargingProvider),
                  const SizedBox(height: 20),
                ],

                // Connected EV Car Status Card
                _buildVehicleStatusCard(context, selectedCar),
                const SizedBox(height: 24),

                // Quick Action Grid
                const Text(
                  'Dịch Vụ Nhanh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 26),

                // Nearest Charging Stations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trạm Sạc Gần Bạn',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to map tab
                      },
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildNearestStationsList(context, stationProvider),
                const SizedBox(height: 24),

                // Promo Banner
                _buildPromoBanner(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveChargingBanner(BuildContext context, ChargingSessionProvider provider) {
    final session = provider.currentSession;
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ĐANG SẠC PIN',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Phiên sạc đang diễn ra',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const StatusBadge(status: 'Charging'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Mức Pin', '${session.currentBatteryPercent.toStringAsFixed(0)}%'),
              _buildMetricItem('Công suất', '${provider.currentPowerKW.toStringAsFixed(0)} kW'),
              _buildMetricItem('Đã nạp', Formatters.formatEnergy(session.totalEnergyConsumedKWh)),
              _buildMetricItem('Tạm tính', Formatters.formatCurrency(session.cost)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.speed, size: 18),
              label: const Text('Mở Bảng Điều Khiển Sạc (Live Telemetry)'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveChargingScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleStatusCard(BuildContext context, dynamic selectedCar) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car_filled, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    selectedCar?.modelName ?? 'VinFast VF8 Plus',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyVehiclesScreen()),
                  );
                },
                child: const Text(
                  'Đổi xe',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCarStatItem(Icons.battery_charging_full, 'Dung lượng pin', '${selectedCar?.batteryCapacityKWh ?? 87} kWh'),
              _buildCarStatItem(Icons.flash_on, 'Chuẩn sạc', 'CCS2 / Fast DC'),
              _buildCarStatItem(Icons.pin, 'Biển số', selectedCar?.licensePlate ?? '51K-987.65'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarStatItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Quét Sạc Ngay',
        'icon': Icons.qr_code_scanner_rounded,
        'color': AppColors.primary,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          );
        },
      },
      {
        'title': 'Đặt Lịch Sạc',
        'icon': Icons.calendar_today_rounded,
        'color': AppColors.secondary,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
          );
        },
      },
      {
        'title': 'Mã Giảm Giá',
        'icon': Icons.card_giftcard_rounded,
        'color': AppColors.accent,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VoucherListScreen()),
          );
        },
      },
      {
        'title': 'Báo Cáo Sự Cố',
        'icon': Icons.report_problem_outlined,
        'color': AppColors.statusFaulted,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateReportScreen()),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: item['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNearestStationsList(BuildContext context, StationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stations = provider.stations;
    if (stations.isEmpty) {
      return const Center(child: Text('Không tìm thấy trạm sạc nào'));
    }

    return Column(
      children: stations.take(3).map((station) {
        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StationDetailScreen(stationId: station.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.ev_station, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.stationName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              Formatters.formatCurrency(station.pricePerKWh) + '/kWh',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${station.distanceKm} km',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: station.totalAvailableConnectors > 0 ? 'Available' : 'Faulted'),
                      const SizedBox(height: 6),
                      Text(
                        '${station.totalAvailableConnectors}/${station.totalAllConnectors} cổng trống',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ƯU ĐÃI THÀNH VIÊN MỚI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Giảm ngay 20% cho phiên sạc đầu tiên. Tích lũy điểm thưởng đổi voucher!',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoucherListScreen()),
              );
            },
            child: const Text('Nhận ngay'),
          ),
        ],
      ),
    );
  }
}
