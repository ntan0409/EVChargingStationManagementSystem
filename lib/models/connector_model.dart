class ConnectorModel {
  final String id;
  final String connectorName;
  final String type; // Type 2, CCS2, CHAdeMO, GBT
  final String maxPower; // 22 kW, 60 kW, 120 kW
  final String status; // Available, InUse, Charging, Reserved, Faulted
  final String? chargingPostId;
  final bool isAvailable;

  ConnectorModel({
    required this.id,
    required this.connectorName,
    required this.type,
    required this.maxPower,
    required this.status,
    this.chargingPostId,
    this.isAvailable = true,
  });

  factory ConnectorModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? 'Available';
    final available = rawStatus.toLowerCase() == 'available' || json['isAvailable'] == true;

    return ConnectorModel(
      id: json['id']?.toString() ?? '',
      connectorName: json['connectorName']?.toString() ?? json['name']?.toString() ?? 'Cổng sạc',
      type: json['type']?.toString() ?? json['connectorType']?.toString() ?? 'Type 2',
      maxPower: json['maxPower']?.toString() ?? '${json['maxPowerKw'] ?? 22} kW',
      status: rawStatus,
      chargingPostId: json['chargingPostId']?.toString(),
      isAvailable: available,
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
    };
  }
}
