import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService;
  BookingProvider({BookingService? bookingService})
    : _bookingService = bookingService ?? BookingService();
  List<BookingModel> _bookings = [];
  bool _isLoading = false, _disposed = false;
  int _epoch = 0;
  String? _account, _errorMessage;
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  List<BookingModel> get activeBookings =>
      _bookings.where((b) => b.isScheduled || b.isInProgress).toList();
  List<BookingModel> get historyBookings =>
      _bookings.where((b) => b.isCompleted || b.isCancelled).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void bindAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _epoch++;
    _bookings = [];
    _isLoading = false;
    _errorMessage = null;
    Future.microtask(_notify);
  }

  Future<void> fetchMyBookings({bool silent = false}) async {
    if (_disposed) return;
    if (_isLoading && !silent) return;
    final epoch = _epoch;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      _bookings = [];
      _notify();
    }
    try {
      final result = await _bookingService.getMyBookings();
      if (_disposed || epoch != _epoch) return;
      if (result.success && result.data != null) {
        _bookings = result.data!;
        _errorMessage = null;
      } else if (!silent) {
        _errorMessage = result.message;
      }
    } catch (_) {
      if (!_disposed && epoch == _epoch && !silent) {
        _errorMessage = 'Không tải được lịch đặt.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        if (!silent) _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> createBooking({
    required String stationId,
    required String vehicleId,
    required DateTime startTime,
  }) async {
    if (_disposed || _isLoading) return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final result = await _bookingService.createBooking(
        stationId: stationId,
        vehicleId: vehicleId,
        startTime: startTime,
      );
      if (_disposed || epoch != _epoch) return false;
      if (!result.success || result.data == null) {
        _errorMessage = result.message;
        return false;
      }
      _bookings = [
        result.data!,
        ..._bookings.where((b) => b.id != result.data!.id),
      ];
      return true;
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        _errorMessage =
            'Chưa xác nhận đặt lịch. Kiểm tra danh sách trước khi thử lại.';
      }
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> _mutate(Future<dynamic> Function() action) async {
    if (_disposed || _isLoading) return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    var accepted = false;
    try {
      final result = await action();
      if (_disposed || epoch != _epoch) return false;
      accepted = result.success;
      if (!accepted) _errorMessage = result.message;
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        _errorMessage = 'Chưa xác nhận thao tác với máy chủ.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
    if (accepted && !_disposed && epoch == _epoch) await fetchMyBookings();
    return accepted;
  }

  Future<bool> checkIn(String code) =>
      _mutate(() => _bookingService.checkInBooking(code));
  Future<bool> cancelBooking(String id) =>
      _mutate(() => _bookingService.cancelBooking(id));
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
