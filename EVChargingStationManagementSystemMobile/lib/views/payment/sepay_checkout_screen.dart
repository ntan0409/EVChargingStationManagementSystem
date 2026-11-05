import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';

// The backend link is a short-lived capability, never a bearer JWT. Only the
// exact form URL and the sandbox checkout host may navigate inside this view.
bool isSePayCheckoutNavigationAllowed(Uri target, Uri initial) {
  if (target.userInfo.isNotEmpty) return false;
  return target == initial ||
      (target.scheme == 'https' &&
          target.host == 'pay-sandbox.sepay.vn' &&
          target.port == 443);
}

class SePayCheckoutScreen extends StatefulWidget {
  final Uri checkoutUrl;
  final String sessionId;
  const SePayCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.sessionId,
  });

  @override
  State<SePayCheckoutScreen> createState() => _SePayCheckoutScreenState();
}

class _SePayCheckoutScreenState extends State<SePayCheckoutScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  final _payments = PaymentService();
  Timer? _timer;
  bool _checking = false;
  bool _active = true;
  bool _closing = false;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target != null &&
                isSePayCheckoutNavigationAllowed(target, widget.checkoutUrl)) {
              return NavigationDecision.navigate;
            }
            if (request.isMainFrame && mounted) {
              setState(
                () => _error = 'Liên kết ngoài trang Sandbox đã bị chặn.',
              );
            }
            return NavigationDecision.prevent;
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _error = null);
          },
          onPageFinished: (_) => _check(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(
                () => _error =
                    'Không tải được trang thanh toán. Bạn có thể tải lại hoặc quay về hóa đơn.',
              );
            }
          },
          onHttpError: (error) {
            if (error.request?.uri == widget.checkoutUrl && mounted) {
              setState(
                () => _error =
                    'Trang thanh toán không khả dụng hoặc liên kết đã hết hạn. Quay về hóa đơn để mở lại.',
              );
            }
          },
        ),
      );
    _load();
    _startPolling();
  }

  Future<void> _load() async {
    try {
      await _controller.loadRequest(widget.checkoutUrl);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không mở được trang thanh toán. Hãy quay về hóa đơn và thử lại.',
        );
      }
    }
  }

  void _startPolling() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  Future<void> _check() async {
    if (!mounted || !_active || _checking || _closing) return;
    _checking = true;
    try {
      // Only the authenticated backend can confirm settlement. Page text,
      // redirects and JavaScript never grant a payment success result.
      final response = await _payments.getSessionPayment(widget.sessionId);
      if (mounted &&
          response.success &&
          response.data?.isPaid == true &&
          !_closing) {
        _closing = true;
        Navigator.of(context).pop();
      }
    } catch (_) {
      // The invoice remains pending when the network is unavailable.
    } finally {
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _startPolling();
      _check();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thanh toán thử SePay')),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Sandbox • Chỉ nhập thẻ thử • Không dùng tiền thật'),
          ),
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Tải lại trang'),
                  ),
                ],
              ),
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Trở về hóa đơn / Kiểm tra kết quả'),
            ),
          ),
        ],
      ),
    ),
  );
}
