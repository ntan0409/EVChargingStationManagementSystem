import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/voucher_model.dart';

class VoucherService {
  final ApiClient _apiClient = ApiClient();

  // Get available vouchers
  Future<ApiResponse<List<VoucherModel>>> getAvailableVouchers() async {
    final response = await _apiClient.get<List<VoucherModel>>(
      ApiConstants.availableVouchers,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => VoucherModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    if (!response.success || response.data == null || response.data!.isEmpty) {
      return ApiResponse.success(_mockVouchers);
    }

    return response;
  }

  // Redeem voucher
  Future<ApiResponse<dynamic>> redeemVoucher(String voucherId) async {
    return await _apiClient.post(
      '${ApiConstants.redeemVoucher}$voucherId',
    );
  }

  // Use voucher on session
  Future<ApiResponse<dynamic>> useVoucher(String userVoucherId, String sessionId) async {
    return await _apiClient.post(
      '${ApiConstants.useVoucher}$userVoucherId/$sessionId',
    );
  }

  static final List<VoucherModel> _mockVouchers = [
    VoucherModel(
      id: 'vc-001',
      code: 'EVGREEN20',
      description: 'Giảm 20% tối đa 50.000đ cho phiên sạc đầu tiên trong tháng',
      discountPercent: 20,
      maxDiscountAmount: 50000,
      minOrderAmount: 50000,
      validFrom: DateTime.now().subtract(const Duration(days: 5)),
      validTo: DateTime.now().add(const Duration(days: 25)),
      pointsRequired: 50,
    ),
    VoucherModel(
      id: 'vc-002',
      code: 'FASTCHARGE15',
      description: 'Giảm 15% tối đa 30.000đ cho các trụ sạc nhanh DC Super Fast',
      discountPercent: 15,
      maxDiscountAmount: 30000,
      minOrderAmount: 40000,
      validFrom: DateTime.now().subtract(const Duration(days: 2)),
      validTo: DateTime.now().add(const Duration(days: 15)),
      pointsRequired: 40,
    ),
    VoucherModel(
      id: 'vc-003',
      code: 'WEEKEND10',
      description: 'Giảm 10% tối đa 20.000đ vào thứ Bảy và Chủ Nhật',
      discountPercent: 10,
      maxDiscountAmount: 20000,
      minOrderAmount: 30000,
      validFrom: DateTime.now(),
      validTo: DateTime.now().add(const Duration(days: 30)),
      pointsRequired: 30,
    ),
  ];
}
