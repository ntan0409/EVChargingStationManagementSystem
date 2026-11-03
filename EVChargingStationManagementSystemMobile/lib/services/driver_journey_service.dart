import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/driver_journey_model.dart';

class DriverJourneyService {
  final ApiClient _api;
  DriverJourneyService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();
  Future<ApiResponse<DriverJourneyModel>> getState() => _api.get(
    '/EVDriver/eligibility',
    fromJson: (data) => DriverJourneyModel.fromJson(contractMap(data)),
  );
}
