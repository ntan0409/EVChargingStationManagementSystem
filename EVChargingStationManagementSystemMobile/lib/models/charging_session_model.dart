import '../core/network/api_contract.dart';

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
  final bool hasEnergy;
  final bool hasCost;
  final bool hasMeasuredBatteryPercent;
  final bool demoReadingEnabled;

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
    this.hasEnergy = true,
    this.hasCost = true,
    this.hasMeasuredBatteryPercent = false,
    this.demoReadingEnabled = false,
  });

  factory ChargingSessionModel.fromJson(Map<String, dynamic> json) {
    if (![
      'Charging',
      'Completed',
      'Paid',
      'Cancelled',
      'Unknown',
    ].contains(json['status'])) {
      throw const FormatException('Missing or invalid charging status');
    }
    final start = contractDate(json['startTime']);
    final end = contractDate(json['endTime']);
    return ChargingSessionModel(
      id: contractId(json['id']),
      chargingPostId: json['chargingPostId']?.toString() ?? '',
      connectorId: json['connectorId']?.toString(),
      startTime: start,
      endTime: end,
      status: json['status'] as String,
      vehicleType: json['vehicleType']?.toString() ?? 'Car',
      phone: json['phone']?.toString(),
      batteryCapacityKWh: json['batteryCapacityKWh'] is int
          ? json['batteryCapacityKWh']
          : int.tryParse(json['batteryCapacityKWh']?.toString() ?? '') ?? 0,
      initialBatteryLevelPercent: json['initialBatteryLevelPercent'] is int
          ? json['initialBatteryLevelPercent']
          : int.tryParse(
                  json['initialBatteryLevelPercent']?.toString() ?? '',
                ) ??
                0,
      expectedEnergiesKWh: json['expectedEnergiesKWh'] is int
          ? json['expectedEnergiesKWh']
          : int.tryParse(json['expectedEnergiesKWh']?.toString() ?? '') ?? 0,
      powerRateKW: json['powerRateKW'] is int
          ? json['powerRateKW']
          : int.tryParse(json['powerRateKW']?.toString() ?? '') ?? 0,
      totalEnergyConsumedKWh: json['totalEnergyConsumedKWh'] == null
          ? 0
          : contractNumber(json['totalEnergyConsumedKWh']),
      cost: json['cost'] == null ? 0 : contractNumber(json['cost']),
      currentBatteryPercent: json['currentBatteryPercent'] == null
          ? 0
          : contractNumber(json['currentBatteryPercent']),
      elapsedSeconds: start == null
          ? 0
          : (end ?? DateTime.now())
                .difference(start)
                .inSeconds
                .clamp(0, 2147483647),
      hasEnergy: json['totalEnergyConsumedKWh'] != null,
      hasCost: json['cost'] != null,
      hasMeasuredBatteryPercent: json['currentBatteryPercent'] != null,
      demoReadingEnabled: json['demoReadingEnabled'] == true,
    );
  }

  Map<String, dynamic> toStartJson() {
    return {
      'connectorId': connectorId,
      'batteryCapacityKWh': batteryCapacityKWh,
      'initialBatteryLevelPercent': initialBatteryLevelPercent,
      'expectedEnergiesKWh': expectedEnergiesKWh,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
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
      initialBatteryLevelPercent:
          initialBatteryLevelPercent ?? this.initialBatteryLevelPercent,
      expectedEnergiesKWh: expectedEnergiesKWh ?? this.expectedEnergiesKWh,
      powerRateKW: powerRateKW ?? this.powerRateKW,
      totalEnergyConsumedKWh:
          totalEnergyConsumedKWh ?? this.totalEnergyConsumedKWh,
      cost: cost ?? this.cost,
      currentBatteryPercent:
          currentBatteryPercent ?? this.currentBatteryPercent,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hasEnergy: hasEnergy,
      hasCost: hasCost,
      hasMeasuredBatteryPercent: hasMeasuredBatteryPercent,
      demoReadingEnabled: demoReadingEnabled,
    );
  }
}
