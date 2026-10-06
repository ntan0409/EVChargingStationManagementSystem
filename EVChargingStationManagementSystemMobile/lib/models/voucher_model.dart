class VoucherModel {
  final String id;
  final String code;
  final String description;
  final double discountPercent; // Ví dụ 10%
  final double maxDiscountAmount; // Tối đa 50.000 đ
  final double minOrderAmount;
  final DateTime validFrom;
  final DateTime validTo;
  final bool isActive;
  final int pointsRequired;

  VoucherModel({
    required this.id,
    required this.code,
    required this.description,
    this.discountPercent = 10,
    this.maxDiscountAmount = 50000,
    this.minOrderAmount = 0,
    required this.validFrom,
    required this.validTo,
    this.isActive = true,
    this.pointsRequired = 100,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? 'EVPROMO',
      description: json['description']?.toString() ?? 'Giảm giá sạc xe điện',
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 10.0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble() ?? 50000.0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'].toString()) ?? DateTime.now()
          : DateTime.now(),
      validTo: json['validTo'] != null
          ? DateTime.tryParse(json['validTo'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] ?? true,
      pointsRequired: json['pointsRequired'] is int
          ? json['pointsRequired']
          : int.tryParse(json['pointsRequired']?.toString() ?? '100') ?? 100,
    );
  }

  bool get isValid => isActive && DateTime.now().isAfter(validFrom) && DateTime.now().isBefore(validTo);

  double calculateDiscount(double originalAmount) {
    if (originalAmount < minOrderAmount) return 0.0;
    double calculated = originalAmount * (discountPercent / 100);
    if (calculated > maxDiscountAmount) {
      return maxDiscountAmount;
    }
    return calculated;
  }
}
