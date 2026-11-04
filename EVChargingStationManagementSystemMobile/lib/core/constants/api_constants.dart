import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String _environmentUrl = String.fromEnvironment('API_BASE_URL');
  static const String keyCustomBaseUrl = kReleaseMode
      ? 'production_api_base_url'
      : 'custom_base_url';

  static String developmentBaseUrl(
    TargetPlatform platform, {
    bool isWeb = false,
  }) => !isWeb && platform == TargetPlatform.android
      ? 'http://10.0.2.2:5058/api'
      : 'http://localhost:5058/api';

  // Release never defaults to localhost or a saved development URL.
  static String get defaultBaseUrl => _environmentUrl.isNotEmpty
      ? _environmentUrl
      : kReleaseMode
      ? ''
      : developmentBaseUrl(defaultTargetPlatform, isWeb: kIsWeb);

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyCustomBaseUrl);
    try {
      _currentBaseUrl = normalizeBaseUrl(_environmentUrl.isNotEmpty ? _environmentUrl : saved ?? defaultBaseUrl);
    } on FormatException {
      _currentBaseUrl = '';
      if (saved != null) {
        await prefs.remove(keyCustomBaseUrl);
        if (defaultBaseUrl.isNotEmpty) {
          try {
            _currentBaseUrl = normalizeBaseUrl(defaultBaseUrl);
          } on FormatException {
            _currentBaseUrl = '';
          }
        }
      }
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final normalized = normalizeBaseUrl(newUrl);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(keyCustomBaseUrl, normalized)) {
      throw StateError('Không lưu được cấu hình API.');
    }
    _currentBaseUrl = normalized;
  }

  static String normalizeBaseUrl(
    String value, {
    bool requireHttps = kReleaseMode,
  }) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        RegExp(r'\s').hasMatch(value.trim())) {
      throw const FormatException(
        'Nhập URL HTTP/HTTPS hợp lệ, không kèm tài khoản, query hoặc fragment.',
      );
    }
    if (requireHttps && uri.scheme != 'https') {
      throw const FormatException('Bản release yêu cầu API HTTPS.');
    }
    if (uri.port < 1 || uri.port > 65535) {
      throw const FormatException('Cổng API không hợp lệ.');
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    while (segments.isNotEmpty && segments.last.toLowerCase() == 'api') {
      segments.removeLast();
    }
    return uri.replace(pathSegments: [...segments, 'api']).toString();
  }

  static String resolveEndpoint(String endpoint, {String? baseUrl}) {
    final value = baseUrl ?? _currentBaseUrl;
    if (value.isEmpty) {
      throw const FormatException(
        'Chưa cấu hình API. Nhập địa chỉ HTTPS trong cài đặt máy chủ.',
      );
    }
    final base = Uri.parse(normalizeBaseUrl(value));
    final path = Uri.parse(endpoint);
    if (path.hasScheme || path.hasAuthority || path.hasFragment) {
      throw const FormatException(
        'Endpoint phải là đường dẫn tương đối của API.',
      );
    }
    final segments = path.pathSegments.where((s) => s.isNotEmpty).toList();
    while (segments.isNotEmpty && segments.first.toLowerCase() == 'api') {
      segments.removeAt(0);
    }
    return base
        .replace(
          pathSegments: [...base.pathSegments, ...segments],
          query: path.hasQuery ? path.query : null,
        )
        .toString();
  }

  // Endpoints
  // Auth
  static const String login = '/Auth/login';
  static const String loginGoogle = '/Auth/login-google';
  static const String register = '/Auth/register';
  static const String confirmEmail = '/Auth/confirm-email';
  static const String resendConfirmEmail = '/Auth/resend-confirm-email';
  static const String forgotPassword = '/Auth/forgot-password';
  static const String resetPassword = '/Auth/reset-password';
  static const String changePassword = '/Auth/change-password';

  // Charging Station
  static const String stations = '/ChargingStation';
  static const String stationById = '/ChargingStation/'; // + id

  // Charging Post
  static const String chargingPosts = '/ChargingPost';
  static const String chargingPostById = '/ChargingPost/'; // + id

  // Connector
  static const String connectors = '/Connector';
  static const String connectorById = '/Connector/'; // + id
  static const String connectorToggle = '/Connector/connector-toggle';

  // Booking
  static const String bookings = '/Booking';
  static const String myBookings = '/Booking/my-bookings';
  static const String bookingCheckin = '/Booking/checkin';
  static const String bookingComplete = '/Booking/{id}/complete';
  static const String bookingCancel = '/Booking/{id}/cancel';

  // Charging Session
  static const String sessionStart = '/ChargingSession/Start';
  static const String sessionCurrent = '/ChargingSession/current';
  static const String sessionStop = '/ChargingSession/Stop';
  static const String sessionById = '/ChargingSession/'; // + id
  static const String sessionByConnector =
      '/ChargingSession/Connector/'; // + connectorId

  // Payment & Transactions
  static const String paymentCreateUrl = '/Payment';
  static const String paymentForSession = '/Payment/session/';
  static const String paymentMethods = '/Payment/methods';
  static const String paymentOffline = '/Payment/offline';
  static const String paymentById = '/Payment/'; // + id
  static const String paymentList = '/Payment';
  static const String transactions = '/Transaction';
  static const String driverTransactions = '/Transaction/evdriver';

  // EV Driver & Garage
  static const String driverProfile = '/EVDriver/profile';
  static const String updateDriverProfile = '/EVDriver/update';
  static const String deleteMyVehicle =
      '/EVDriver/vehicle/'; // + vehicleModelId

  // Vehicle Model
  static const String vehicleModels = '/VehicleModel';
  static const String vehicleModelById = '/VehicleModel/'; // + id

  // Voucher
  static const String availableVouchers = '/Voucher';
  static const String myVouchers = '/Voucher/my';
  static const String redeemVoucher = '/Voucher/redeem/'; // + voucherId
  static const String useVoucher = '/Voucher/use/'; // + userVoucherId/sessionId

  // Feedback & Report
  static const String feedback = '/Feedback';
  static const String createDriverReport = '/Report/evdriver/report';
  static const String reports = '/Report/getall';
  static const String reportById = '/Report/'; // + id

  // Notifications
  static const String notifications = '/Notification';
  static const String unreadNotificationCount = '/Notification/unread-count';
  static const String markNotificationRead = '/Notification/'; // + id + /read
  static const String markAllNotificationsRead = '/Notification/mark-all-read';

  // System Configuration
  static const String systemConfig = '/SystemConfiguration';
}
