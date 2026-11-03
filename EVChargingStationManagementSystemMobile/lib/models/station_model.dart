import 'charging_post_model.dart';
import '../core/network/api_contract.dart';

class StationModel {
  final String id;
  final String stationName;
  final String location;
  final String province;
  final double latitude;
  final double longitude;
  final int totalBikeChargingPosts;
  final int availableBikeChargingPosts;
  final int totalCarChargingPosts;
  final int availableCarChargingPosts;
  final int totalBikeConnectors;
  final int availableBikeConnectors;
  final int totalCarChargingConnectors;
  final int availableCarConnectors;
  final String status; // Active, Inactive, Maintenance
  final String? operatorName;
  final double pricePerKWh;
  final double distanceKm;
  final List<ChargingPostModel> chargingPosts;
  final bool hasPrice;
  final bool hasDistance;

  StationModel({
    required this.id,
    required this.stationName,
    required this.location,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.totalBikeChargingPosts = 0,
    this.availableBikeChargingPosts = 0,
    this.totalCarChargingPosts = 0,
    this.availableCarChargingPosts = 0,
    this.totalBikeConnectors = 0,
    this.availableBikeConnectors = 0,
    this.totalCarChargingConnectors = 0,
    this.availableCarConnectors = 0,
    this.status = 'Active',
    this.operatorName,
    this.pricePerKWh = 3850,
    this.distanceKm = 0.0,
    this.chargingPosts = const [],
    this.hasPrice = true,
    this.hasDistance = true,
  });

  static double _coordinate(Object? value) {
    final text = value.toString().trim().toUpperCase();
    final suffix = RegExp(r'[NSEW]$').firstMatch(text);
    if (suffix == null) return double.parse(text);
    final magnitude = double.parse(text.substring(0, suffix.start)).abs();
    return suffix.group(0) == 'S' || suffix.group(0) == 'W'
        ? -magnitude
        : magnitude;
  }

  factory StationModel.fromJson(Map<String, dynamic> json) {
    double lat = 0;
    double lng = 0;

    if (json['latitude'] != null) {
      lat = _coordinate(json['latitude']);
    }
    if (json['longitude'] != null) {
      lng = _coordinate(json['longitude']);
    }

    var posts = <ChargingPostModel>[];
    if (json['chargingPosts'] != null && json['chargingPosts'] is List) {
      posts = (json['chargingPosts'] as List)
          .map(
            (item) => ChargingPostModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return StationModel(
      id: contractId(json['id']),
      stationName: json['stationName']?.toString() ?? 'Trạm sạc xe điện',
      location: json['location']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      totalBikeChargingPosts: json['totalBikeChargingPosts'] ?? 0,
      availableBikeChargingPosts: json['availableBikeChargingPosts'] ?? 0,
      totalCarChargingPosts: json['totalCarChargingPosts'] ?? 0,
      availableCarChargingPosts: json['availableCarChargingPosts'] ?? 0,
      totalBikeConnectors: json['totalBikeConnectors'] ?? 0,
      availableBikeConnectors: json['availableBikeConnectors'] ?? 0,
      totalCarChargingConnectors: json['totalCarChargingConnectors'] ?? 0,
      availableCarConnectors: json['availableCarConnectors'] ?? 0,
      status: json['status']?.toString() ?? 'Unknown',
      operatorName: json['operatorName']?.toString(),
      pricePerKWh: json['pricePerKWh'] == null
          ? 0
          : contractNumber(json['pricePerKWh']),
      distanceKm: json['distanceKm'] == null
          ? 0
          : contractNumber(json['distanceKm']),
      hasPrice: json['pricePerKWh'] != null,
      hasDistance: json['distanceKm'] != null,
      chargingPosts: posts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationName': stationName,
      'location': location,
      'province': province,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'totalBikeChargingPosts': totalBikeChargingPosts,
      'availableBikeChargingPosts': availableBikeChargingPosts,
      'totalCarChargingPosts': totalCarChargingPosts,
      'availableCarChargingPosts': availableCarChargingPosts,
      'totalBikeConnectors': totalBikeConnectors,
      'availableBikeConnectors': availableBikeConnectors,
      'totalCarChargingConnectors': totalCarChargingConnectors,
      'availableCarConnectors': availableCarConnectors,
      'status': status,
      'operatorName': operatorName,
      'pricePerKWh': pricePerKWh,
      'chargingPosts': chargingPosts.map((p) => p.toJson()).toList(),
    };
  }

  int get totalAvailableConnectors =>
      availableBikeConnectors + availableCarConnectors;
  int get totalAllConnectors =>
      totalBikeConnectors + totalCarChargingConnectors;
}
