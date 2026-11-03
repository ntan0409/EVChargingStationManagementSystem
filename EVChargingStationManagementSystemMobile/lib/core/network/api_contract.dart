import 'api_response.dart';

Map<String, dynamic> contractMap(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

List<T> contractList<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) throw const FormatException('Expected array');
  return value.map((item) => parse(contractMap(item))).toList();
}

bool isApiId(String value) =>
    RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value) &&
    value != '00000000-0000-0000-0000-000000000000';

String contractId(dynamic value) {
  if (value is! String || !isApiId(value)) {
    throw const FormatException('Invalid server ID');
  }
  return value;
}

double contractNumber(dynamic value, {bool allowNegative = false}) {
  if (value is! num || !value.isFinite || (!allowNegative && value < 0)) {
    throw const FormatException('Invalid server number');
  }
  return value.toDouble();
}

DateTime? contractDate(dynamic value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid server date');
  final date = DateTime.tryParse(value);
  if (date == null) throw const FormatException('Invalid server date');
  return date;
}

ApiResponse<T> forwardError<T>(ApiResponse<dynamic> response) =>
    ApiResponse.error(
      response.message,
      errors: response.errors,
      statusCode: response.statusCode,
      errorType: response.errorType,
    );

ApiResponse<T> invalidInput<T>(String message) =>
    ApiResponse.error(message, errorType: ApiErrorType.parse);
