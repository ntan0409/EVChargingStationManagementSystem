import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_contract.dart';
import '../core/network/api_response.dart';
import '../models/payment_model.dart';
import '../models/transaction_model.dart';

class PaymentService {
  final ApiClient _apiClient;
  PaymentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<String>> createVNPayUrl(String sessionId) =>
      _apiClient.post(
        ApiConstants.paymentCreateUrl,
        queryParameters: {'sessionId': sessionId},
        fromJson: (value) {
          if (value is! String) throw const FormatException('Missing URL');
          final uri = Uri.tryParse(value);
          if (uri == null ||
              uri.scheme != 'https' ||
              uri.host.isEmpty ||
              uri.userInfo.isNotEmpty ||
              (uri.queryParameters['vnp_SecureHash'] ?? '').isEmpty) {
            throw const FormatException('Invalid gateway URL');
          }
          return value;
        },
      );

  Future<ApiResponse<PaymentModel>> createPaymentOffline(
    String sessionId, {
    bool sePay = false,
    bool sandbox = false,
  }) => _apiClient.post(
    sandbox
        ? '/Payment/sepay-sandbox'
        : sePay
        ? '/Payment/sepay-test'
        : ApiConstants.paymentOffline,
    queryParameters: {'sessionId': sessionId},
    fromJson: (value) {
      final payment = PaymentModel.fromJson(contractMap(value));
      if (payment.sessionId.toLowerCase() != sessionId.toLowerCase()) {
        throw const FormatException('Wrong payment session');
      }
      return payment;
    },
  );

  Future<ApiResponse<String>> sandboxLink(String sessionId) => _apiClient.get(
    '/Payment/sepay-sandbox/link/${Uri.encodeComponent(sessionId)}',
    fromJson: (value) {
      if (value is! String) {
        throw const FormatException('Missing checkout link');
      }
      final relative = Uri.parse(value);
      if (relative.hasScheme ||
          relative.hasAuthority ||
          relative.path != 'Payment/sepay-sandbox/checkout' ||
          (relative.queryParameters['ticket'] ?? '').isEmpty) {
        throw const FormatException('Invalid checkout link');
      }
      return Uri.parse(
        '${ApiConstants.baseUrl}/',
      ).resolveUri(relative).toString();
    },
  );

  Future<ApiResponse<void>> confirmSePayTest(String sessionId) =>
      _apiClient.post(
        '/Payment/sepay-test/confirm',
        queryParameters: {'sessionId': sessionId},
      );

  Future<ApiResponse<SessionPaymentModel>> getSessionPayment(
    String sessionId,
  ) => _apiClient.get(
    '${ApiConstants.paymentForSession}${Uri.encodeComponent(sessionId)}',
    fromJson: (value) {
      final quote = SessionPaymentModel.fromJson(contractMap(value));
      if (quote.sessionId.toLowerCase() != sessionId.toLowerCase()) {
        throw const FormatException('Wrong invoice');
      }
      return quote;
    },
  );

  Future<ApiResponse<List<PaymentMethodModel>>> getMethods() => _apiClient.get(
    ApiConstants.paymentMethods,
    fromJson: (value) => contractList(value, PaymentMethodModel.fromJson),
  );

  Future<ApiResponse<List<TransactionModel>>> getPaymentHistory() async {
    final response = await _apiClient.get<List<TransactionModel>>(
      ApiConstants.driverTransactions,
      fromJson: (value) => contractList(value, TransactionModel.fromJson),
    );
    // This particular list endpoint uses 404 for an empty collection.
    if (response.statusCode == 404) {
      return ApiResponse.success(
        [],
        statusCode: 404,
        message: response.message,
      );
    }
    return response;
  }
}
