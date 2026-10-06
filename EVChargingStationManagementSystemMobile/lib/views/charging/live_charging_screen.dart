import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/charging_session_provider.dart';
import '../payment/payment_checkout_screen.dart';

class LiveChargingScreen extends StatelessWidget {
  const LiveChargingScreen({super.key});

  void _showStopConfirmation(BuildContext context, ChargingSessionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dừng phiên sạc?'),
        content: const Text('Bạn có chắc chắn muốn ngắt kết nối và kết thúc phiên sạc hiện tại không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tiếp tục sạc'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.stopCharging();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PaymentCheckoutScreen()),
                );
              }
            },
            child: const Text('Dừng sạc ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChargingSessionProvider>();
    final session = provider.currentSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bảng Điều Khiển Sạc')),
        body: const Center(
          child: Text('Không có phiên sạc nào đang hoạt động.'),
        ),
      );
    }

    final batteryPercent = (session.currentBatteryPercent / 100.0).clamp(0.0, 1.0);
    final targetPercent = session.expectedEnergiesKWh;

    // If completed automatically, offer button to proceed to payment
    if (session.status == 'Completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Automatically or user-navigated
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'GIÁM SÁT PHIÊN SẠC',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              // Main Circular Battery Gauge
              CircularPercentIndicator(
                radius: 115.0,
                lineWidth: 18.0,
                animation: false,
                percent: batteryPercent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: AppColors.primary, size: 36),
                    Text(
                      '${session.currentBatteryPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 42.0,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Mục tiêu: $targetPercent%',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: AppColors.primary,
                backgroundColor: Colors.white.withOpacity(0.12),
              ),
              const SizedBox(height: 16),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.status == 'Completed' ? 'ĐÃ HOÀN TẤT SẠC' : 'ĐANG NẠP NĂNG LƯỢNG',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Live Telemetry Grid (4 items)
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.speed,
                      title: 'Công suất sạc',
                      value: '${provider.currentPowerKW.toStringAsFixed(1)} kW',
                      subtitle: 'DC Super Fast',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.energy_savings_leaf_outlined,
                      title: 'Điện năng nạp',
                      value: Formatters.formatEnergy(session.totalEnergyConsumedKWh),
                      subtitle: 'Dung lượng pin 80 kWh',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.timer_outlined,
                      title: 'Thời gian đã sạc',
                      value: Formatters.formatDuration(session.elapsedSeconds),
                      subtitle: 'Đang đếm thời gian',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.payments_outlined,
                      title: 'Chi phí tích lũy',
                      value: Formatters.formatCurrency(session.cost),
                      subtitle: 'Đã gồm 10% VAT',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Voltage & Current Technical Specs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubMetric('Điện áp (Voltage)', '${provider.currentVoltageV.toStringAsFixed(1)} V'),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSubMetric('Dòng điện (Current)', '${provider.currentAmperageA.toStringAsFixed(1)} A'),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSubMetric('Nhiệt độ đầu sạc', '32.5 °C'),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Bottom Action Button (Stop or Pay)
              if (session.status == 'Completed') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 22),
                  label: const Text(
                    'Xem Hóa Đơn & Thanh Toán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PaymentCheckoutScreen()),
                    );
                  },
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 22),
                  label: const Text(
                    'Dừng Phiên Sạc (Stop Session)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showStopConfirmation(context, provider),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
