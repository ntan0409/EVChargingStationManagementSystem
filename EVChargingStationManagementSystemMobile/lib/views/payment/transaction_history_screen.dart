import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/payment_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch & Hóa Đơn'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await paymentProvider.fetchHistory();
        },
        child: paymentProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : paymentProvider.history.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Chưa có hóa đơn nào',
                    description: 'Tất cả các giao dịch và hóa đơn sạc xe điện của bạn sẽ hiển thị tại đây.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: paymentProvider.history.length,
                    itemBuilder: (context, index) {
                      final item = paymentProvider.history[index];
                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                      item.stationName ?? 'Trạm sạc EV Hub',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(item.amount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatDateTime(item.paymentDate),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  StatusBadge(status: item.paymentStatus),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Phương thức: ${item.paymentMethod}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Điện nạp: ${Formatters.formatEnergy(item.energyDeliveredKWh)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
