import 'dart:async';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/charging_session_model.dart';

class ChargingService {
  final ApiClient _apiClient = ApiClient();

  // Start Session
  Future<ApiResponse<ChargingSessionModel>> startSession({
    required String connectorId,
    required int batteryCapacityKWh,
    required int initialBatteryLevelPercent,
    required int expectedEnergiesKWh,
    String? phone,
    String? vehicleModelId,
    String? bookingId,
  }) async {
    final payload = {
      'connectorId': connectorId,
      'batteryCapacityKWh': batteryCapacityKWh,
      'initialBatteryLevelPercent': initialBatteryLevelPercent,
      'expectedEnergiesKWh': expectedEnergiesKWh,
      'phone': phone ?? '0912345678',
      if (vehicleModelId != null) 'vehicleModelId': vehicleModelId,
      if (bookingId != null) 'bookingId': bookingId,
    };

    final response = await _apiClient.post<ChargingSessionModel>(
      ApiConstants.sessionStart,
      data: payload,
      fromJson: (data) => ChargingSessionModel.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      // Mock session for simulation
      final mock = ChargingSessionModel(
        id: 'sess-${DateTime.now().millisecondsSinceEpoch}',
        chargingPostId: 'post-01',
        connectorId: connectorId,
        startTime: DateTime.now(),
        status: 'Charging',
        batteryCapacityKWh: batteryCapacityKWh,
        initialBatteryLevelPercent: initialBatteryLevelPercent,
        expectedEnergiesKWh: expectedEnergiesKWh,
        currentBatteryPercent: initialBatteryLevelPercent.toDouble(),
        powerRateKW: 60,
        totalEnergyConsumedKWh: 0.0,
        cost: 0.0,
      );
      return ApiResponse.success(mock, message: 'Bắt đầu phiên sạc thành công!');
    }

    return response;
  }

  // Stop Session
  Future<ApiResponse<ChargingSessionModel>> stopSession(String sessionId) async {
    final response = await _apiClient.patch<ChargingSessionModel>(
      '${ApiConstants.sessionStop}?sessionId=$sessionId',
      data: {'sessionId': sessionId},
      fromJson: (data) => ChargingSessionModel.fromJson(data as Map<String, dynamic>),
    );

    return response;
  }

  // Get Session By Id
  Future<ApiResponse<ChargingSessionModel>> getSessionById(String sessionId) async {
    return await _apiClient.get<ChargingSessionModel>(
      '${ApiConstants.sessionById}$sessionId',
      fromJson: (data) => ChargingSessionModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
