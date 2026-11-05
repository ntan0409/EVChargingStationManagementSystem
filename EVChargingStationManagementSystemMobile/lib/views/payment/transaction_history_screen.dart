import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/payment_provider.dart';
import '../widgets/api_problem.dart';
import '../widgets/status_badge.dart';
import 'payment_checkout_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<PaymentProvider>().fetchHistory();

  void _showDetail(BuildContext context, TransactionModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi Tiết Giao Dịch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Amount & Status
            Center(
              child: Column(
                children: [
                  Text(
                    Formatters.formatCurrency(item.amount),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: item.status),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Thông số sạc
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  _detailRow(
                    'Công suất sạc',
                    '${item.powerRateKW ?? 60} kW',
                    icon: Icons.bolt_rounded,
                  ),
                  const Divider(height: 16),
                  _detailRow(
                    'Điện năng tiêu thụ',
                    item.energyDeliveredKWh != null
                        ? '${item.energyDeliveredKWh!.toStringAsFixed(2)} kWh'
                        : 'Theo phiên sạc',
                    icon: Icons.battery_charging_full_rounded,
                  ),
                  if (item.chargingSessionId != null) ...[
                    const Divider(height: 16),
                    _detailRow(
                      'Mã phiên sạc',
                      item.chargingSessionId!,
                      icon: Icons.qr_code_rounded,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section: Thanh toán & Bút toán
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _detailRow(
                    'Phương thức',
                    item.paymentMethod == 'OFFLINE'
                        ? 'Tiền mặt'
                        : (item.paymentMethod ?? item.transactionType),
                  ),
                  const Divider(height: 16),
                  _detailRow('Mã tham chiếu', item.referenceCode),
                  const Divider(height: 16),
                  _detailRow('Mã giao dịch', item.id),
                  if (item.paymentId != null) ...[
                    const Divider(height: 16),
                    _detailRow('Mã thanh toán', item.paymentId!),
                  ],
                  if (item.paymentReference != null) ...[
                    const Divider(height: 16),
                    _detailRow('Tham chiếu TT', item.paymentReference!),
                  ],
                  if (item.initiatedAt != null && item.initiatedAt!.year > 1) ...[
                    const Divider(height: 16),
                    _detailRow('Khởi tạo', Formatters.formatDateTime(item.initiatedAt!)),
                  ],
                  if (item.completedAt != null) ...[
                    const Divider(height: 16),
                    _detailRow('Hoàn tất', Formatters.formatDateTime(item.completedAt!)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final chargingProvider = context.watch<ChargingSessionProvider>();
    final session = chargingProvider.currentSession;
    final hasUnpaidInvoice = session != null && session.status == 'Completed';

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Giao Dịch')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (hasUnpaidInvoice) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pending_actions_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Hóa Đơn Chờ Thanh Toán',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Chưa thanh toán',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Công suất / Năng lượng',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.powerRateKW} kW • ${session.totalEnergyConsumedKWh.toStringAsFixed(2)} kWh',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Tổng tiền',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(session.cost),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text(
                          'Xem hóa đơn & thanh toán',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaymentCheckoutScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Text(
              'Các bút toán đã được máy chủ ghi nhận. Yêu cầu thanh toán đang chờ chưa phải giao dịch hoàn tất.',
            ),
            const SizedBox(height: 16),
            if (provider.historyLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.historyError != null)
              ApiProblem(message: provider.historyError!, onRetry: _load)
            else if (provider.history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có giao dịch nào',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final item in provider.history)
                Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDetail(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.referenceCode,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  Formatters.formatCurrency(item.amount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Power / Công suất & năng lượng
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 17,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Công suất: ${item.powerRateKW ?? 60} kW${item.energyDeliveredKWh != null ? ' • ${item.energyDeliveredKWh!.toStringAsFixed(1)} kWh' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.paymentMethod == 'OFFLINE'
                                    ? 'Tiền mặt'
                                    : item.transactionType,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              StatusBadge(status: item.status),
                            ],
                          ),

                          // Existing paymentReference kept for test compatibility & transparency
                          if (item.paymentReference != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Tham chiếu thanh toán: ${item.paymentReference}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // Action to view details inside
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Xem chi tiết',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
