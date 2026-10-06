import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  // Get notifications
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    final response = await _apiClient.get<List<NotificationModel>>(
      ApiConstants.notifications,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    if (!response.success || response.data == null || response.data!.isEmpty) {
      return ApiResponse.success(List.from(_mockNotifications));
    }

    return response;
  }

  // Get unread count
  Future<ApiResponse<int>> getUnreadCount() async {
    final count = _mockNotifications.where((n) => !n.isRead).length;
    return ApiResponse.success(count);
  }

  // Mark single as read
  Future<ApiResponse<dynamic>> markAsRead(String notificationId) async {
    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
    }
    return ApiResponse.success(null);
  }

  // Mark all as read
  Future<ApiResponse<dynamic>> markAllAsRead() async {
    for (int i = 0; i < _mockNotifications.length; i++) {
      _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
    }
    return ApiResponse.success(null);
  }

  static final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'notif-01',
      title: '⚡ Phiên sạc đã hoàn tất!',
      message: 'Xe VinFast VF8 của bạn đã sạc đến 80% tại Trạm Landmark 81. Tổng tiêu thụ: 30.0 kWh.',
      type: 'Charging',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    NotificationModel(
      id: 'notif-02',
      title: '📅 Nhắc nhở lịch đặt sạc',
      message: 'Lịch đặt sạc của bạn tại Trạm Landmark 81 sẽ bắt đầu sau 30 phút. Vui lòng đến đúng giờ.',
      type: 'Booking',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'notif-03',
      title: '🎁 Ưu đãi sạc xe mới',
      message: 'Nhận ngay Voucher giảm 20% tối đa 50.000đ cho các phiên sạc trong tuần này!',
      type: 'Promo',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'notif-04',
      title: '💳 Hóa đơn thanh toán #VNP14829104',
      message: 'Thanh toán thành công 115.500 đ qua cổng VNPay. Cảm ơn bạn đã sử dụng dịch vụ!',
      type: 'Payment',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
