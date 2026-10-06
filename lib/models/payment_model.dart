class PaymentModel {
  final String id;
  final String sessionId;
  final double amount;
  final double subtotal;
  final double vat;
  final double discount;
  final String paymentMethod; // VNPay, Offline, Wallet
  final String paymentStatus; // Paid, Pending, Failed
  final DateTime paymentDate;
  final String? transactionCode;
  final String? stationName;
  final double energyDeliveredKWh;

  PaymentModel({
    required this.id,
    required this.sessionId,
    required this.amount,
    this.subtotal = 0,
    this.vat = 0,
    this.discount = 0,
    this.paymentMethod = 'VNPay',
    this.paymentStatus = 'Paid',
    required this.paymentDate,
    this.transactionCode,
    this.stationName,
    this.energyDeliveredKWh = 0,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? json['method']?.toString() ?? 'VNPay',
      paymentStatus: json['paymentStatus']?.toString() ?? json['status']?.toString() ?? 'Paid',
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      transactionCode: json['transactionCode']?.toString() ?? json['code']?.toString() ?? 'VNP${DateTime.now().millisecondsSinceEpoch}',
      stationName: json['stationName']?.toString() ?? 'Trạm sạc EV',
      energyDeliveredKWh: (json['energyDeliveredKWh'] as num?)?.toDouble() ?? (json['energyDelivered'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isPaid => paymentStatus.toLowerCase() == 'paid' || paymentStatus.toLowerCase() == 'success';
}
