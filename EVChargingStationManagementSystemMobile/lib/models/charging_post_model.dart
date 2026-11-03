import 'connector_model.dart';
import '../core/network/api_contract.dart';

class ChargingPostModel {
  final String id;
  final String postName;
  final String connectorType;
  final String vehicleTypeSupported; // Car, Bike, All
  final int maxPowerKw;
  final int totalConnectors;
  final String status; // Available, InUse, Faulted, Maintenance
  final String stationId;
  final List<ConnectorModel> connectors;

  ChargingPostModel({
    required this.id,
    required this.postName,
    required this.connectorType,
    required this.vehicleTypeSupported,
    required this.maxPowerKw,
    required this.totalConnectors,
    required this.status,
    required this.stationId,
    this.connectors = const [],
  });

  factory ChargingPostModel.fromJson(Map<String, dynamic> json) {
    var rawConnectors = <ConnectorModel>[];
    if (json['connectors'] != null && json['connectors'] is List) {
      rawConnectors = (json['connectors'] as List)
          .map((item) => ConnectorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ChargingPostModel(
      id: contractId(json['id']),
      postName: json['postName']?.toString() ?? 'Trụ sạc',
      connectorType: json['connectorType']?.toString() ?? 'Unknown',
      vehicleTypeSupported:
          json['vehicleTypeSupported']?.toString() ?? 'Unknown',
      maxPowerKw: json['maxPowerKw'] is int
          ? json['maxPowerKw']
          : int.tryParse(json['maxPowerKw']?.toString() ?? '0') ?? 0,
      totalConnectors: json['totalConnectors'] is int
          ? json['totalConnectors']
          : int.tryParse(json['totalConnectors']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Unknown',
      stationId: json['stationId']?.toString() ?? '',
      connectors: rawConnectors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postName': postName,
      'connectorType': connectorType,
      'vehicleTypeSupported': vehicleTypeSupported,
      'maxPowerKw': maxPowerKw,
      'totalConnectors': totalConnectors,
      'status': status,
      'stationId': stationId,
      'connectors': connectors.map((c) => c.toJson()).toList(),
    };
  }
}
