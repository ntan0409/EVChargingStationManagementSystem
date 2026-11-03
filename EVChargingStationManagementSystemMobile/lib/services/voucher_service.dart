import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/voucher_model.dart';

class VoucherService {
  final ApiClient _apiClient;
  VoucherService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<VoucherModel>>> getAvailableVouchers() async {
    final response = await _apiClient.get<List<VoucherModel>>(
      ApiConstants.availableVouchers,
      fromJson: (value) => contractList(value, VoucherModel.fromJson),
    );
    if (response.statusCode == 404) {
      return ApiResponse.success([], statusCode: 404);
    }
    return response;
  }

  Future<ApiResponse<List<UserVoucherModel>>> getMyVouchers() async {
    final response = await _apiClient.get<List<UserVoucherModel>>(
      ApiConstants.myVouchers,
      fromJson: (value) => contractList(value, UserVoucherModel.fromJson),
    );
    if (response.statusCode == 404) {
      return ApiResponse.success([], statusCode: 404);
    }
    return response;
  }

  Future<ApiResponse<UserVoucherModel>> redeemVoucher(String voucherId) =>
      _apiClient.post(
        '${ApiConstants.redeemVoucher}${Uri.encodeComponent(voucherId)}',
        fromJson: (value) {
          final voucher = UserVoucherModel.fromJson(contractMap(value));
          if (voucher.voucherId != voucherId || voucher.status != 'Redeemed') {
            throw const FormatException('Unconfirmed redemption');
          }
          return voucher;
        },
      );
  Future<ApiResponse<UserVoucherModel>> useVoucher(
    String userVoucherId,
    String sessionId,
  ) => _apiClient.post(
    '${ApiConstants.useVoucher}${Uri.encodeComponent(userVoucherId)}/${Uri.encodeComponent(sessionId)}',
    fromJson: (value) {
      final voucher = UserVoucherModel.fromJson(contractMap(value));
      if (voucher.id != userVoucherId ||
          voucher.sessionId != sessionId ||
          voucher.status != 'Used') {
        throw const FormatException('Unconfirmed voucher application');
      }
      return voucher;
    },
  );

  Future<ApiResponse<int>> getPoints() => _apiClient.get(
    ApiConstants.driverProfile,
    fromJson: (value) {
      final points = contractMap(value)['score'];
      if (points is! int || points < 0) {
        throw const FormatException('Invalid points');
      }
      return points;
    },
  );
}
