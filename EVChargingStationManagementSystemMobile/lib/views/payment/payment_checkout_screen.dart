import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/formatters.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/voucher_provider.dart';
import '../widgets/api_problem.dart';
import '../widgets/custom_button.dart';
import 'payment_status_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final Future<bool> Function(Uri)? paymentLauncher;
  const PaymentCheckoutScreen({super.key, this.paymentLauncher});
  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  String? _method;
  String? _voucher;
  String? _readyUrl;
  String? _localError;
  bool _working = false;
  bool _mustCheck = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final session = context.read<ChargingSessionProvider>().currentSession;
    if (session == null) return;
    final payments = context.read<PaymentProvider>();
    await Future.wait([
      payments.fetchQuote(session.id),
      payments.fetchMethods(),
      context.read<VoucherProvider>().fetchVouchers(),
    ]);
    if (!mounted) return;
    setState(() {
      if (!payments.methods.any((m) => m.id == _method && m.available)) {
        _method = payments.methods.where((m) => m.available).firstOrNull?.id;
      }
    });
  }

  void _status(String id) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => PaymentStatusScreen(sessionId: id)));
  Future<void> _check() async {
    final session = context.read<ChargingSessionProvider>().currentSession;
    if (session == null) return;
    final ok = await context.read<PaymentProvider>().fetchQuote(session.id);
    if (mounted && ok) {
      setState(() {
        _mustCheck = false;
        _localError = null;
      });
    }
  }

  Future<void> _apply() async {
    final id = context.read<ChargingSessionProvider>().currentSession?.id;
    final voucher = _voucher;
    if (id == null || voucher == null || _working) return;
    setState(() {
      _working = true;
      _localError = null;
    });
    final vouchers = context.read<VoucherProvider>();
    final charging = context.read<ChargingSessionProvider>();
    final payments = context.read<PaymentProvider>();
    final accepted = await vouchers.applyVoucher(voucher, id);
    if (!mounted) return;
    if (accepted) {
      await Future.wait([charging.refreshSession(), payments.fetchQuote(id)]);
    }
    if (mounted) {
      setState(() {
        _working = false;
        _voucher = null;
        if (!accepted) _localError = vouchers.errorMessage;
      });
    }
  }

  Future<void> _pay() async {
    final session = context.read<ChargingSessionProvider>().currentSession;
    final payments = context.read<PaymentProvider>();
    final quote = payments.quote;
    if (_working ||
        session == null ||
        quote == null ||
        quote.sessionId != session.id) {
      return;
    }
    if (quote.isPaid || quote.hasPendingPayment) {
      _status(session.id);
      return;
    }
    if (_mustCheck ||
        quote.sessionStatus != 'Completed' ||
        !payments.methods.any((m) => m.available && m.id == _method)) {
      return;
    }
    setState(() {
      _working = true;
      _localError = null;
      _readyUrl = null;
    });
    if (_method == 'VNPay') {
      final url = await payments.generateVNPayUrl(session.id);
      final error = payments.errorMessage;
      await payments.fetchQuote(
        session.id,
      ); // Read-only reconciliation, never re-POST.
      if (mounted) {
        setState(() {
          _readyUrl = url;
          _working = false;
          _mustCheck = url == null;
          _localError = url == null
              ? error ??
                    'Chưa xác nhận tạo URL thanh toán. Hãy kiểm tra trạng thái.'
              : null;
        });
      }
    } else if (_method == 'Offline' || _method == 'SePayTest') {
      final accepted = _method == 'SePayTest'
          ? await payments.processSePayTest(session.id)
          : await payments.processOfflinePayment(session.id);
      final error = payments.errorMessage;
      await payments.fetchQuote(session.id);
      if (!mounted) return;
      setState(() {
        _working = false;
        _mustCheck = !accepted;
        if (!accepted) _localError = error;
      });
      if (accepted) _status(session.id); // Pending screen, not a receipt.
    } else {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _open() async {
    final url = _readyUrl;
    final id = context.read<ChargingSessionProvider>().currentSession?.id;
    if (url == null || id == null || _working) return;
    setState(() => _working = true);
    try {
      final opened =
          await (widget.paymentLauncher?.call(Uri.parse(url)) ??
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));
      if (!mounted) return;
      setState(() {
        _working = false;
        if (!opened) {
          _localError =
              'Không mở được cổng thanh toán. Yêu cầu vẫn chờ xác nhận; kiểm tra trạng thái hoặc mở lại.';
        }
      });
      if (opened) _status(id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _working = false;
          _localError =
              'Không mở được cổng thanh toán. Chưa xác nhận đã thanh toán.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final charging = context.watch<ChargingSessionProvider>();
    final payments = context.watch<PaymentProvider>();
    final vouchers = context.watch<VoucherProvider>();
    final session = charging.currentSession;
    final quote = payments.quote?.sessionId == session?.id
        ? payments.quote
        : null;
    final busy =
        _working ||
        payments.isLoading ||
        payments.checking ||
        vouchers.isLoading;
    final owned = vouchers.ownedVouchers.where((v) => v.isUsable).toList();
    final applied = vouchers.ownedVouchers
        .where((v) => v.sessionId == session?.id && v.status == 'Used')
        .firstOrNull;
    final selected = owned.any((v) => v.id == _voucher) ? _voucher : null;
    final canCreate =
        quote != null &&
        quote.sessionStatus == 'Completed' &&
        !quote.hasPendingPayment &&
        !quote.isPaid &&
        !_mustCheck;
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh Toán Hóa Đơn')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (session == null) ...[
            const Text('Không có phiên sạc hợp lệ để thanh toán.'),
            OutlinedButton(
              onPressed: charging.isLoading
                  ? null
                  : () async {
                      await charging.restoreSession();
                      if (mounted) await _load();
                    },
              child: const Text('Tải phiên từ máy chủ'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            if (payments.checking) const LinearProgressIndicator(),
            if (payments.errorMessage != null)
              ApiProblem(message: payments.errorMessage!, onRetry: _check),
            if (quote != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'HÓA ĐƠN TỪ MÁY CHỦ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _row('Trạng thái phiên', quote.sessionStatus),
                      _row(
                        'Chi phí phiên sau ưu đãi',
                        Formatters.formatCurrency(quote.beforeVatAmount),
                      ),
                      _row('Thuế VAT', '${quote.taxRate}%'),
                      _row(
                        'Tổng theo máy chủ',
                        Formatters.formatCurrency(quote.amount),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (vouchers.isLoading) const LinearProgressIndicator(),
            if (vouchers.errorMessage != null)
              ApiProblem(
                message: vouchers.errorMessage!,
                onRetry: vouchers.fetchVouchers,
              ),
            if (applied != null)
              Text('Máy chủ đã áp dụng: ${applied.voucherName}'),
            if (applied == null &&
                quote?.payment == null &&
                canCreate &&
                owned.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                hint: const Text('Chọn voucher đã đổi'),
                items: owned
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(v.voucherName),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => _voucher = value),
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Áp dụng voucher trên máy chủ',
                onPressed: selected == null || busy ? null : _apply,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Phương thức thanh toán',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (payments.methodsLoading) const LinearProgressIndicator(),
            if (payments.methodsError != null)
              ApiProblem(
                message: payments.methodsError!,
                onRetry: payments.fetchMethods,
              ),
            if (!payments.methodsLoading &&
                payments.methods.isEmpty &&
                payments.methodsError == null)
              const Text('Máy chủ chưa cung cấp phương thức thanh toán.'),
            for (final method in payments.methods)
              RadioListTile<String>(
                value: method.id,
                groupValue: _method,
                title: Text(method.name),
                subtitle: method.available ? null : const Text('Chưa khả dụng'),
                onChanged: busy || !method.available || !canCreate
                    ? null
                    : (value) => setState(() => _method = value),
              ),
            const SizedBox(height: 20),
            if (_localError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _localError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_readyUrl != null) ...[
              CustomButton(
                text: 'Mở VNPAY Sandbox',
                onPressed: busy ? null : _open,
              ),
              const SizedBox(height: 12),
            ],
            CustomButton(
              text: quote?.isPaid == true || quote?.hasPendingPayment == true
                  ? 'Xem trạng thái thanh toán'
                  : 'Tạo yêu cầu thanh toán',
              isLoading: _working || payments.isLoading,
              onPressed:
                  busy ||
                      quote == null ||
                      (!canCreate && !quote.isPaid && !quote.hasPendingPayment)
                  ? null
                  : _pay,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: busy ? null : _check,
              child: const Text('Kiểm tra trạng thái / hóa đơn'),
            ),
            const SizedBox(height: 12),
            const Text('Hóa đơn hoàn tất khi máy chủ xác nhận thanh toán.'),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
