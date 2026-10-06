import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleModel> get vehicles => _vehicles;
  VehicleModel? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  Future<void> fetchVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vehicleService.getVehicleModels();
      if (response.success && response.data != null) {
        _vehicles = response.data!;
        if (_selectedVehicle == null && _vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.first;
        }
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

  Future<bool> addVehicle(VehicleModel vehicle) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _vehicleService.addVehicle(vehicle);
      _isLoading = false;
      if (response.success) {
        _vehicles.add(vehicle);
        _selectedVehicle ??= vehicle;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _vehicleService.deleteVehicle(vehicleId);
      _isLoading = false;
      if (response.success) {
        _vehicles.removeWhere((v) => v.id == vehicleId);
        if (_selectedVehicle?.id == vehicleId) {
          _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
