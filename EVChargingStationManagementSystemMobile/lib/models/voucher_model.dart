import '../core/network/api_contract.dart';

class VoucherModel {
  final String id;
  final String name;
  final String description;
  final double value;
  final String voucherType;
  final DateTime validFrom;
  final DateTime validTo;
  final bool isActive;
  final int pointsRequired;
  VoucherModel({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.voucherType,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
    required this.pointsRequired,
  });
  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final from = contractDate(json['validFrom']);
    final to = contractDate(json['validTo']);
    if (from == null ||
        to == null ||
        json['name'] is! String ||
        json['isActive'] is! bool ||
        json['requiredPoints'] is! int ||
        (json['requiredPoints'] as int) < 0) {
      throw const FormatException('Invalid voucher');
    }
    final value = contractNumber(json['value']);
    final type = json['voucherType'];
    if (!['Discount', 'Amount'].contains(type) ||
        (type == 'Discount' && value > 100)) {
      throw const FormatException('Invalid voucher value');
    }
    return VoucherModel(
      id: contractId(json['id']),
      name: json['name'],
      description: json['description']?.toString() ?? '',
      value: value,
      voucherType: type as String,
      validFrom: from,
      validTo: to,
      isActive: json['isActive'],
      pointsRequired: json['requiredPoints'],
    );
  }
  bool get isValid =>
      isActive &&
      !DateTime.now().isBefore(validFrom) &&
      !DateTime.now().isAfter(validTo);
}

class UserVoucherModel {
  final String id;
  final String voucherId;
  final String voucherName;
  final double value;
  final String voucherType;
  final DateTime expiryDate;
  final String status;
  final String? sessionId;
  UserVoucherModel({
    required this.id,
    required this.voucherId,
    required this.voucherName,
    required this.value,
    required this.voucherType,
    required this.expiryDate,
    required this.status,
    this.sessionId,
  });
  factory UserVoucherModel.fromJson(Map<String, dynamic> json) {
    final expiry = contractDate(json['expiryDate']);
    if (expiry == null ||
        json['status'] is! String ||
        json['voucherName'] is! String ||
        !['Discount', 'Amount'].contains(json['voucherType'])) {
      throw const FormatException('Invalid owned voucher');
    }
    return UserVoucherModel(
      id: contractId(json['id']),
      voucherId: contractId(json['voucherId']),
      voucherName: json['voucherName'],
      value: contractNumber(json['voucherValue']),
      voucherType: json['voucherType'],
      expiryDate: expiry,
      status: json['status'],
      sessionId: json['sessionId'] == null
          ? null
          : contractId(json['sessionId']),
    );
  }
  bool get isUsable =>
      status == 'Redeemed' && !DateTime.now().isAfter(expiryDate);
}
