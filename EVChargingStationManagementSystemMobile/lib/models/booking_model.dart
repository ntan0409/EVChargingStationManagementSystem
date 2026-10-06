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
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      checkInCode: json['checkInCode']?.toString(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.tryParse(json['actualStartTime'].toString())
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.tryParse(json['actualEndTime'].toString())
          : null,
      status: json['status']?.toString() ?? 'Scheduled',
      currentBattery: (json['currentBattery'] as num?)?.toDouble(),
      targetBattery: (json['targetBattery'] as num?)?.toDouble(),
      estimatedEnergyKWh: (json['estimatedEnergyKWh'] as num?)?.toDouble(),
      actualEnergyKWh: (json['actualEnergyKWh'] as num?)?.toDouble(),
      stationId: json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Trạm sạc',
      location: json['location']?.toString() ?? '',
      connectorId: json['connectorId']?.toString(),
      connectorName: json['connectorName']?.toString(),
      chargingPostId: json['chargingPostId']?.toString(),
      chargingPostName: json['chargingPostName']?.toString(),
      vehicleId: json['vehicleId']?.toString(),
      vehicleName: json['vehicleName']?.toString() ?? 'VinFast VF8',
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 75000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'vehicleId': vehicleId,
      'startTime': startTime.toIso8601String(),
    };
  }

  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isInProgress => status.toLowerCase() == 'inprogress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
