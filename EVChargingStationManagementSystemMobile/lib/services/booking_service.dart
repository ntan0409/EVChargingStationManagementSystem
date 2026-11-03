import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/booking_model.dart';

class BookingService {
  final ApiClient _apiClient;
  BookingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  Future<ApiResponse<BookingModel>> createBooking({
    required String stationId,
    required String vehicleId,
    required DateTime startTime,
  }) {
    if (!isApiId(stationId) || !isApiId(vehicleId)) {
      return Future.value(invalidInput('Chọn trạm và xe từ máy chủ.'));
    }
    return _apiClient.post(
      ApiConstants.bookings,
      data: {
        'stationId': stationId,
        'vehicleId': vehicleId,
        'startTime': startTime.toIso8601String(),
      },
      fromJson: (data) => BookingModel.fromJson(contractMap(data)),
    );
  }

  Future<ApiResponse<List<BookingModel>>> getMyBookings() async {
    final response = await _apiClient.get<List<BookingModel>>(
      ApiConstants.myBookings,
      fromJson: (data) => contractList(data, BookingModel.fromJson),
    );
    if (response.statusCode == 404) {
      return ApiResponse.success([], statusCode: 404);
    }
    return response;
  }

  Future<ApiResponse<dynamic>> checkInBooking(String code) => _apiClient.patch(
    ApiConstants.bookingCheckin,
    data: {'checkInCode': code},
  );
  Future<ApiResponse<dynamic>> cancelBooking(String bookingId) {
    if (!isApiId(bookingId)) {
      return Future.value(invalidInput('Mã lịch đặt không hợp lệ.'));
    }
    return _apiClient.patch(
      ApiConstants.bookingCancel.replaceAll('{id}', bookingId),
    );
  }
}
