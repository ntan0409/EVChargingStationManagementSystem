import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/voucher_provider.dart';
import '../widgets/api_problem.dart';

class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});
  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => context.read<VoucherProvider>().fetchVouchers();
  Future<void> _redeem(String id) async {
    final provider = context.read<VoucherProvider>();
    final accepted = await provider.redeemVoucher(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Máy chủ đã xác nhận đổi voucher. Áp dụng voucher khi xem hóa đơn.'
              : provider.errorMessage ?? 'Chưa xác nhận đổi voucher.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoucherProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher & Điểm Thưởng')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              provider.points == null
                  ? 'Điểm thưởng: chưa tải được'
                  : 'Điểm thưởng trên máy chủ: ${provider.points}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (provider.isLoading) const LinearProgressIndicator(),
            if (provider.errorMessage != null)
              ApiProblem(message: provider.errorMessage!, onRetry: _load),
            const SizedBox(height: 12),
            Text(
              'Voucher có thể đổi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!provider.isLoading &&
                provider.errorMessage == null &&
                provider.vouchers.isEmpty)
              const Text('Chưa có voucher nào còn hiệu lực.'),
            for (final voucher in provider.vouchers)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        voucher.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(voucher.description),
                      Text(
                        voucher.voucherType == 'Discount'
                            ? 'Giảm ${voucher.value}%'
                            : 'Giảm ${Formatters.formatCurrency(voucher.value)}',
                      ),
                      Text(
                        '${voucher.pointsRequired} điểm • Hết hạn ${Formatters.formatDate(voucher.validTo)}',
                      ),
                      OutlinedButton(
                        onPressed:
                            provider.isLoading ||
                                !voucher.isValid ||
                                provider.points == null ||
                                provider.points! < voucher.pointsRequired ||
                                provider.ownedVouchers.any(
                                  (v) =>
                                      v.voucherId == voucher.id &&
                                      v.status != 'Expired' &&
                                      !DateTime.now().isAfter(v.expiryDate),
                                )
                            ? null
                            : () => _redeem(voucher.id),
                        child: const Text('Đổi voucher trên máy chủ'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Voucher của bạn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!provider.isLoading &&
                provider.errorMessage == null &&
                provider.ownedVouchers.isEmpty)
              const Text('Bạn chưa đổi voucher nào.'),
            for (final voucher in provider.ownedVouchers)
              Card(
                child: ListTile(
                  title: Text(voucher.voucherName),
                  subtitle: Text(
                    '${voucher.status} • Hết hạn ${Formatters.formatDate(voucher.expiryDate)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
