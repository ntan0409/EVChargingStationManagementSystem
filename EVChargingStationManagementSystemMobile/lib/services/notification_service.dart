import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    int page = 1,
    int pageSize = 100,
  }) => _apiClient.get(
    ApiConstants.notifications,
    queryParameters: {'page': page, 'pageSize': pageSize},
    fromJson: (data) => contractList(data, NotificationModel.fromJson),
  );
  Future<ApiResponse<int>> getUnreadCount() => _apiClient.get(
    ApiConstants.unreadNotificationCount,
    fromJson: (data) {
      final count = contractMap(data)['count'];
      if (count is! int || count < 0) {
        throw const FormatException('Invalid unread count');
      }
      return count;
    },
  );
  Future<ApiResponse<dynamic>> markAsRead(String id) {
    if (!isApiId(id)) {
      return Future.value(invalidInput('Mã thông báo không hợp lệ.'));
    }
    return _apiClient.patch('${ApiConstants.markNotificationRead}$id/read');
  }

  Future<ApiResponse<dynamic>> markAllAsRead() =>
      _apiClient.patch(ApiConstants.markAllNotificationsRead);
}
