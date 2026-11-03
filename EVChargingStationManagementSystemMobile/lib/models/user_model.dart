import '../core/network/auth_token.dart';

class UserModel {
  final String id;
  final String? accountId;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final String role;
  final int score;
  final String? rankingName;
  final List<String> vehicleModelIds;
  final bool profileCompleted;
  final List<String> missingRequirements;
  final List<String> eligibleVehicleModelIds;

  UserModel({
    required this.id,
    this.accountId,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    this.role = 'EVDriver',
    this.score = 0,
    this.rankingName,
    this.vehicleModelIds = const [],
    this.profileCompleted = false,
    this.missingRequirements = const [],
    this.eligibleVehicleModelIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:
          json['id']?.toString() ??
          json['userId']?.toString() ??
          json['accountId']?.toString() ??
          '',
      accountId: json['accountId']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phoneNumber']?.toString() ?? json['phone']?.toString(),
      address: json['address']?.toString(),
      avatar:
          json['profilePictureUrl']?.toString() ?? json['avatar']?.toString(),
      role:
          json['role']?.toString() ??
          json['user_role']?.toString() ??
          'EVDriver',
      score: json['score'] is int
          ? json['score']
          : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      rankingName: json['rankingName']?.toString(),
      vehicleModelIds:
          (json['vehicleModelIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profileCompleted: json['profileCompleted'] == true,
      missingRequirements:
          (json['missingRequirements'] as List?)
              ?.whereType<String>()
              .toList() ??
          [],
      eligibleVehicleModelIds:
          (json['eligibleVehicleModelIds'] as List?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  factory UserModel.fromDriverProfile(dynamic json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! String ||
        !AuthToken.isGuid(json['id']) ||
        json['accountId'] is! String ||
        !AuthToken.isGuid(json['accountId']) ||
        json['email'] is! String ||
        (json['email'] as String).isEmpty) {
      throw const FormatException('Hồ sơ tài xế không đúng contract backend.');
    }
    return UserModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'name': name,
      'email': email,
      'phoneNumber': phone,
      'address': address,
      'profilePictureUrl': avatar,
      'role': role,
      'score': score,
      'rankingName': rankingName,
      'vehicleModelIds': vehicleModelIds,
      'profileCompleted': profileCompleted,
      'missingRequirements': missingRequirements,
      'eligibleVehicleModelIds': eligibleVehicleModelIds,
    };
  }
}

class AuthResponseModel {
  final String token;
  final UserModel? user;
  final DateTime? expiration;

  AuthResponseModel({required this.token, this.user, this.expiration});

  factory AuthResponseModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic> ||
        json['token'] is! String ||
        (json['token'] as String).isEmpty) {
      throw const FormatException('Phản hồi đăng nhập thiếu token.');
    }
    final token = json['token'] as String;
    AuthToken.parse(token);
    final expiration = json['expiration'] == null
        ? null
        : DateTime.tryParse(json['expiration'].toString());
    if (json['expiration'] != null &&
        (expiration == null || !expiration.isAfter(DateTime.now().toUtc()))) {
      throw const FormatException('Thời hạn phiên đăng nhập không hợp lệ.');
    }
    // The backend does not return a user/profile in its login response.
    return AuthResponseModel(token: token, expiration: expiration);
  }
}
