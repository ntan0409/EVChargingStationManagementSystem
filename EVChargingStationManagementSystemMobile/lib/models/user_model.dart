class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final String role;
  final int score;
  final String? rankingName;
  final List<String> vehicleModelIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    this.role = 'EVDriver',
    this.score = 0,
    this.rankingName,
    this.vehicleModelIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? json['accountId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Người dùng',
      email: json['email']?.toString() ?? '',
      phone: json['phoneNumber']?.toString() ?? json['phone']?.toString(),
      address: json['address']?.toString(),
      avatar: json['profilePictureUrl']?.toString() ?? json['avatar']?.toString(),
      role: json['role']?.toString() ?? json['user_role']?.toString() ?? 'EVDriver',
      score: json['score'] is int ? json['score'] : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      rankingName: json['rankingName']?.toString(),
      vehicleModelIds: (json['vehicleModelIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phone,
      'address': address,
      'profilePictureUrl': avatar,
      'role': role,
      'score': score,
      'rankingName': rankingName,
      'vehicleModelIds': vehicleModelIds,
    };
  }
}

class AuthResponseModel {
  final String token;
  final UserModel? user;

  AuthResponseModel({
    required this.token,
    this.user,
  });

  factory AuthResponseModel.fromJson(dynamic json) {
    if (json is String) {
      return AuthResponseModel(token: json);
    } else if (json is Map<String, dynamic>) {
      final token = json['token'] ?? json['accessToken'] ?? json['access_token'] ?? json['jwt'] ?? '';
      final user = json['user'] != null ? UserModel.fromJson(json['user']) : null;
      return AuthResponseModel(token: token, user: user);
    }
    return AuthResponseModel(token: '');
  }
}
