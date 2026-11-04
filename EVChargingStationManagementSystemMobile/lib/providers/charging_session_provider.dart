import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_response.dart';
import '../models/charging_session_model.dart';
import '../services/charging_service.dart';

class ChargingSessionProvider extends ChangeNotifier {
  final ChargingService _chargingService;
  final Duration? pollInterval;
  ChargingSessionProvider({
    ChargingService? chargingService,
    this.pollInterval = const Duration(seconds: 5),
  }) : _chargingService = chargingService ?? ChargingService();
  ChargingSessionModel? _currentSession;
  Timer? _pollTimer;
  bool _isLoading = false;
  bool _refreshing = false;
  bool _disposed = false;
  bool _needsReconciliation = false;
  int _epoch = 0;
  String? _errorMessage;
  String? _account;

  ChargingSessionModel? get currentSession => _currentSession;
  bool get isCharging => _currentSession?.status == 'Charging';
  bool get isLoading => _isLoading;
  bool get needsReconciliation => _needsReconciliation;
  String? get errorMessage => _errorMessage;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _active(int epoch) => !_disposed && epoch == _epoch;
  void bindAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _epoch++;
    _pollTimer?.cancel();
    _currentSession = null;
    _isLoading = false;
    _refreshing = false;
    _needsReconciliation = false;
    _errorMessage = null;
    scheduleMicrotask(_notify);
  }

  Future<bool> startCharging({
    required String connectorId,
    required int batteryCapacityKWh,
    required int initialBatteryLevelPercent,
    required int expectedEnergiesKWh,
    String? phone,
    String? vehicleModelId,
    String? bookingId,
    double? stationPowerKw,
    double? price,
  }) async {
    if (_disposed || _isLoading) return false;
    if (_needsReconciliation ||
        (_currentSession != null && _currentSession!.status != 'Paid')) {
      _errorMessage =
          'Hãy kiểm tra và xử lý phiên hiện tại trước khi tạo phiên mới.';
      _notify();
      return false;
    }
    final epoch = ++_epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _chargingService.startSession(
        connectorId: connectorId,
        batteryCapacityKWh: batteryCapacityKWh,
        initialBatteryLevelPercent: initialBatteryLevelPercent,
        expectedEnergiesKWh: expectedEnergiesKWh,
        phone: phone,
        vehicleModelId: vehicleModelId,
        bookingId: bookingId,
      );
      if (!_active(epoch)) return false;
      if (!response.success ||
          response.data == null ||
          response.data!.status != 'Charging') {
        _errorMessage = response.message.isEmpty
            ? 'Máy chủ chưa xác nhận bắt đầu sạc.'
            : response.message;
        _needsReconciliation =
            response.statusCode == null ||
            response.statusCode! >= 500 ||
            response.errorType == ApiErrorType.parse;
        return false;
      }
      _currentSession = response.data;
      _needsReconciliation = false;
      _poll();
      return true;
    } catch (_) {
      if (_active(epoch)) {
        _needsReconciliation = true;
        _errorMessage =
            'Chưa xác nhận được kết quả. Kiểm tra phiên trước khi tạo lại.';
      }
      return false;
    } finally {
      if (_active(epoch)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> restoreSession() async {
    if (_disposed || _isLoading) return false;
    final epoch = ++_epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _chargingService.getCurrentSession();
      if (!_active(epoch)) return false;
      if (response.statusCode == 404) {
        _currentSession = null;
        _needsReconciliation = false;
        _pollTimer?.cancel();
        return true;
      }
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        return false;
      }
      _currentSession = response.data;
      _needsReconciliation = false;
      _poll();
      return true;
    } catch (_) {
      if (_active(epoch)) _errorMessage = 'Không tải được phiên hiện tại.';
      return false;
    } finally {
      if (_active(epoch)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> refreshSession() async {
    final session = _currentSession;
    if (session == null) return restoreSession();
    if (_disposed || _isLoading || _refreshing) return false;
    final epoch = _epoch;
    _refreshing = true;
    try {
      final response = await _chargingService.getSessionById(session.id);
      if (!_active(epoch)) return false;
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        _notify();
        return false;
      }
      _currentSession = response.data;
      _needsReconciliation = false;
      _errorMessage = null;
      if (!isCharging) _pollTimer?.cancel();
      _notify();
      return true;
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage =
            'Không tải được trạng thái phiên. Dữ liệu hiển thị có thể đã cũ.';
        _notify();
      }
      return false;
    } finally {
      if (_active(epoch)) _refreshing = false;
    }
  }

  Future<bool> stopCharging({double? energyDeliveredKWh}) async {
    if (_disposed || _isLoading || _currentSession == null) return false;
    if (energyDeliveredKWh == null
        ? !_currentSession!.demoReadingEnabled
        : !energyDeliveredKWh.isFinite || energyDeliveredKWh < 0) {
      _errorMessage =
          'Nhập số đo điện năng thực từ cổng sạc (kWh) để dừng phiên.';
      _notify();
      return false;
    }
    final epoch = ++_epoch;
    final id = _currentSession!.id;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _chargingService.stopSession(
        id,
        energyDeliveredKWh: energyDeliveredKWh,
        demoReading: energyDeliveredKWh == null,
      );
      if (!_active(epoch)) return false;
      if (!response.success ||
          response.data == null ||
          response.data!.status != 'Completed') {
        _errorMessage = response.message.isEmpty
            ? 'Máy chủ chưa xác nhận dừng sạc.'
            : response.message;
        return false;
      }
      _currentSession = response.data;
      _pollTimer?.cancel();
      return true;
    } catch (_) {
      if (_active(epoch)) {
        _errorMessage = 'Chưa xác nhận dừng sạc. Hãy kiểm tra trạng thái.';
      }
      return false;
    } finally {
      if (_active(epoch)) {
        _isLoading = false;
        _refreshing = false;
        _notify();
      }
    }
  }

  void resetSession() {
    _epoch++;
    _pollTimer?.cancel();
    _currentSession = null;
    _isLoading = false;
    _refreshing = false;
    _needsReconciliation = false;
    _errorMessage = null;
    _notify();
  }

  void _poll() {
    _pollTimer?.cancel();
    if (pollInterval != null && isCharging) {
      _pollTimer = Timer.periodic(pollInterval!, (_) {
        unawaited(refreshSession());
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _pollTimer?.cancel();
    super.dispose();
  }
}
