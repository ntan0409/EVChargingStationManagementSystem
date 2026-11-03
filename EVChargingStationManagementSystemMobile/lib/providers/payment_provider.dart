import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../models/transaction_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;
  PaymentProvider({PaymentService? paymentService})
    : _paymentService = paymentService ?? PaymentService();
  List<TransactionModel> _history = [];
  List<PaymentMethodModel> _methods = [];
  SessionPaymentModel? _quote;
  bool _isLoading = false;
  bool _historyLoading = false;
  bool _checking = false;
  bool _methodsLoading = false;
  bool _disposed = false;
  int _epoch = 0;
  int _quoteEpoch = 0;
  String? _errorMessage;
  String? _historyError;
  String? _methodsError;
  String? _vnpayUrl;
  String? _account;
  List<TransactionModel> get history => List.unmodifiable(_history);
  List<PaymentMethodModel> get methods => List.unmodifiable(_methods);
  SessionPaymentModel? get quote => _quote;
  bool get isLoading => _isLoading;
  bool get historyLoading => _historyLoading;
  bool get checking => _checking;
  bool get methodsLoading => _methodsLoading;
  String? get errorMessage => _errorMessage;
  String? get historyError => _historyError;
  String? get methodsError => _methodsError;
  String? get vnpayUrl => _vnpayUrl;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _active(int epoch) => !_disposed && epoch == _epoch;
  void bindAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _epoch++;
    _quoteEpoch++;
    _history = [];
    _quote = null;
    _vnpayUrl = null;
    _methods = [];
    _errorMessage = _historyError = _methodsError = null;
    _isLoading = _historyLoading = _checking = _methodsLoading = false;
    Future.microtask(_notify);
  }

  Future<void> fetchHistory() async {
    if (_disposed || _historyLoading) return;
    final epoch = _epoch;
    _historyLoading = true;
    _historyError = null;
    _history = [];
    _notify();
    try {
      final response = await _paymentService.getPaymentHistory();
      if (!_active(epoch)) return;
      if (response.success && response.data != null) {
        _history = response.data!;
      } else {
        _historyError = response.message;
      }
    } catch (_) {
      if (_active(epoch)) _historyError = 'Không tải được lịch sử giao dịch.';
    } finally {
      if (_active(epoch)) {
        _historyLoading = false;
        _notify();
      }
    }
  }

  Future<void> fetchMethods() async {
    if (_disposed || _methodsLoading) return;
    final epoch = _epoch;
    _methodsLoading = true;
    _methodsError = null;
    _methods = [];
    _notify();
    try {
      final response = await _paymentService.getMethods();
      if (!_active(epoch)) return;
      if (response.success && response.data != null) {
        _methods = response.data!;
      } else {
        _methodsError = response.message;
      }
    } catch (_) {
      if (_active(epoch)) {
        _methodsError = 'Không tải được phương thức thanh toán.';
      }
    } finally {
      if (_active(epoch)) {
        _methodsLoading = false;
        _notify();
      }
    }
  }

  Future<bool> fetchQuote(String sessionId) async {
    if (_disposed) return false;
    final epoch = _epoch;
    final request = ++_quoteEpoch;
    _checking = true;
    _quote = null;
    _errorMessage = null;
    _notify();
    try {
      final response = await _paymentService.getSessionPayment(sessionId);
      if (!_active(epoch) || request != _quoteEpoch) return false;
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        return false;
      }
      _quote = response.data;
      return true;
    } catch (_) {
      if (_active(epoch) && request == _quoteEpoch) {
        _errorMessage =
            'Không xác minh được hóa đơn. Không tạo yêu cầu mới trước khi kiểm tra lại.';
      }
      return false;
    } finally {
      if (_active(epoch) && request == _quoteEpoch) {
        _checking = false;
        _notify();
      }
    }
  }

  Future<String?> generateVNPayUrl(String sessionId) async {
    if (_disposed || _isLoading) return null;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _vnpayUrl = null;
    _notify();
    try {
      final response = await _paymentService.createVNPayUrl(sessionId);
      if (!_active(epoch)) return null;
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        return null;
      }
      _vnpayUrl = response.data;
      return _vnpayUrl;
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage =
            'Chưa xác nhận yêu cầu thanh toán. Kiểm tra trạng thái trước khi thử lại.';
      }
      return null;
    } finally {
      if (_active(epoch)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  // Legacy display arguments are deliberately ignored; money comes from the server.
  Future<bool> processOfflinePayment(
    String sessionId, [
    double? amount,
    String? stationName,
    double? energy,
  ]) async {
    if (_disposed || _isLoading) return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _paymentService.createPaymentOffline(sessionId);
      if (!_active(epoch)) return false;
      if (!response.success ||
          response.data == null ||
          response.data!.paymentStatus != 'Initiated') {
        _errorMessage = response.message.isEmpty
            ? 'Chưa xác nhận được yêu cầu tại quầy.'
            : response.message;
        return false;
      }
      // Creation is only an acknowledged pending request. Never insert a ledger row here.
      return true;
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage =
            'Chưa xác nhận yêu cầu tại quầy. Hãy kiểm tra trạng thái.';
      }
      return false;
    } finally {
      if (_active(epoch)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _quoteEpoch++;
    super.dispose();
  }
}
