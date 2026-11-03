import '../core/network/api_contract.dart';

class ConnectorModel {
  final String id;
  final String connectorName;
  final String type; // Type 2, CCS2, CHAdeMO, GBT
  final String maxPower; // 22 kW, 60 kW, 120 kW
  final String status; // Available, InUse, Charging, Reserved, Faulted
  final String? chargingPostId;
  final bool isAvailable;
  final bool isPluggedIn;
  final bool isLocked;
  bool get canStart => status == 'InUse' && isPluggedIn && !isLocked;

  ConnectorModel({
    required this.id,
    required this.connectorName,
    required this.type,
    required this.maxPower,
    required this.status,
    this.chargingPostId,
    this.isAvailable = true,
    this.isPluggedIn = false,
    this.isLocked = false,
  });

  factory ConnectorModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? 'Unknown';
    final available = rawStatus == 'Available' && json['isLocked'] != true;

    return ConnectorModel(
      id: contractId(json['id']),
      connectorName:
          json['connectorName']?.toString() ??
          json['name']?.toString() ??
          'Cổng sạc',
      type:
          json['type']?.toString() ??
          json['connectorType']?.toString() ??
          'Unknown',
      maxPower:
          json['maxPower']?.toString() ??
          (json['maxPowerKw'] == null ? '—' : '${json['maxPowerKw']} kW'),
      status: rawStatus,
      chargingPostId: json['chargingPostId']?.toString(),
      isAvailable: available,
      isPluggedIn: json['isPluggedIn'] == true,
      isLocked: json['isLocked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectorName': connectorName,
      'type': type,
      'maxPower': maxPower,
      'status': status,
      'chargingPostId': chargingPostId,
      'isAvailable': isAvailable,
      'isPluggedIn': isPluggedIn,
      'isLocked': isLocked,
    };
  }
}
