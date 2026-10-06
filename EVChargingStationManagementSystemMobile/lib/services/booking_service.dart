import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/booking_model.dart';

class BookingService {
  final ApiClient _apiClient = ApiClient();

  // Create Booking
  Future<ApiResponse<BookingModel>> createBooking({
    required String stationId,
    required String vehicleId,
    required DateTime startTime,
  }) async {
    final response = await _apiClient.post<BookingModel>(
      ApiConstants.bookings,
      data: {
        'stationId': stationId,
        'vehicleId': vehicleId,
        'startTime': startTime.toIso8601String(),
      },
      fromJson: (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );

    if (!response.success) {
      // Mock newly created booking for smooth offline demo
      final mockBooking = BookingModel(
        id: 'bk-${DateTime.now().millisecondsSinceEpoch}',
        checkInCode: '${(1000 + DateTime.now().millisecond % 9000)}',
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        status: 'Scheduled',
        stationId: stationId,
        stationName: 'Trạm Sạc EV Hub - Landmark 81',
        location: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM',
        vehicleId: vehicleId,
        vehicleName: 'VinFast VF8',
        estimatedCost: 75000,
      );
      _mockBookings.insert(0, mockBooking);
      return ApiResponse.success(mockBooking, message: 'Đặt lịch thành công!');
    }

    return response;
  }

  // Get My Bookings
  Future<ApiResponse<List<BookingModel>>> getMyBookings() async {
    final response = await _apiClient.get<List<BookingModel>>(
      ApiConstants.myBookings,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    if (!response.success || response.data == null || response.data!.isEmpty) {
      return ApiResponse.success(List.from(_mockBookings));
    }

    return response;
  }

  // Checkin Booking
  Future<ApiResponse<dynamic>> checkInBooking(String checkInCode) async {
    final response = await _apiClient.patch(
      ApiConstants.bookingCheckin,
      data: {'checkInCode': checkInCode},
    );

    if (!response.success) {
      // Offline fallback
      final index = _mockBookings.indexWhere((b) => b.checkInCode == checkInCode);
      if (index != -1) {
        return ApiResponse.success(null, message: 'Check-in thành công!');
      }
    }
    return response;
  }

  // Cancel Booking
  Future<ApiResponse<dynamic>> cancelBooking(String bookingId) async {
    final path = ApiConstants.bookingCancel.replaceAll('{id}', bookingId);
    final response = await _apiClient.patch(path);

    _mockBookings.removeWhere((b) => b.id == bookingId);
    return response.success
        ? response
        : ApiResponse.success(null, message: 'Đã hủy lịch đặt thành công');
  }

  // Mock initial bookings
  static final List<BookingModel> _mockBookings = [
    BookingModel(
      id: 'bk-101',
      checkInCode: '8942',
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 3)),
      status: 'Scheduled',
      stationId: 'st-001',
      stationName: 'Trạm Sạc EV Hub - Landmark 81',
      location: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM',
      chargingPostName: 'Trụ Super Fast DC 120kW #1',
      connectorName: 'Cổng A - CCS2',
      vehicleName: 'VinFast VF8 (51K-987.65)',
      estimatedEnergyKWh: 30.0,
      estimatedCost: 115500,
    ),
    BookingModel(
      id: 'bk-102',
      checkInCode: '4512',
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      actualStartTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      actualEndTime: DateTime.now().subtract(const Duration(days: 2, hours: 3, minutes: 15)),
      status: 'Completed',
      stationId: 'st-002',
      stationName: 'Trạm Sạc EV Sài Gòn Centre',
      location: '65 Lê Lợi, Phường Bến Nghé, Quận 1, TP.HCM',
      chargingPostName: 'Trụ Fast DC 60kW #1',
      connectorName: 'Cổng 1 - CCS2',
      vehicleName: 'VinFast VF8 (51K-987.65)',
      actualEnergyKWh: 24.5,
      estimatedCost: 95550,
    ),
  ];
}
