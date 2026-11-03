import 'package:flutter/material.dart';
import '../core/network/api_response.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherService _voucherService;
  VoucherProvider({VoucherService? voucherService})
    : _voucherService = voucherService ?? VoucherService();
  List<VoucherModel> _vouchers = [];
  List<UserVoucherModel> _owned = [];
  int? _points;
  bool _fetching = false;
  bool _mutating = false;
  bool _disposed = false;
  int _epoch = 0;
  String? _errorMessage;
  String? _account;
  List<VoucherModel> get vouchers => List.unmodifiable(_vouchers);
  List<UserVoucherModel> get ownedVouchers => List.unmodifiable(_owned);
  int? get points => _points;
  bool get isLoading => _fetching || _mutating;
  String? get errorMessage => _errorMessage;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _active(int epoch) => !_disposed && epoch == _epoch;
  void bindAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _epoch++;
    _vouchers = [];
    _owned = [];
    _points = null;
    _fetching = _mutating = false;
    _errorMessage = null;
    Future.microtask(_notify);
  }

  Future<void> fetchVouchers() async {
    if (_disposed || _fetching) return;
    final epoch = _epoch;
    _fetching = true;
    _errorMessage = null;
    _vouchers = [];
    _owned = [];
    _points = null;
    _notify();
    try {
      final responses = await Future.wait<Object>([
        _voucherService.getAvailableVouchers(),
        _voucherService.getMyVouchers(),
        _voucherService.getPoints(),
      ]);
      if (!_active(epoch)) return;
      final catalog = responses[0] as ApiResponse<List<VoucherModel>>;
      final owned = responses[1] as ApiResponse<List<UserVoucherModel>>;
      final points = responses[2] as ApiResponse<int>;
      if (!catalog.success || catalog.data == null) {
        _errorMessage = catalog.message;
      } else if (!owned.success || owned.data == null) {
        _errorMessage = owned.message;
      } else if (!points.success || points.data == null) {
        _errorMessage = points.message;
      } else {
        _vouchers = catalog.data!;
        _owned = owned.data!;
        _points = points.data;
      }
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage = 'Không tải được voucher và điểm thưởng từ máy chủ.';
      }
    } finally {
      if (_active(epoch)) {
        _fetching = false;
        _notify();
      }
    }
  }

  Future<bool> redeemVoucher(String voucherId) async {
    if (_disposed || isLoading) return false;
    final epoch = _epoch;
    _mutating = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _voucherService.redeemVoucher(voucherId);
      if (!_active(epoch)) return false;
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        return false;
      }
      await fetchVouchers();
      return true;
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage =
            'Chưa xác nhận đổi voucher. Hãy tải lại danh sách trước khi thử lại.';
      }
      return false;
    } finally {
      if (_active(epoch)) {
        _mutating = false;
        _notify();
      }
    }
  }

  Future<bool> applyVoucher(String userVoucherId, String sessionId) async {
    if (_disposed || isLoading) return false;
    final epoch = _epoch;
    _mutating = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _voucherService.useVoucher(
        userVoucherId,
        sessionId,
      );
      if (!_active(epoch)) return false;
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        return false;
      }
      await fetchVouchers();
      return true;
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage =
            'Chưa xác nhận áp dụng voucher. Kiểm tra lại phiên trước khi thử lại.';
      }
      return false;
    } finally {
      if (_active(epoch)) {
        _mutating = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
