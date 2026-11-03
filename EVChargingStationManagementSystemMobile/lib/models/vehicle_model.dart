import '../core/network/api_contract.dart';

class VehicleModel {
  final String id;
  final String modelName;
  final int modelYear;
  final String vehicleType; // Car, Bike
  final int batteryCapacityKWh;
  final int recommendedChargingPowerKW;
  final String imageUrl;
  final String status;
  final String? licensePlate;

  VehicleModel({
    required this.id,
    required this.modelName,
    this.modelYear = 2024,
    this.vehicleType = 'Car',
    this.batteryCapacityKWh = 80,
    this.recommendedChargingPowerKW = 60,
    this.imageUrl = '',
    this.status = 'Active',
    this.licensePlate,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: contractId(json['id']),
      modelName: json['modelName']?.toString() ?? 'Xe điện',
      modelYear: json['modelYear'] is int
          ? json['modelYear']
          : int.tryParse(json['modelYear']?.toString() ?? '') ?? 0,
      vehicleType: json['vehicleType']?.toString() ?? 'Unknown',
      batteryCapacityKWh: json['batteryCapacityKWh'] is int
          ? json['batteryCapacityKWh']
          : int.tryParse(json['batteryCapacityKWh']?.toString() ?? '') ?? 0,
      recommendedChargingPowerKW: json['recommendedChargingPowerKW'] is int
          ? json['recommendedChargingPowerKW']
          : int.tryParse(
                  json['recommendedChargingPowerKW']?.toString() ?? '',
                ) ??
                0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      licensePlate: json['licensePlate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'modelYear': modelYear,
      'vehicleType': vehicleType,
      'batteryCapacityKWh': batteryCapacityKWh,
      'recommendedChargingPowerKW': recommendedChargingPowerKW,
      'imageUrl': imageUrl,
      'licensePlate': licensePlate,
    };
  }
}
