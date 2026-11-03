import 'dart:convert';

/// Local format/lifetime checks only. The authenticated backend profile endpoint
/// must still verify the signature and session validity.
class AuthToken {
  final String accountId;
  final List<String> roles;
  final DateTime expiresAt;
  AuthToken._(this.accountId, this.roles, this.expiresAt);

  static bool isGuid(String value) =>
      RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value) &&
      value != '00000000-0000-0000-0000-000000000000';

  factory AuthToken.parse(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3 ||
        parts.any(
          (p) => p.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(p),
        )) {
      throw const FormatException('Token không đúng định dạng JWT.');
    }
    final header = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
    );
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (header is! Map ||
        header['alg'] != 'HS256' ||
        payload is! Map ||
        base64Url.decode(base64Url.normalize(parts[2])).length != 32) {
      throw const FormatException('Token không phù hợp với contract backend.');
    }
    final id = payload['userId'];
    final exp = payload['exp'];
    final role = payload['role'];
    final roles = role is String
        ? [role]
        : role is List
        ? role.whereType<String>().toList()
        : <String>[];
    if (id is! String || !isGuid(id) || exp is! int || roles.isEmpty) {
      throw const FormatException('Token thiếu claim phiên đăng nhập.');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp * 1000,
      isUtc: true,
    );
    final current = (now ?? DateTime.now()).toUtc();
    final nbf = payload['nbf'];
    if (!expiresAt.isAfter(current) ||
        (nbf != null &&
            (nbf is! int || nbf * 1000 > current.millisecondsSinceEpoch))) {
      throw const FormatException(
        'Phiên đăng nhập đã hết hạn hoặc chưa có hiệu lực.',
      );
    }
    return AuthToken._(id, roles, expiresAt);
  }
}
