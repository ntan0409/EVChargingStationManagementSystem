import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/charging_session_provider.dart';
import '../payment/payment_checkout_screen.dart';
import '../widgets/api_problem.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';

class LiveChargingScreen extends StatelessWidget {
  const LiveChargingScreen({super.key});
  static const _demo = bool.fromEnvironment('EVCSMS_CHARGING_DEMO');
  Future<void> _stop(BuildContext context) async {
    final provider = context.read<ChargingSessionProvider>();
    final energy = _demo
        ? null
        : await showDialog<double>(
            context: context,
            builder: (_) => _MeterReadingDialog(
              capacity: provider.currentSession!.batteryCapacityKWh,
            ),
          );
    if ((!_demo && energy == null) || !context.mounted) return;
    final accepted = await provider.stopCharging(energyDeliveredKWh: energy);
    if (!context.mounted) return;
    if (accepted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaymentCheckoutScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Máy chủ chưa xác nhận dừng sạc.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChargingSessionProvider>();
    final session = provider.currentSession;
    return Scaffold(
      appBar: AppBar(title: const Text('Giám Sát Phiên Sạc')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 64),
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.errorMessage != null)
            ApiProblem(
              message: provider.errorMessage!,
              onRetry: provider.refreshSession,
            ),
          if (session == null) ...[
            const Text(
              'Chưa có phiên đang mở. Kiểm tra máy chủ để khôi phục phiên.',
            ),
            OutlinedButton(
              onPressed: provider.isLoading ? null : provider.restoreSession,
              child: const Text('Tải phiên hiện tại'),
            ),
          ] else ...[
            const SizedBox(height: 12),
            StatusBadge(status: session.status),
            const SizedBox(height: 16),
            const Text(
              _demo
                  ? 'Chế độ demo. Điện năng và chi phí tạm tính tự cập nhật mỗi 5 giây.'
                  : 'Máy chủ chưa cung cấp telemetry phần cứng thời gian thực. Các số liệu dưới đây là snapshot từ backend.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      _demo
                          ? 'Điện năng mô phỏng'
                          : 'Điện năng máy chủ ghi nhận',
                    ),
                    trailing: Text(
                      session.hasEnergy
                          ? Formatters.formatEnergy(
                              session.totalEnergyConsumedKWh,
                            )
                          : 'Chưa có',
                    ),
                  ),
                  ListTile(
                    title: const Text('Thời gian từ mốc máy chủ'),
                    trailing: Text(
                      Formatters.formatDuration(session.elapsedSeconds),
                    ),
                  ),
                  ListTile(
                    title: const Text('Công suất định mức trụ'),
                    trailing: Text(
                      session.powerRateKW > 0
                          ? '${session.powerRateKW} kW'
                          : 'Chưa có',
                    ),
                  ),
                  ListTile(
                    title: const Text('Mức pin đo được'),
                    trailing: Text(
                      session.hasMeasuredBatteryPercent
                          ? '${session.currentBatteryPercent}%'
                          : 'Chưa có',
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      _demo
                          ? 'Chi phí tạm tính (chưa VAT)'
                          : 'Chi phí phiên trên máy chủ',
                    ),
                    trailing: Text(
                      session.hasCost
                          ? Formatters.formatCurrency(session.cost)
                          : 'Chưa có',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (session.status == 'Charging')
              CustomButton(
                text: _demo ? 'Dừng sạc (demo)' : 'Dừng sạc với số đo thực',
                isLoading: provider.isLoading,
                onPressed: provider.isLoading ? null : () => _stop(context),
              ),
            if (session.status == 'Completed')
              CustomButton(
                text: 'Xem hóa đơn & thanh toán',
                onPressed: provider.isLoading || provider.errorMessage != null
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const PaymentCheckoutScreen(),
                        ),
                      ),
              ),
            if (session.status == 'Paid')
              const Text('Máy chủ đã ghi nhận phiên được thanh toán.'),
          ],
        ],
      ),
    );
  }
}

class _MeterReadingDialog extends StatefulWidget {
  final int capacity;
  const _MeterReadingDialog({required this.capacity});
  @override
  State<_MeterReadingDialog> createState() => _MeterReadingDialogState();
}

class _MeterReadingDialogState extends State<_MeterReadingDialog> {
  final _form = GlobalKey<FormState>();
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get reading =>
      double.tryParse(_controller.text.trim().replaceAll(',', '.'));
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Xác nhận số đo trước khi dừng'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nhập tổng điện năng thực của phiên từ đồng hồ cổng sạc (kWh). Không nhập số ước tính.',
          ),
          TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Điện năng đã nạp (kWh)',
            ),
            validator: (_) =>
                reading == null ||
                    !reading!.isFinite ||
                    reading! < 0 ||
                    (widget.capacity > 0 && reading! > widget.capacity)
                ? 'Nhập số đo hợp lệ trong dung lượng pin.'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
        onPressed: () {
          if (_form.currentState!.validate()) Navigator.pop(context, reading);
        },
        child: const Text('Gửi yêu cầu dừng'),
      ),
    ],
  );
}
