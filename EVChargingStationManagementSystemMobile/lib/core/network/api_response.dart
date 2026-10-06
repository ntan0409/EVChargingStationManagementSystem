class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message = '',
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.success(T? data, {String message = '', int? statusCode}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {dynamic errors, int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
    );
  }
}
