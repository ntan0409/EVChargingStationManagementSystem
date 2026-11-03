import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final ApiClient _apiClient;
  VehicleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  Future<ApiResponse<List<VehicleModel>>> getVehicleModels() async {
    final response = await _apiClient.get<List<VehicleModel>>(
      ApiConstants.vehicleModels,
      fromJson: (value) => contractList(value, VehicleModel.fromJson),
    );
    if (response.statusCode == 404) {
      return ApiResponse.success([], statusCode: 404);
    }
    return response;
  }

  Future<ApiResponse<List<VehicleModel>>> getMyVehicleModels() async {
    final profile = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.driverProfile,
      fromJson: contractMap,
    );
    if (!profile.success || profile.data == null) return forwardError(profile);
    final ids = profile.data!['vehicleModelIds'];
    if (ids is! List || ids.any((id) => id is! String || !isApiId(id))) {
      return invalidInput('Danh sách xe trong hồ sơ chưa hợp lệ.');
    }
    if (ids.isEmpty) return ApiResponse.success([]);
    final catalog = await getVehicleModels();
    if (!catalog.success || catalog.data == null) return catalog;
    return ApiResponse.success(
      catalog.data!.where((vehicle) => ids.contains(vehicle.id)).toList(),
    );
  }

  Future<ApiResponse<dynamic>> addVehicle(VehicleModel vehicle) async {
    if (!isApiId(vehicle.id)) {
      return invalidInput('Chọn mẫu xe do máy chủ cung cấp để thêm vào hồ sơ.');
    }
    final profile = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.driverProfile,
      fromJson: contractMap,
    );
    if (!profile.success || profile.data == null) return forwardError(profile);
    final json = profile.data!;
    if (json['vehicleModelIds'] is! List ||
        !isApiId(json['id']?.toString() ?? '')) {
      return invalidInput('Hồ sơ thiếu thông tin xe.');
    }
    return _apiClient.put(
      ApiConstants.updateDriverProfile,
      data: {
        'driverId': json['id'],
        'name': json['name'],
        'phoneNumber': json['phoneNumber'],
        'address': json['address'],
        'profilePictureUrl': json['profilePictureUrl'],
        'vehicleModelIds': {
          ...(json['vehicleModelIds'] as List),
          vehicle.id,
        }.toList(),
      },
    );
  }

  Future<ApiResponse<dynamic>> deleteVehicle(String vehicleId) =>
      _apiClient.delete(
        '${ApiConstants.deleteMyVehicle}${Uri.encodeComponent(vehicleId)}',
      );
}
