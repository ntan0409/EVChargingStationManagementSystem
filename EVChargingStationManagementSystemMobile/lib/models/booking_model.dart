import '../core/network/api_contract.dart';

class BookingModel {
  final String id;
  final String? checkInCode;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String status; // Scheduled, InProgress, Completed, Cancelled, Expired
  final double? currentBattery;
  final double? targetBattery;
  final double? estimatedEnergyKWh;
  final double? actualEnergyKWh;
  final String stationId;
  final String? stationName;
  final String? location;
  final String? connectorId;
  final String? connectorName;
  final String? chargingPostId;
  final String? chargingPostName;
  final String? vehicleId;
  final String? vehicleName;
  final String? driverName;
  final String? driverPhone;
  final double estimatedCost;
  final bool hasEstimatedCost;

  BookingModel({
    required this.id,
    this.checkInCode,
    required this.startTime,
    required this.endTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.status,
    this.currentBattery,
    this.targetBattery,
    this.estimatedEnergyKWh,
    this.actualEnergyKWh,
    required this.stationId,
    this.stationName,
    this.location,
    this.connectorId,
    this.connectorName,
    this.chargingPostId,
    this.chargingPostName,
    this.vehicleId,
    this.vehicleName,
    this.driverName,
    this.driverPhone,
    this.estimatedCost = 0,
    this.hasEstimatedCost = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: contractId(json['id']),
      checkInCode: json['checkInCode']?.toString(),
      startTime:
          contractDate(json['startTime']) ??
          (throw const FormatException('Missing booking start')),
      endTime:
          contractDate(json['endTime']) ??
          (throw const FormatException('Missing booking end')),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.tryParse(json['actualStartTime'].toString())
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.tryParse(json['actualEndTime'].toString())
          : null,
      status: json['status'] is String
          ? json['status']
          : (throw const FormatException('Missing booking status')),
      currentBattery: (json['currentBattery'] as num?)?.toDouble(),
      targetBattery: (json['targetBattery'] as num?)?.toDouble(),
      estimatedEnergyKWh: (json['estimatedEnergyKWh'] as num?)?.toDouble(),
      actualEnergyKWh: (json['actualEnergyKWh'] as num?)?.toDouble(),
      stationId: contractId(json['stationId']),
      stationName: json['stationName']?.toString() ?? 'Trạm sạc',
      location: json['location']?.toString() ?? '',
      connectorId: json['connectorId']?.toString(),
      connectorName: json['connectorName']?.toString(),
      chargingPostId: json['chargingPostId']?.toString(),
      chargingPostName: json['chargingPostName']?.toString(),
      vehicleId:
          json['vehicleModelId']?.toString() ?? json['vehicleId']?.toString(),
      vehicleName: json['vehicleName']?.toString(),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      estimatedCost: json['estimatedCost'] == null
          ? 0
          : contractNumber(json['estimatedCost']),
      hasEstimatedCost: json['estimatedCost'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'vehicleId': vehicleId,
      'startTime': startTime.toIso8601String(),
    };
  }

  bool get isScheduled => [
    'scheduled',
    'reserved',
    'checkedin',
    'waiting',
  ].contains(status.toLowerCase());
  bool get isInProgress => status.toLowerCase() == 'inprogress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => [
    'cancelled',
    'autocancelled',
    'cancelledinvalid',
    'noshow',
    'compensatedcancelled',
    'rejected',
  ].contains(status.toLowerCase());
}
