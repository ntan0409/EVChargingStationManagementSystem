enum ApiErrorType {
  http,
  network,
  timeout,
  tls,
  parse,
  configuration,
  cancelled,
  unknown,
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;
  final int? statusCode;
  final ApiErrorType? errorType;

  ApiResponse({
    required this.success,
    this.message = '',
    this.data,
    this.errors,
    this.statusCode,
    this.errorType,
  });

  factory ApiResponse.success(T? data, {String message = '', int? statusCode}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(
    String message, {
    dynamic errors,
    int? statusCode,
    ApiErrorType? errorType,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
      errorType: errorType,
    );
  }
}
