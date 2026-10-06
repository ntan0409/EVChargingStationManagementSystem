import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final ApiClient _apiClient = ApiClient();

  // Get Vehicle Models
  Future<ApiResponse<List<VehicleModel>>> getVehicleModels() async {
    final response = await _apiClient.get<List<VehicleModel>>(
      ApiConstants.vehicleModels,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => VehicleModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    if (!response.success || response.data == null || response.data!.isEmpty) {
      return ApiResponse.success(List.from(_mockVehicles));
    }

    return response;
  }

  // Add Vehicle Model
  Future<ApiResponse<dynamic>> addVehicle(VehicleModel vehicle) async {
    final response = await _apiClient.post(
      ApiConstants.vehicleModels,
      data: vehicle.toJson(),
    );

    _mockVehicles.add(vehicle);
    return response.success
        ? response
        : ApiResponse.success(vehicle, message: 'Thêm xe thành công!');
  }

  // Delete Vehicle
  Future<ApiResponse<dynamic>> deleteVehicle(String vehicleId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.deleteMyVehicle}$vehicleId',
    );

    _mockVehicles.removeWhere((v) => v.id == vehicleId);
    return response.success
        ? response
        : ApiResponse.success(null, message: 'Đã xóa xe thành công');
  }

  static final List<VehicleModel> _mockVehicles = [
    VehicleModel(
      id: 'v-001',
      modelName: 'VinFast VF8 Plus',
      modelYear: 2024,
      vehicleType: 'Car',
      batteryCapacityKWh: 87,
      recommendedChargingPowerKW: 120,
      imageUrl: 'https://vinfastauto.com/sites/default/files/styles/news_detail/public/2022-09/VF8_1.png',
      licensePlate: '51K-987.65',
    ),
    VehicleModel(
      id: 'v-002',
      modelName: 'VinFast VF e34',
      modelYear: 2023,
      vehicleType: 'Car',
      batteryCapacityKWh: 42,
      recommendedChargingPowerKW: 60,
      imageUrl: 'https://vinfastauto.com/sites/default/files/styles/news_detail/public/2022-09/VFe34.png',
      licensePlate: '59A-123.45',
    ),
    VehicleModel(
      id: 'v-003',
      modelName: 'VinFast Feliz S (Xe máy điện)',
      modelYear: 2024,
      vehicleType: 'Bike',
      batteryCapacityKWh: 4,
      recommendedChargingPowerKW: 3,
      imageUrl: '',
      licensePlate: '59-X1 999.99',
    ),
  ];
}
