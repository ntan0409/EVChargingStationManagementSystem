import 'dart:async';
import 'package:flutter/material.dart';
import '../models/charging_session_model.dart';
import '../services/charging_service.dart';

class ChargingSessionProvider extends ChangeNotifier {
  final ChargingService _chargingService = ChargingService();

  ChargingSessionModel? _currentSession;
  Timer? _telemetryTimer;
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time telemetry extras
  double _currentPowerKW = 60.0;
  double _currentVoltageV = 398.5;
  double _currentAmperageA = 150.2;
  double _pricePerKWh = 3850.0;
  double _vatRate = 10.0;

  ChargingSessionModel? get currentSession => _currentSession;
  bool get isCharging => _currentSession != null && _currentSession!.status == 'Charging';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get currentPowerKW => _currentPowerKW;
  double get currentVoltageV => _currentVoltageV;
  double get currentAmperageA => _currentAmperageA;
  double get pricePerKWh => _pricePerKWh;
  double get vatRate => _vatRate;

  // Start Charging Session
  Future<bool> startCharging({
    required String connectorId,
    required int batteryCapacityKWh,
    required int initialBatteryLevelPercent,
    required int expectedEnergiesKWh,
    String? phone,
    String? vehicleModelId,
    String? bookingId,
    double stationPowerKw = 60.0,
    double price = 3850.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _pricePerKWh = price;
    _currentPowerKW = stationPowerKw;
    notifyListeners();

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

      _isLoading = false;
      if (response.success && response.data != null) {
        _currentSession = response.data;
        _startTelemetryTimer();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Stop Charging Session
  Future<bool> stopCharging() async {
    if (_currentSession == null) return false;

    _isLoading = true;
    notifyListeners();

    _telemetryTimer?.cancel();
    _telemetryTimer = null;

    try {
      await _chargingService.stopSession(_currentSession!.id);
      _currentSession = _currentSession!.copyWith(
        status: 'Completed',
        endTime: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _currentSession = _currentSession!.copyWith(
        status: 'Completed',
        endTime: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  // Clear Session after payment
  void resetSession() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _currentSession = null;
    notifyListeners();
  }

  // Telemetry loop: simulated IoT updates every second
  void _startTelemetryTimer() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession == null || _currentSession!.status != 'Charging') {
        timer.cancel();
        return;
      }

      final elapsed = _currentSession!.elapsedSeconds + 1;
      
      // Calculate energy added per second based on power: kWh = (kW * hours)
      // For smooth demo visualization, add ~ 0.05 kWh per second
      final energyIncrement = (_currentPowerKW / 3600.0) * 4.0; 
      final totalEnergy = _currentSession!.totalEnergyConsumedKWh + energyIncrement;

      // Calculate battery percent increase
      final capacity = _currentSession!.batteryCapacityKWh;
      final batteryPercentIncrease = (totalEnergy / capacity) * 100.0;
      double newBattery = _currentSession!.initialBatteryLevelPercent + batteryPercentIncrease;

      if (newBattery >= _currentSession!.expectedEnergiesKWh) {
        newBattery = _currentSession!.expectedEnergiesKWh.toDouble();
        _currentSession = _currentSession!.copyWith(
          status: 'Completed',
          currentBatteryPercent: newBattery,
          totalEnergyConsumedKWh: totalEnergy,
          cost: totalEnergy * _pricePerKWh * (1 + _vatRate / 100.0),
          elapsedSeconds: elapsed,
          endTime: DateTime.now(),
        );
        timer.cancel();
        notifyListeners();
        return;
      }

      // Fluctuations for realistic IoT reading
      _currentVoltageV = 398.0 + (elapsed % 5) * 0.4;
      _currentAmperageA = (_currentPowerKW * 1000) / _currentVoltageV;

      final currentCost = totalEnergy * _pricePerKWh * (1 + _vatRate / 100.0);

      _currentSession = _currentSession!.copyWith(
        currentBatteryPercent: newBattery,
        totalEnergyConsumedKWh: totalEnergy,
        cost: currentCost,
        elapsedSeconds: elapsed,
      );

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
