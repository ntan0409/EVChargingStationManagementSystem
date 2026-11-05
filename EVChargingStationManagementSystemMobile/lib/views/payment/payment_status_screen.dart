import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/payment_provider.dart';
import '../main_navigation_screen.dart';
import '../widgets/api_problem.dart';
import 'sepay_checkout_screen.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String sessionId;
  const PaymentStatusScreen({super.key, required this.sessionId});
  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _reading = false;
  bool _active = true;
  bool _opening = false;
  bool _autoOpened = false;
  String? _openError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _read();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _read();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _read() async {
    if (!mounted || _reading || _opening) return;
    _reading = true;
    final payments = context.read<PaymentProvider>();
    final accepted = await payments.fetchQuote(widget.sessionId);
    if (!mounted) return;
    _reading = false;
    final quote = payments.quote;
    if (accepted &&
        quote?.hasPendingPayment == true &&
        quote?.payment?.paymentMethod == 'SePaySandbox' &&
        !_autoOpened) {
      _autoOpened = true;
      await _openCheckout();
      return;
    }
    if (!accepted || quote?.hasPendingPayment != true) {
      _timer?.cancel();
      _timer = null;
    }
    if (_active &&
        accepted &&
        quote?.hasPendingPayment == true &&
        _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        _read();
      });
    }
    if (accepted && quote?.isPaid == true) {
      final charging = context.read<ChargingSessionProvider>();
      if (charging.currentSession?.id == widget.sessionId) {
        charging.resetSession();
      }
    }
  }

  Future<void> _openCheckout() async {
    if (_opening) return;
    _timer?.cancel();
    _timer = null;
    setState(() {
      _opening = true;
      _openError = null;
    });
    try {
      final url = await context.read<PaymentProvider>().sandboxLink(
        widget.sessionId,
      );
      if (!mounted) return;
      if (url != null &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SePayCheckoutScreen(
              checkoutUrl: Uri.parse(url),
              sessionId: widget.sessionId,
            ),
          ),
        );
      } else if (url == null ||
          !await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        if (mounted) {
          setState(
            () => _openError =
                'Không mở được trang thanh toán. Bạn có thể mở lại bên dưới.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _openError = 'Không mở được SePay Sandbox. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        // Also reconcile when the embedded page is closed with Android Back.
        unawaited(_read());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final quote = provider.quote?.sessionId == widget.sessionId
        ? provider.quote
        : null;
    final paid = quote?.isPaid == true;
    final sandbox = quote?.payment?.paymentMethod == 'SePaySandbox';
    final status = quote?.payment?.paymentStatus;
    final title = provider.checking
        ? 'Đang kiểm tra với máy chủ'
        : paid
        ? 'Thanh toán đã được xác nhận'
        : status == 'Failed'
        ? 'Thanh toán thất bại'
        : status == 'Cancelled'
        ? 'Giao dịch đã hủy'
        : status == 'Initiated'
        ? 'Đang chờ xác nhận thanh toán'
        : 'Chưa xác nhận đã thanh toán';
    return Scaffold(
      appBar: AppBar(title: const Text('Trạng Thái Thanh Toán')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            paid ? Icons.verified : Icons.receipt_long_outlined,
            size: 72,
            color: paid ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (provider.checking) const LinearProgressIndicator(),
          if (provider.errorMessage != null)
            ApiProblem(message: provider.errorMessage!, onRetry: _read),
          if (quote != null) ...[
            ListTile(
              title: const Text('Số tiền máy chủ ghi nhận'),
              subtitle: Text(
                Formatters.formatCurrency(
                  quote.payment?.amount ?? quote.amount,
                ),
              ),
            ),
            ListTile(
              title: const Text('Phương thức'),
              subtitle: Text(
                quote.payment?.paymentMethod == 'VNPaySandbox'
                    ? 'VNPAY Sandbox'
                    : quote.payment?.paymentMethod ?? 'Chưa có yêu cầu',
              ),
            ),
            ListTile(
              title: Text(
                quote.payment?.paymentMethod == 'SePayTest'
                    ? 'Nội dung giao dịch mô phỏng SePay'
                    : 'Mã tham chiếu',
              ),
              subtitle: SelectableText(
                quote.payment?.transactionCode ?? 'Chưa được cấp',
              ),
            ),
            if (quote.payment?.paymentDate != null)
              ListTile(
                title: const Text('Tạo yêu cầu lúc'),
                subtitle: Text(
                  Formatters.formatDateTime(quote.payment!.paymentDate!),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            paid
                ? 'Máy chủ đã xác nhận hoàn tất hóa đơn.'
                : sandbox
                ? 'Nhập thẻ thử trên màn hình SePay Sandbox. Hóa đơn tự mở lại khi máy chủ xác nhận; chỉ dùng tiền giả.'
                : 'Chưa được coi là đã thanh toán. Với tiền mặt, cần nhân viên xác nhận đã nhận tiền. Với SePay Test Mode, tạo giao dịch mô phỏng đúng số tiền và nội dung ở trên.',
          ),
          if (_openError != null) Text(_openError!),
          if (sandbox && quote?.hasPendingPayment == true)
            FilledButton(
              onPressed: _opening ? null : _openCheckout,
              child: Text(
                _opening ? 'Đang mở...' : 'Mở trang thẻ thử SePay Sandbox',
              ),
            ),
          const SizedBox(height: 20),
          if (quote?.payment?.paymentMethod == 'SePayTest' &&
              quote?.hasPendingPayment == true) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      final ok = await provider.confirmSePayTest(widget.sessionId);
                      if (ok && mounted) {
                        await _read();
                      }
                    },
              child: Text(
                provider.isLoading
                    ? 'Đang xác nhận...'
                    : 'Xác nhận chuyển tiền thành công (SePay Test)',
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: provider.checking ? null : _read,
            child: const Text('Kiểm tra lại trạng thái'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (_) => false,
            ),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }
}
