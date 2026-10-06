import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  // Default Base URL
  // For Android Emulator: http://10.0.2.2:7252/api
  // For Real Device or Windows / Web: http://localhost:7252/api or LAN IP
  static const String defaultBaseUrl = 'https://localhost:7252/api';
  static const String keyCustomBaseUrl = 'custom_base_url';

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentBaseUrl = prefs.getString(keyCustomBaseUrl) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    _currentBaseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCustomBaseUrl, newUrl);
  }

  // Endpoints
  // Auth
  static const String login = '/Auth/login';
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
  static const String sessionStop = '/ChargingSession/Stop';
  static const String sessionById = '/ChargingSession/'; // + id
  static const String sessionByConnector = '/ChargingSession/Connector/'; // + connectorId

  // Payment & Transactions
  static const String paymentCreateUrl = '/Payment';
  static const String paymentOffline = '/Payment/offline';
  static const String paymentById = '/Payment/'; // + id
  static const String paymentList = '/Payment';
  static const String transactions = '/Transaction';
  static const String driverTransactions = '/Transaction/evdriver';

  // EV Driver & Garage
  static const String driverProfile = '/EVDriver/profile';
  static const String updateDriverProfile = '/EVDriver/update';
  static const String deleteMyVehicle = '/EVDriver/vehicle/'; // + vehicleModelId

  // Vehicle Model
  static const String vehicleModels = '/VehicleModel';
  static const String vehicleModelById = '/VehicleModel/'; // + id

  // Voucher
  static const String availableVouchers = '/Voucher';
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
