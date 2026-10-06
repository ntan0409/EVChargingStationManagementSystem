import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/voucher_provider.dart';
import '../widgets/custom_button.dart';
import 'payment_status_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  String _selectedMethod = 'VNPay'; // VNPay or Offline

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoucherProvider>(context, listen: false).fetchVouchers();
    });
  }

  void _handlePay() async {
    final chargingProvider = Provider.of<ChargingSessionProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);

    final session = chargingProvider.currentSession;
    final sessionId = session?.id ?? 'sess-demo-01';

    final subtotal = (session?.cost ?? 95000) / 1.10;
    final originalTotal = session?.cost ?? 95000;
    final discount = voucherProvider.selectedVoucher?.calculateDiscount(originalTotal) ?? 0.0;
    final finalTotal = (originalTotal - discount).clamp(0.0, double.infinity);

    if (_selectedMethod == 'VNPay') {
      final vnpayUrl = await paymentProvider.generateVNPayUrl(sessionId);
      if (vnpayUrl != null && vnpayUrl.isNotEmpty) {
        final uri = Uri.tryParse(vnpayUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      await paymentProvider.processOfflinePayment(
        sessionId,
        finalTotal,
        'Trạm Sạc EV Hub - Landmark 81',
        session?.totalEnergyConsumedKWh ?? 24.5,
      );
    }

    if (!mounted) return;

    // Reset session and go to success screen
    chargingProvider.resetSession();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(
          amount: finalTotal,
          paymentMethod: _selectedMethod == 'VNPay' ? 'Cổng thanh toán VNPay' : 'Thanh toán tại quầy (Tiền mặt)',
          sessionId: sessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chargingProvider = context.watch<ChargingSessionProvider>();
    final voucherProvider = context.watch<VoucherProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    final session = chargingProvider.currentSession;
    final energyDelivered = session?.totalEnergyConsumedKWh ?? 24.5;
    final pricePerKWh = chargingProvider.pricePerKWh;
    final subtotal = energyDelivered * pricePerKWh;
    final vat = subtotal * (chargingProvider.vatRate / 100.0);
    final rawTotal = subtotal + vat;

    final selectedVoucher = voucherProvider.selectedVoucher;
    final discount = selectedVoucher?.calculateDiscount(rawTotal) ?? 0.0;
    final finalTotal = (rawTotal - discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán Hóa Đơn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Invoice
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HÓA ĐƠN SẠC XE ĐIỆN',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        '#EV982103',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _buildInvoiceRow('Thời gian sạc:', Formatters.formatDuration(session?.elapsedSeconds ?? 1840)),
                  const SizedBox(height: 8),
                  _buildInvoiceRow('Điện năng tiêu thụ:', Formatters.formatEnergy(energyDelivered)),
                  const SizedBox(height: 8),
                  _buildInvoiceRow('Đơn giá điện:', '${Formatters.formatCurrency(pricePerKWh)}/kWh'),
                  const SizedBox(height: 8),
                  _buildInvoiceRow('Tiền điện (Chưa thuế):', Formatters.formatCurrency(subtotal)),
                  const SizedBox(height: 8),
                  _buildInvoiceRow('Thuế VAT (10%):', Formatters.formatCurrency(vat)),

                  if (selectedVoucher != null) ...[
                    const SizedBox(height: 8),
                    _buildInvoiceRow(
                      'Ưu đãi voucher (${selectedVoucher.code}):',
                      '-${Formatters.formatCurrency(discount)}',
                      textColor: AppColors.primary,
                    ),
                  ],

                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG THANH TOÁN:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        Formatters.formatCurrency(finalTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Voucher Picker
            const Text(
              'Mã Giảm Giá / Voucher',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Chọn voucher áp dụng'),
                  value: selectedVoucher?.id,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Không sử dụng voucher'),
                    ),
                    ...voucherProvider.vouchers.map((v) {
                      return DropdownMenuItem<String>(
                        value: v.id,
                        child: Text('${v.code} - ${v.description}'),
                      );
                    }),
                  ],
                  onChanged: (voucherId) {
                    if (voucherId == null) {
                      voucherProvider.selectVoucher(null);
                    } else {
                      final v = voucherProvider.vouchers.firstWhere((item) => item.id == voucherId);
                      voucherProvider.selectVoucher(v);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods
            const Text(
              'Phương Thức Thanh Toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildPaymentMethodOption(
              context,
              id: 'VNPay',
              title: 'Cổng thanh toán VNPAY-QR',
              subtitle: 'Thanh toán qua App Ngân hàng hoặc Ví điện tử VNPAY',
              icon: Icons.qr_code_2_rounded,
              color: const Color(0xFF005BAA),
            ),
            const SizedBox(height: 12),

            _buildPaymentMethodOption(
              context,
              id: 'Offline',
              title: 'Thanh toán tại quầy với nhân viên',
              subtitle: 'Thanh toán tiền mặt hoặc quẹt thẻ POS tại trạm',
              icon: Icons.storefront_outlined,
              color: AppColors.accent,
            ),
            const SizedBox(height: 32),

            // Submit Payment Button
            CustomButton(
              text: 'Xác Nhận Thanh Toán (${Formatters.formatCurrency(finalTotal)})',
              isLoading: paymentProvider.isLoading,
              onPressed: _handlePay,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
