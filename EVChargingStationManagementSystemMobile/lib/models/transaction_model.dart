import '../core/network/api_contract.dart';

// A transaction is a persisted ledger entry, distinct from a pending Payment.
class TransactionModel {
  final String id;
  final String referenceCode;
  final double amount;
  final String transactionType;
  final String status;
  final String? paymentId;
  final String? chargingSessionId;
  final String? paymentMethod;
  final String? paymentReference;
  final int? powerRateKW;
  final double? energyDeliveredKWh;
  final DateTime? initiatedAt;
  final DateTime? completedAt;
  TransactionModel({
    required this.id,
    required this.referenceCode,
    required this.amount,
    required this.transactionType,
    required this.status,
    this.paymentId,
    this.chargingSessionId,
    this.paymentMethod,
    this.paymentReference,
    this.powerRateKW,
    this.energyDeliveredKWh,
    this.initiatedAt,
    this.completedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    if (json['referenceCode'] is! String ||
        json['status'] is! String ||
        json['transactionType'] is! String) {
      throw const FormatException('Invalid transaction');
    }
    return TransactionModel(
      id: contractId(json['id']),
      referenceCode: json['referenceCode'],
      amount: contractNumber(json['amount'], allowNegative: true),
      transactionType: json['transactionType'],
      status: json['status'],
      paymentId: json['paymentId'] == null
          ? null
          : contractId(json['paymentId']),
      chargingSessionId: json['chargingSessionId'] == null
          ? null
          : contractId(json['chargingSessionId']),
      paymentMethod: json['paymentMethod'] as String?,
      paymentReference: json['paymentReference'] as String?,
      powerRateKW: json['powerRateKW'] is int
          ? json['powerRateKW']
          : int.tryParse(json['powerRateKW']?.toString() ?? ''),
      energyDeliveredKWh: json['energyDeliveredKWh'] == null
          ? null
          : contractNumber(json['energyDeliveredKWh']),
      initiatedAt: contractDate(json['initiatedAt']),
      completedAt: contractDate(json['completedAt']),
    );
  }
}
