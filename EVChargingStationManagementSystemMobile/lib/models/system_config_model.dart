class SystemConfigModel {
  final double pricePerKWh;
  final double vatRate; // ví dụ 10%
  final int maxBookingMinutes;
  final int autoCancelMinutes;

  SystemConfigModel({
    this.pricePerKWh = 3850.0,
    this.vatRate = 10.0,
    this.maxBookingMinutes = 60,
    this.autoCancelMinutes = 15,
  });

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      pricePerKWh: (json['pricePerKWh'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 3850.0,
      vatRate: (json['vatRate'] as num?)?.toDouble() ?? (json['vat'] as num?)?.toDouble() ?? 10.0,
      maxBookingMinutes: json['maxBookingMinutes'] is int
          ? json['maxBookingMinutes']
          : int.tryParse(json['maxBookingMinutes']?.toString() ?? '60') ?? 60,
      autoCancelMinutes: json['autoCancelMinutes'] is int
          ? json['autoCancelMinutes']
          : int.tryParse(json['autoCancelMinutes']?.toString() ?? '15') ?? 15,
    );
  }
}
