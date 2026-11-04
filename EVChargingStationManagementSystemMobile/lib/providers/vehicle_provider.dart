import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../services/driver_journey_service.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService;
  final DriverJourneyService _journeyService;
  VehicleProvider({
    VehicleService? vehicleService,
    DriverJourneyService? journeyService,
  }) : _vehicleService = vehicleService ?? VehicleService(),
       _journeyService = journeyService ?? DriverJourneyService();
  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  bool _isLoading = false;
  bool _disposed = false;
  int _epoch = 0;
  String? _errorMessage;
  String? _account;
  List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
  VehicleModel? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void bindAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _epoch++;
    _vehicles = [];
    _selectedVehicle = null;
    _isLoading = false;
    _errorMessage = null;
    Future.microtask(_notify);
  }

  Future<bool> selectVehicle(VehicleModel vehicle) async {
    if (_disposed || _isLoading || !_vehicles.any((v) => v.id == vehicle.id))
      return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final result = await _journeyService.getState();
      if (_disposed || epoch != _epoch) return false;
      final state = result.data;
      if (!result.success ||
          state == null ||
          (_account != null &&
              state.accountId.toLowerCase() != _account!.toLowerCase())) {
        _errorMessage = result.message;
        return false;
      }
      if (!state.eligibleVehicleModelIds.contains(vehicle.id) ||
          (!state.canChangeVehicle &&
              state.activeBooking?.vehicleId != vehicle.id)) {
        _errorMessage =
            'Không đổi sang xe khác khi còn lịch đặt/phiên sạc, hoặc xe chưa được máy chủ xác nhận hợp lệ.';
        return false;
      }
      _selectedVehicle = vehicle;
      return true;
    } catch (_) {
      if (!_disposed && epoch == _epoch)
        _errorMessage = 'Chưa xác minh được điều kiện đổi xe.';
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> fetchVehicles() async {
    if (_disposed) return;
    final selectedId = _selectedVehicle?.id;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final response = await _vehicleService.getMyVehicleModels();
      if (_disposed) return;
      if (response.success && response.data != null) {
        _vehicles = response.data!;
        _selectedVehicle =
            _vehicles.where((v) => v.id == selectedId).firstOrNull ??
            _vehicles.firstOrNull;
      } else {
        _errorMessage = response.message;
      }
    } catch (_) {
      if (!_disposed) {
        _errorMessage = 'Không tải được xe trong hồ sơ.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> addVehicle(VehicleModel vehicle) async {
    if (_disposed || _isLoading) return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    final response = await _vehicleService.addVehicle(vehicle);
    if (_disposed || epoch != _epoch) return false;
    _isLoading = false;
    if (!response.success) {
      _errorMessage = response.message;
      _notify();
      return false;
    }
    await fetchVehicles();
    return _vehicles.any((v) => v.id == vehicle.id);
  }

  Future<bool> deleteVehicle(String id) async {
    if (_disposed || _isLoading) return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    final response = await _vehicleService.deleteVehicle(id);
    if (_disposed || epoch != _epoch) return false;
    _isLoading = false;
    if (!response.success) {
      _errorMessage = response.message;
      _notify();
      return false;
    }
    await fetchVehicles();
    return _errorMessage == null && !_vehicles.any((v) => v.id == id);
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
