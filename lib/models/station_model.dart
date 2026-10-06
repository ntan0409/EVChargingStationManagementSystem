import 'charging_post_model.dart';

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
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    double lat = 10.7769; // Default HCM
    double lng = 106.7009;

    if (json['latitude'] != null) {
      lat = double.tryParse(json['latitude'].toString()) ?? 10.7769;
    }
    if (json['longitude'] != null) {
      lng = double.tryParse(json['longitude'].toString()) ?? 106.7009;
    }

    var posts = <ChargingPostModel>[];
    if (json['chargingPosts'] != null && json['chargingPosts'] is List) {
      posts = (json['chargingPosts'] as List)
          .map((item) => ChargingPostModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return StationModel(
      id: json['id']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Trạm sạc xe điện',
      location: json['location']?.toString() ?? '',
      province: json['province']?.toString() ?? 'Hồ Chí Minh',
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
      status: json['status']?.toString() ?? 'Active',
      operatorName: json['operatorName']?.toString(),
      pricePerKWh: (json['pricePerKWh'] as num?)?.toDouble() ?? 3850.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.2,
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

  int get totalAvailableConnectors => availableBikeConnectors + availableCarConnectors;
  int get totalAllConnectors => totalBikeConnectors + totalCarChargingConnectors;
}
