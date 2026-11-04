import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/station_service.dart';
import '../charging/live_charging_screen.dart';
import '../charging/start_charging_screen.dart';
import '../payment/payment_checkout_screen.dart';
import '../widgets/api_problem.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'checkin_qr_screen.dart';
import 'create_booking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingProvider>().fetchMyBookings();
      context.read<VehicleProvider>().fetchVehicles();
      context.read<ChargingSessionProvider>().refreshSession();
      _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      context.read<BookingProvider>().fetchMyBookings(silent: true);
      context.read<ChargingSessionProvider>().refreshSession();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _continueBooking(BookingModel booking) async {
    final provider = context.read<BookingProvider>();
    if (provider.isLoading) return;

    if (booking.status != 'InProgress') {
      if (booking.checkInCode == null) return;
      final accepted = await provider.checkIn(booking.checkInCode!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Máy chủ đã xác nhận check-in. Chọn tiếp tục để mở cổng sạc.'
                : provider.errorMessage ?? 'Chưa thể check-in.',
          ),
        ),
      );
      return;
    }

    if (booking.connectorId == null) return;
    final location = await StationService().resolveConnector(
      booking.connectorId!,
    );
    if (!mounted) return;
    if (!location.success || location.data == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(location.message)));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StartChargingScreen(
          connector: location.data!.connector,
          station: location.data!.station,
        ),
      ),
    );
    if (mounted) provider.fetchMyBookings();
  }

  void _showCancelDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch đặt sạc?'),
        content: Text(
          'Bạn có chắc chắn muốn hủy lịch đặt tại "${booking.stationName}" vào lúc ${Formatters.formatDateTime(booking.startTime)} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Giữ lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final success = await context
                  .read<BookingProvider>()
                  .cancelBooking(booking.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Đã hủy lịch đặt thành công' : 'Hủy thất bại',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  String _formatReservedLocation(BookingModel booking) {
    final post = booking.chargingPostName?.trim();
    final conn = booking.connectorName?.trim();

    if (post != null && post.isNotEmpty && conn != null && conn.isNotEmpty) {
      return '$post • $conn';
    }
    if (post != null && post.isNotEmpty) {
      return '$post (Cổng giữ chỗ)';
    }
    if (conn != null && conn.isNotEmpty) {
      return conn;
    }
    if (booking.connectorId != null && booking.connectorId!.isNotEmpty) {
      return 'Cổng sạc #${booking.connectorId!.substring(0, 6).toUpperCase()}';
    }
    return 'Cổng sạc được phân bổ';
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Đặt Sạc Của Tôi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Đang hiệu lực',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bookingProvider.activeBookings.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge(
                      label: Text('${bookingProvider.activeBookings.length}'),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Lịch sử đặt'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await bookingProvider.fetchMyBookings();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingList(
              context,
              bookingProvider.activeBookings,
              bookingProvider.isLoading,
              isActiveTab: true,
            ),
            _buildBookingList(
              context,
              bookingProvider.historyBookings,
              bookingProvider.isLoading,
              isActiveTab: false,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Đặt Lịch Mới'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
          );
        },
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<BookingModel> list,
    bool isLoading, {
    required bool isActiveTab,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final provider = context.read<BookingProvider>();
    if (provider.errorMessage != null && list.isEmpty) {
      return ApiProblem(
        message: provider.errorMessage!,
        onRetry: provider.fetchMyBookings,
      );
    }
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: isActiveTab
            ? 'Không có lịch đặt nào đang chờ'
            : 'Chưa có lịch sử đặt',
        description: isActiveTab
            ? 'Bạn có thể đặt trước vị trí sạc để không phải chờ đợi khi đến trạm.'
            : 'Các lịch đặt đã hoàn tất hoặc đã hủy sẽ được lưu trữ tại đây.',
        buttonText: isActiveTab ? 'Đặt Lịch Ngay' : null,
        onButtonPressed: isActiveTab
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateBookingScreen(),
                  ),
                );
              }
            : null,
      );
    }

    final vehicles = context.watch<VehicleProvider>().vehicles;
    final activeSession = context.watch<ChargingSessionProvider>().currentSession;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        final matchedVehicle = vehicles
            .where((v) => v.id.toLowerCase() == booking.vehicleId?.toLowerCase())
            .firstOrNull;
        final vehicleDisplayName = booking.vehicleName ??
            matchedVehicle?.modelName ??
            (booking.vehicleId != null ? 'Xe điện của bạn' : 'Chưa có thông tin');

        final isCharging = activeSession != null &&
            activeSession.status == 'Charging' &&
            (activeSession.connectorId?.toLowerCase() == booking.connectorId?.toLowerCase() ||
                activeSession.id.isNotEmpty && booking.isInProgress);

        final isSessionCompleted = activeSession != null &&
            activeSession.status == 'Completed' &&
            (activeSession.connectorId?.toLowerCase() == booking.connectorId?.toLowerCase() ||
                activeSession.id.isNotEmpty && booking.isInProgress);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.stationName ?? 'Trạm sạc',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(
                      status: isCharging ? 'Charging' : booking.status,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  booking.location ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                // Hiển thị vị trí giữ chỗ: Trụ sạc và Cổng sạc
                if (booking.connectorId != null ||
                    booking.chargingPostName != null ||
                    booking.connectorName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: (booking.isInProgress || isCharging)
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (booking.isInProgress || isCharging)
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : Colors.blue.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (booking.isInProgress || isCharging)
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.ev_station,
                            color: (booking.isInProgress || isCharging)
                                ? AppColors.primary
                                : Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.isInProgress
                                    ? 'CỔNG SẠC SẴN SÀNG'
                                    : 'VỊ TRÍ GIỮ CHỖ CHO BẠN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatReservedLocation(booking),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: booking.isInProgress
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                booking.isInProgress
                                    ? Icons.lock_open
                                    : Icons.lock_outline,
                                size: 13,
                                color: booking.isInProgress
                                    ? AppColors.primary
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                booking.isInProgress
                                    ? 'Đã mở khóa'
                                    : 'Đã khóa slot',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: booking.isInProgress
                                      ? AppColors.primary
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 20),

                // Booking details grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      'Thời gian bắt đầu',
                      Formatters.formatDateTime(booking.startTime),
                    ),
                    _buildInfoColumn(
                      'Mã Check-in',
                      booking.checkInCode ?? 'Chưa có',
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      'Xe sử dụng',
                      vehicleDisplayName,
                    ),
                    _buildInfoColumn(
                      'Chi phí tạm tính',
                      booking.hasEstimatedCost && booking.estimatedCost > 0
                          ? Formatters.formatCurrency(booking.estimatedCost)
                          : 'Theo thực tế',
                    ),
                  ],
                ),

                if (isActiveTab &&
                    (booking.isScheduled || booking.isInProgress || isCharging || isSessionCompleted)) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Hủy Đặt'),
                          onPressed:
                              context.watch<BookingProvider>().isLoading ||
                                  booking.isInProgress ||
                                  isCharging
                              ? null
                              : () => _showCancelDialog(context, booking),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('Mã Check-in'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CheckinQrScreen(booking: booking),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: isCharging
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.flash_on, size: 20),
                            label: const Text(
                              'Theo dõi phiên sạc (Đang sạc)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LiveChargingScreen(),
                                ),
                              );
                            },
                          )
                        : isSessionCompleted
                            ? FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.payment, size: 20),
                                label: const Text(
                                  'Thanh toán hóa đơn sạc',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PaymentCheckoutScreen(),
                                    ),
                                  );
                                },
                              )
                            : FilledButton(
                                onPressed: context.watch<BookingProvider>().isLoading
                                    ? null
                                    : () => _continueBooking(booking),
                                child: Text(
                                  booking.isInProgress
                                      ? 'Tiếp tục tới cổng sạc'
                                      : 'Check-in với máy chủ',
                                ),
                              ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
