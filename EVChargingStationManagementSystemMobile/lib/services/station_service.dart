import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/station_model.dart';
import '../models/charging_post_model.dart';
import '../models/connector_model.dart';

class StationService {
  final ApiClient _apiClient = ApiClient();

  // Get list of stations
  Future<ApiResponse<List<StationModel>>> getStations() async {
    final response = await _apiClient.get<List<StationModel>>(
      ApiConstants.stations,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => StationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    // Fallback mock stations if empty or server offline
    if (!response.success || response.data == null || response.data!.isEmpty) {
      return ApiResponse.success(_getMockStations());
    }

    return response;
  }

  // Get Station by Id
  Future<ApiResponse<StationModel>> getStationById(String stationId) async {
    final response = await _apiClient.get<StationModel>(
      '${ApiConstants.stationById}$stationId',
      fromJson: (data) => StationModel.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      final mock = _getMockStations().firstWhere(
        (s) => s.id == stationId,
        orElse: () => _getMockStations().first,
      );
      return ApiResponse.success(mock);
    }

    return response;
  }

  // Mock data for initial view / offline demo
  static List<StationModel> _getMockStations() {
    return [
      StationModel(
        id: 'st-001',
        stationName: 'Trạm Sạc EV Hub - Landmark 81',
        location: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM',
        province: 'Hồ Chí Minh',
        latitude: 10.7951,
        longitude: 106.7218,
        totalCarChargingPosts: 4,
        availableCarChargingPosts: 3,
        totalCarChargingConnectors: 8,
        availableCarConnectors: 5,
        totalBikeChargingPosts: 2,
        availableBikeChargingPosts: 2,
        totalBikeConnectors: 4,
        availableBikeConnectors: 4,
        status: 'Active',
        operatorName: 'EV Hub Vietnam',
        pricePerKWh: 3850,
        distanceKm: 0.8,
        chargingPosts: [
          ChargingPostModel(
            id: 'post-01',
            postName: 'Trụ Super Fast DC 120kW #1',
            connectorType: 'CCS2 / CHAdeMO',
            vehicleTypeSupported: 'Car',
            maxPowerKw: 120,
            totalConnectors: 2,
            status: 'Available',
            stationId: 'st-001',
            connectors: [
              ConnectorModel(
                id: 'conn-01',
                connectorName: 'Cổng A - CCS2 (120kW)',
                type: 'CCS2',
                maxPower: '120 kW',
                status: 'Available',
                chargingPostId: 'post-01',
                isAvailable: true,
              ),
              ConnectorModel(
                id: 'conn-02',
                connectorName: 'Cổng B - CCS2 (120kW)',
                type: 'CCS2',
                maxPower: '120 kW',
                status: 'Charging',
                chargingPostId: 'post-01',
                isAvailable: false,
              ),
            ],
          ),
          ChargingPostModel(
            id: 'post-02',
            postName: 'Trụ Fast DC 60kW #2',
            connectorType: 'CCS2',
            vehicleTypeSupported: 'Car',
            maxPowerKw: 60,
            totalConnectors: 2,
            status: 'Available',
            stationId: 'st-001',
            connectors: [
              ConnectorModel(
                id: 'conn-03',
                connectorName: 'Cổng A - CCS2 (60kW)',
                type: 'CCS2',
                maxPower: '60 kW',
                status: 'Available',
                chargingPostId: 'post-02',
                isAvailable: true,
              ),
              ConnectorModel(
                id: 'conn-04',
                connectorName: 'Cổng B - Type 2 (22kW)',
                type: 'Type 2',
                maxPower: '22 kW',
                status: 'Available',
                chargingPostId: 'post-02',
                isAvailable: true,
              ),
            ],
          ),
        ],
      ),
      StationModel(
        id: 'st-002',
        stationName: 'Trạm Sạc EV Sài Gòn Centre',
        location: '65 Lê Lợi, Phường Bến Nghé, Quận 1, TP.HCM',
        province: 'Hồ Chí Minh',
        latitude: 10.7733,
        longitude: 106.7011,
        totalCarChargingPosts: 3,
        availableCarChargingPosts: 2,
        totalCarChargingConnectors: 6,
        availableCarConnectors: 4,
        totalBikeChargingPosts: 2,
        availableBikeChargingPosts: 1,
        totalBikeConnectors: 4,
        availableBikeConnectors: 2,
        status: 'Active',
        operatorName: 'EV Green Energy',
        pricePerKWh: 3900,
        distanceKm: 2.1,
        chargingPosts: [
          ChargingPostModel(
            id: 'post-03',
            postName: 'Trụ Fast DC 60kW #1',
            connectorType: 'CCS2',
            vehicleTypeSupported: 'Car',
            maxPowerKw: 60,
            totalConnectors: 2,
            status: 'Available',
            stationId: 'st-002',
            connectors: [
              ConnectorModel(
                id: 'conn-05',
                connectorName: 'Cổng 1 - CCS2',
                type: 'CCS2',
                maxPower: '60 kW',
                status: 'Available',
                chargingPostId: 'post-03',
                isAvailable: true,
              ),
              ConnectorModel(
                id: 'conn-06',
                connectorName: 'Cổng 2 - CCS2',
                type: 'CCS2',
                maxPower: '60 kW',
                status: 'Reserved',
                chargingPostId: 'post-03',
                isAvailable: false,
              ),
            ],
          ),
        ],
      ),
      StationModel(
        id: 'st-003',
        stationName: 'Trạm Sạc FPT University Hub - Q9',
        location: 'Lô E2a-7, Đường D1, Đ. D1, Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
        province: 'Hồ Chí Minh',
        latitude: 10.8411,
        longitude: 106.8100,
        totalCarChargingPosts: 5,
        availableCarChargingPosts: 4,
        totalCarChargingConnectors: 10,
        availableCarConnectors: 8,
        totalBikeChargingPosts: 4,
        availableBikeChargingPosts: 3,
        totalBikeConnectors: 8,
        availableBikeConnectors: 6,
        status: 'Active',
        operatorName: 'FPT EV Station',
        pricePerKWh: 3500,
        distanceKm: 4.5,
        chargingPosts: [
          ChargingPostModel(
            id: 'post-04',
            postName: 'Trụ Ultra Fast 150kW #1',
            connectorType: 'CCS2',
            vehicleTypeSupported: 'Car',
            maxPowerKw: 150,
            totalConnectors: 2,
            status: 'Available',
            stationId: 'st-003',
            connectors: [
              ConnectorModel(
                id: 'conn-07',
                connectorName: 'Cổng A (150kW)',
                type: 'CCS2',
                maxPower: '150 kW',
                status: 'Available',
                chargingPostId: 'post-04',
                isAvailable: true,
              ),
              ConnectorModel(
                id: 'conn-08',
                connectorName: 'Cổng B (150kW)',
                type: 'CCS2',
                maxPower: '150 kW',
                status: 'Available',
                chargingPostId: 'post-04',
                isAvailable: true,
              ),
            ],
          ),
        ],
      ),
      StationModel(
        id: 'st-004',
        stationName: 'Trạm Sạc EV Sân Bay Tân Sơn Nhất',
        location: 'Trường Sơn, Phường 2, Tân Bình, TP.HCM',
        province: 'Hồ Chí Minh',
        latitude: 10.8166,
        longitude: 106.6631,
        totalCarChargingPosts: 6,
        availableCarChargingPosts: 3,
        totalCarChargingConnectors: 12,
        availableCarConnectors: 6,
        status: 'Active',
        operatorName: 'Airport EV Charge',
        pricePerKWh: 4000,
        distanceKm: 6.2,
      ),
    ];
  }
}
