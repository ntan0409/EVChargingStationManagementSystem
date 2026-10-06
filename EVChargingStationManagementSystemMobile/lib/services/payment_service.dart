import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/payment_model.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  // Create VNPay Payment URL
  Future<ApiResponse<String>> createVNPayUrl(String sessionId) async {
    final response = await _apiClient.post<dynamic>(
      '${ApiConstants.paymentCreateUrl}?sessionId=$sessionId',
    );

    if (response.success && response.data != null) {
      if (response.data is String) {
        return ApiResponse.success(response.data as String);
      } else if (response.data is Map && response.data['data'] != null) {
        return ApiResponse.success(response.data['data'].toString());
      }
    }

    // Fallback sandbox mock VNPay URL
    return ApiResponse.success(
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=10000000&vnp_Command=pay&vnp_CreateDate=20260922000000&vnp_CurrCode=VND&vnp_IpAddr=127.0.0.1&vnp_Locale=vn&vnp_OrderInfo=Thanh+toan+phien+sac+EV&vnp_OrderType=other&vnp_ReturnUrl=https%3A%2F%2Flocalhost%3A7252%2Fapi%2FPayment%2Fvnpay%2Fipn&vnp_TmnCode=DEMO&vnp_TxnRef=$sessionId',
    );
  }

  // Create Payment Offline Record
  Future<ApiResponse<dynamic>> createPaymentOffline(String sessionId) async {
    return await _apiClient.post(
      '${ApiConstants.paymentOffline}?sessionId=$sessionId',
    );
  }

  // Get Payment History / Driver Transactions
  Future<ApiResponse<List<PaymentModel>>> getPaymentHistory() async {
    final response = await _apiClient.get<List<PaymentModel>>(
      ApiConstants.driverTransactions,
      fromJson: (data) {
        if (data is List) {
          return data
              .map((item) => PaymentModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );

    if (!response.success || response.data == null || response.data!.isEmpty) {
      return ApiResponse.success(_mockPayments);
    }

    return response;
  }

  static final List<PaymentModel> _mockPayments = [
    PaymentModel(
      id: 'pay-001',
      sessionId: 'sess-001',
      amount: 115500,
      subtotal: 105000,
      vat: 10500,
      discount: 0,
      paymentMethod: 'VNPay',
      paymentStatus: 'Paid',
      paymentDate: DateTime.now().subtract(const Duration(days: 1)),
      transactionCode: 'VNP14829104',
      stationName: 'Trạm Sạc EV Hub - Landmark 81',
      energyDeliveredKWh: 30.0,
    ),
    PaymentModel(
      id: 'pay-002',
      sessionId: 'sess-002',
      amount: 85000,
      subtotal: 95450,
      vat: 9550,
      discount: 20000,
      paymentMethod: 'Tiền mặt (Offline)',
      paymentStatus: 'Paid',
      paymentDate: DateTime.now().subtract(const Duration(days: 3)),
      transactionCode: 'OFF92817234',
      stationName: 'Trạm Sạc EV Sài Gòn Centre',
      energyDeliveredKWh: 24.5,
    ),
  ];
}
