import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/charging_session_model.dart';

class ChargingService {
  final ApiClient _apiClient;
  ChargingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<ChargingSessionModel>> startSession({
    required String connectorId,
    required int batteryCapacityKWh,
    required int initialBatteryLevelPercent,
    required int expectedEnergiesKWh,
    String? phone,
    String? vehicleModelId,
    String? bookingId,
  }) => _apiClient.post(
    ApiConstants.sessionStart,
    data: {
      'connectorId': connectorId,
      'batteryCapacityKWh': batteryCapacityKWh,
      'initialBatteryLevelPercent': initialBatteryLevelPercent,
      'expectedEnergiesKWh': expectedEnergiesKWh,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (vehicleModelId != null) 'vehicleModelId': vehicleModelId,
      if (bookingId != null) 'bookingId': bookingId,
    },
    fromJson: (value) => ChargingSessionModel.fromJson(contractMap(value)),
  );

  Future<ApiResponse<ChargingSessionModel>> stopSession(
    String sessionId, {
    double? energyDeliveredKWh,
  }) async {
    if (energyDeliveredKWh == null ||
        !energyDeliveredKWh.isFinite ||
        energyDeliveredKWh < 0) {
      return invalidInput(
        'Cần số đo điện năng thực (kWh) để dừng phiên; không dùng năng lượng mô phỏng.',
      );
    }
    return _apiClient.patch(
      ApiConstants.sessionStop,
      queryParameters: {'sessionId': sessionId},
      data: {'energyDeliveredKWh': energyDeliveredKWh},
      fromJson: (value) => _forSession(value, sessionId),
    );
  }

  Future<ApiResponse<ChargingSessionModel>> getSessionById(String sessionId) =>
      _apiClient.get(
        '${ApiConstants.sessionById}${Uri.encodeComponent(sessionId)}',
        fromJson: (value) => _forSession(value, sessionId),
      );

  Future<ApiResponse<ChargingSessionModel>> getCurrentSession() =>
      _apiClient.get(
        ApiConstants.sessionCurrent,
        fromJson: (value) => ChargingSessionModel.fromJson(contractMap(value)),
      );

  ChargingSessionModel _forSession(dynamic value, String id) {
    final session = ChargingSessionModel.fromJson(contractMap(value));
    if (session.id.toLowerCase() != id.toLowerCase()) {
      throw const FormatException('Wrong session');
    }
    return session;
  }
}
