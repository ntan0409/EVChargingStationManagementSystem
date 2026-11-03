import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/payment_provider.dart';
import '../widgets/api_problem.dart';
import '../widgets/status_badge.dart';

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
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Giao Dịch')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                Formatters.formatCurrency(item.amount),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.paymentMethod == 'OFFLINE'
                              ? 'Tiền mặt'
                              : item.transactionType,
                        ),
                        StatusBadge(status: item.status),
                        if (item.initiatedAt != null &&
                            item.initiatedAt!.year > 1)
                          Text(
                            'Khởi tạo: ${Formatters.formatDateTime(item.initiatedAt!)}',
                          ),
                        if (item.completedAt != null)
                          Text(
                            'Hoàn tất: ${Formatters.formatDateTime(item.completedAt!)}',
                          ),
                        if (item.paymentReference != null)
                          SelectableText(
                            'Tham chiếu thanh toán: ${item.paymentReference}',
                          ),

                        if (item.paymentId != null)
                          SelectableText('Mã thanh toán: ${item.paymentId}'),
                        SelectableText('Mã giao dịch: ${item.id}'),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
