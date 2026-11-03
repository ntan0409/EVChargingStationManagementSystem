import '../core/network/api_contract.dart';

class PaymentModel {
  final String id;
  final String sessionId;
  final double amount;
  final double subtotal;
  final double taxRate;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String transactionCode;
  PaymentModel({
    required this.id,
    required this.sessionId,
    required this.amount,
    required this.subtotal,
    required this.taxRate,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentDate,
    required this.transactionCode,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    if (![
          'Initiated',
          'Successed',
          'Failed',
          'Cancelled',
          'Unknown',
        ].contains(status) ||
        json['txnRef'] is! String) {
      throw const FormatException('Invalid payment status/reference');
    }
    return PaymentModel(
      id: contractId(json['id']),
      sessionId: contractId(json['chargingSessionId']),
      amount: contractNumber(json['amount']),
      subtotal: contractNumber(json['beforeVatAmount']),
      taxRate: contractNumber(json['taxRate']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Unknown',
      paymentStatus: status as String,
      paymentDate: contractDate(json['createdAt']),
      transactionCode: json['txnRef'],
    );
  }
  bool get isPaid => paymentStatus == 'Successed';
}

class SessionPaymentModel {
  final String sessionId;
  final String sessionStatus;
  final double beforeVatAmount;
  final double taxRate;
  final double amount;
  final PaymentModel? payment;
  SessionPaymentModel({
    required this.sessionId,
    required this.sessionStatus,
    required this.beforeVatAmount,
    required this.taxRate,
    required this.amount,
    this.payment,
  });
  factory SessionPaymentModel.fromJson(Map<String, dynamic> json) {
    if (json['sessionStatus'] is! String) {
      throw const FormatException('Missing session status');
    }
    final result = SessionPaymentModel(
      sessionId: contractId(json['sessionId']),
      sessionStatus: json['sessionStatus'],
      beforeVatAmount: contractNumber(json['beforeVatAmount']),
      taxRate: contractNumber(json['taxRate']),
      amount: contractNumber(json['amount']),
      payment: json['payment'] == null
          ? null
          : PaymentModel.fromJson(contractMap(json['payment'])),
    );
    if (result.payment != null &&
        result.payment!.sessionId != result.sessionId) {
      throw const FormatException('Wrong invoice session');
    }
    final payment = result.payment;
    if (payment != null &&
        (payment.amount != result.amount ||
            payment.subtotal != result.beforeVatAmount ||
            payment.taxRate != result.taxRate)) {
      throw const FormatException('Inconsistent invoice amounts');
    }
    return result;
  }
  bool get isPaid => sessionStatus == 'Paid' && payment?.isPaid == true;
  bool get hasPendingPayment => payment?.paymentStatus == 'Initiated';
}

class PaymentMethodModel {
  final String id;
  final String name;
  final bool available;
  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.available,
  });
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['name'] is! String ||
        json['available'] is! bool) {
      throw const FormatException('Invalid method');
    }
    return PaymentMethodModel(
      id: json['id'],
      name: json['name'],
      available: json['available'],
    );
  }
}
