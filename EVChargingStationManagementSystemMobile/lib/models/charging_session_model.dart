class ChargingSessionModel {
  final String id;
  final String chargingPostId;
  final String? connectorId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status; // Charging, Completed, Stopped, Faulted
  final String vehicleType;
  final String? phone;
  final int batteryCapacityKWh;
  final int initialBatteryLevelPercent;
  final int expectedEnergiesKWh;
  final int powerRateKW;
  final double totalEnergyConsumedKWh;
  final double cost;
  final double currentBatteryPercent;
  final int elapsedSeconds;

  ChargingSessionModel({
    required this.id,
    required this.chargingPostId,
    this.connectorId,
    this.startTime,
    this.endTime,
    required this.status,
    this.vehicleType = 'Car',
    this.phone,
    this.batteryCapacityKWh = 80,
    this.initialBatteryLevelPercent = 20,
    this.expectedEnergiesKWh = 80,
    this.powerRateKW = 60,
    this.totalEnergyConsumedKWh = 0.0,
    this.cost = 0.0,
    this.currentBatteryPercent = 20.0,
    this.elapsedSeconds = 0,
  });

  factory ChargingSessionModel.fromJson(Map<String, dynamic> json) {
    return ChargingSessionModel(
      id: json['id']?.toString() ?? '',
      chargingPostId: json['chargingPostId']?.toString() ?? '',
      connectorId: json['connectorId']?.toString(),
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      status: json['status']?.toString() ?? 'Charging',
      vehicleType: json['vehicleType']?.toString() ?? 'Car',
      phone: json['phone']?.toString(),
      batteryCapacityKWh: json['batteryCapacityKWh'] is int
          ? json['batteryCapacityKWh']
          : int.tryParse(json['batteryCapacityKWh']?.toString() ?? '80') ?? 80,
      initialBatteryLevelPercent: json['initialBatteryLevelPercent'] is int
          ? json['initialBatteryLevelPercent']
          : int.tryParse(json['initialBatteryLevelPercent']?.toString() ?? '20') ?? 20,
      expectedEnergiesKWh: json['expectedEnergiesKWh'] is int
          ? json['expectedEnergiesKWh']
          : int.tryParse(json['expectedEnergiesKWh']?.toString() ?? '80') ?? 80,
      powerRateKW: json['powerRateKW'] is int
          ? json['powerRateKW']
          : int.tryParse(json['powerRateKW']?.toString() ?? '60') ?? 60,
      totalEnergyConsumedKWh: (json['totalEnergyConsumedKWh'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      currentBatteryPercent: (json['currentBatteryPercent'] as num?)?.toDouble() ??
          (json['initialBatteryLevelPercent'] as num?)?.toDouble() ??
          20.0,
      elapsedSeconds: json['elapsedSeconds'] is int ? json['elapsedSeconds'] : 0,
    );
  }

  Map<String, dynamic> toStartJson() {
    return {
      'connectorId': connectorId,
      'batteryCapacityKWh': batteryCapacityKWh,
      'initialBatteryLevelPercent': initialBatteryLevelPercent,
      'expectedEnergiesKWh': expectedEnergiesKWh,
      'phone': phone ?? '0912345678',
    };
  }

  ChargingSessionModel copyWith({
    String? id,
    String? chargingPostId,
    String? connectorId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? vehicleType,
    String? phone,
    int? batteryCapacityKWh,
    int? initialBatteryLevelPercent,
    int? expectedEnergiesKWh,
    int? powerRateKW,
    double? totalEnergyConsumedKWh,
    double? cost,
    double? currentBatteryPercent,
    int? elapsedSeconds,
  }) {
    return ChargingSessionModel(
      id: id ?? this.id,
      chargingPostId: chargingPostId ?? this.chargingPostId,
      connectorId: connectorId ?? this.connectorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      vehicleType: vehicleType ?? this.vehicleType,
      phone: phone ?? this.phone,
      batteryCapacityKWh: batteryCapacityKWh ?? this.batteryCapacityKWh,
      initialBatteryLevelPercent: initialBatteryLevelPercent ?? this.initialBatteryLevelPercent,
      expectedEnergiesKWh: expectedEnergiesKWh ?? this.expectedEnergiesKWh,
      powerRateKW: powerRateKW ?? this.powerRateKW,
      totalEnergyConsumedKWh: totalEnergyConsumedKWh ?? this.totalEnergyConsumedKWh,
      cost: cost ?? this.cost,
      currentBatteryPercent: currentBatteryPercent ?? this.currentBatteryPercent,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}
