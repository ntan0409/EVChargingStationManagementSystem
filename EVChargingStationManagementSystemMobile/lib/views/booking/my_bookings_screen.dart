import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';
import 'create_booking_screen.dart';
import 'checkin_qr_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch đặt sạc?'),
        content: Text('Bạn có chắc chắn muốn hủy lịch đặt tại "${booking.stationName}" vào lúc ${Formatters.formatDateTime(booking.startTime)} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Giữ lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<BookingProvider>(context, listen: false).cancelBooking(booking.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã hủy lịch đặt thành công' : 'Hủy thất bại'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
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
                  const Text('Đang hiệu lực'),
                  if (bookingProvider.activeBookings.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${bookingProvider.activeBookings.length}')),
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
            // Active Bookings Tab
            _buildBookingList(
              context,
              bookingProvider.activeBookings,
              bookingProvider.isLoading,
              isActiveTab: true,
            ),
            // History Bookings Tab
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

    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: isActiveTab ? 'Không có lịch đặt nào đang chờ' : 'Chưa có lịch sử đặt',
        description: isActiveTab
            ? 'Bạn có thể đặt trước vị trí sạc để không phải chờ đợi khi đến trạm.'
            : 'Các lịch đặt đã hoàn tất hoặc đã hủy sẽ được lưu trữ tại đây.',
        buttonText: isActiveTab ? 'Đặt Lịch Ngay' : null,
        onButtonPressed: isActiveTab
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
                );
              }
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  booking.location ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Divider(height: 20),

                // Booking details grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Thời gian bắt đầu', Formatters.formatDateTime(booking.startTime)),
                    _buildInfoColumn('Mã Check-in', booking.checkInCode ?? '8942', isBold: true),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Xe sử dụng', booking.vehicleName ?? 'VinFast VF8'),
                    _buildInfoColumn('Chi phí tạm tính', Formatters.formatCurrency(booking.estimatedCost)),
                  ],
                ),

                if (isActiveTab && (booking.isScheduled || booking.isInProgress)) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Hủy Đặt'),
                          onPressed: () => _showCancelDialog(context, booking),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('Mã Check-in'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckinQrScreen(booking: booking),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
    );
  }
}
