import 'package:flutter/material.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherService _voucherService = VoucherService();

  List<VoucherModel> _vouchers = [];
  VoucherModel? _selectedVoucher;
  bool _isLoading = false;
  String? _errorMessage;

  List<VoucherModel> get vouchers => _vouchers;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void selectVoucher(VoucherModel? voucher) {
    if (_selectedVoucher?.id == voucher?.id) {
      _selectedVoucher = null; // Unselect if tapping same
    } else {
      _selectedVoucher = voucher;
    }
    notifyListeners();
  }

  Future<void> fetchVouchers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _voucherService.getAvailableVouchers();
      if (response.success && response.data != null) {
        _vouchers = response.data!;
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

  Future<bool> redeemVoucher(String voucherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _voucherService.redeemVoucher(voucherId);
      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
