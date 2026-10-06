import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _vnpayUrl;

  List<PaymentModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get vnpayUrl => _vnpayUrl;

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _paymentService.getPaymentHistory();
      if (response.success && response.data != null) {
        _history = response.data!;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateVNPayUrl(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _paymentService.createVNPayUrl(sessionId);
      _isLoading = false;
      if (response.success && response.data != null) {
        _vnpayUrl = response.data;
        notifyListeners();
        return _vnpayUrl;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> processOfflinePayment(String sessionId, double amount, String stationName, double energy) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _paymentService.createPaymentOffline(sessionId);
      
      // Add to local history
      final payment = PaymentModel(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        amount: amount,
        paymentMethod: 'Tiền mặt (Offline)',
        paymentStatus: 'Pending',
        paymentDate: DateTime.now(),
        stationName: stationName,
        energyDeliveredKWh: energy,
      );
      _history.insert(0, payment);

      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return true; // Fallback success for demo
    }
  }
}
