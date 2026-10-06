import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Login
  Future<ApiResponse<AuthResponseModel>> login(String email, String password) async {
    final response = await _apiClient.post<AuthResponseModel>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      fromJson: (data) => AuthResponseModel.fromJson(data),
    );

    if (response.success && response.data != null) {
      _apiClient.setAuthToken(response.data!.token);
    }
    return response;
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
      '${ApiConstants.resendConfirmEmail}?email=$email',
    );
  }

  // Forgot Password
  Future<ApiResponse<dynamic>> forgotPassword(String email) async {
    return await _apiClient.post(
      '${ApiConstants.forgotPassword}?email=$email',
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
      data: {
        'userId': userId,
        'token': token,
        'newPassword': newPassword,
      },
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
      fromJson: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  // Update Profile
  Future<ApiResponse<dynamic>> updateProfile(UserModel user) async {
    return await _apiClient.put(
      ApiConstants.updateDriverProfile,
      data: user.toJson(),
    );
  }

  // Logout
  void logout() {
    _apiClient.setAuthToken(null);
  }
}
