import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  ApiClient get apiClient => _apiClient;

  void setSessionToken(String? token) => _apiClient.setAuthToken(token);
  void addUnauthorizedListener(void Function(String) listener) =>
      _apiClient.addUnauthorizedListener(listener);
  void removeUnauthorizedListener(void Function(String) listener) =>
      _apiClient.removeUnauthorizedListener(listener);

  // Login
  Future<ApiResponse<AuthResponseModel>> login(
    String email,
    String password,
  ) async {
    return await _apiClient.post<AuthResponseModel>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      fromJson: (data) => AuthResponseModel.fromJson(data),
      authenticated: false,
    );
  }

  // Exchange a Google ID token for the backend session JWT.
  Future<ApiResponse<AuthResponseModel>> loginGoogle(String idToken) async {
    if (idToken.trim().isEmpty) {
      return ApiResponse.error(
        'Google không trả ID Token.',
        errorType: ApiErrorType.parse,
      );
    }
    return _apiClient.post<AuthResponseModel>(
      ApiConstants.loginGoogle,
      data: {'idToken': idToken},
      fromJson: AuthResponseModel.fromJson,
      authenticated: false,
    );
  }

  // Register
  Future<ApiResponse<dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return await _apiClient.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      },
      authenticated: false,
      fromJson: (data) {
        if (data is! Map<String, dynamic> || data['message'] is! String) {
          throw const FormatException('Phản hồi đăng ký không hợp lệ.');
        }
        return data;
      },
    );
  }

  // Confirm Email
  Future<ApiResponse<dynamic>> confirmEmail({
    required String userId,
    required String token,
  }) async {
    return await _apiClient.patch(
      ApiConstants.confirmEmail,
      data: {'userId': userId, 'token': token},
    );
  }

  // Resend Confirm Email
  Future<ApiResponse<dynamic>> resendConfirmEmail(String email) async {
    return await _apiClient.post(
      ApiConstants.resendConfirmEmail,
      queryParameters: {'Email': email},
      authenticated: false,
    );
  }

  // Forgot Password
  Future<ApiResponse<dynamic>> forgotPassword(String email) async {
    return await _apiClient.post(
      ApiConstants.forgotPassword,
      queryParameters: {'Email': email},
      authenticated: false,
    );
  }

  // Reset Password
  Future<ApiResponse<dynamic>> resetPassword({
    required String userId,
    required String token,
    required String newPassword,
  }) async {
    return await _apiClient.post(
      ApiConstants.resetPassword,
      data: {'userId': userId, 'token': token, 'newPassword': newPassword},
    );
  }

  // Change Password
  Future<ApiResponse<dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _apiClient.post(
      ApiConstants.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  // Get Profile
  Future<ApiResponse<UserModel>> getProfile() async {
    return await _apiClient.get<UserModel>(
      ApiConstants.driverProfile,
      fromJson: UserModel.fromDriverProfile,
    );
  }

  // Update Profile
  Future<ApiResponse<UserModel>> updateProfile(
    UserModel user, {
    required String name,
    required String phone,
    String? address,
  }) async {
    return await _apiClient.put<UserModel>(
      ApiConstants.updateDriverProfile,
      data: {
        'driverId': user.id,
        'name': name,
        'phoneNumber': phone,
        'address': address ?? user.address,
        'profilePictureUrl': user.avatar,
      },
      fromJson: UserModel.fromDriverProfile,
    );
  }

  // Logout
  void logout() {
    _apiClient.setAuthToken(null);
  }
}
