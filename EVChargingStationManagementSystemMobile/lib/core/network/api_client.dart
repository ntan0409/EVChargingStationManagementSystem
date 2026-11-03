import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_response.dart';
import 'transport_error.dart' if (dart.library.io) 'transport_error_io.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal(Dio());
  factory ApiClient({Dio? dio}) =>
      dio == null ? _instance : ApiClient._internal(dio);

  final Dio _dio;
  String? _authToken;
  String? _tokenBaseUrl;
  final Set<void Function(String)> _unauthorizedListeners = {};
  void addUnauthorizedListener(void Function(String) listener) =>
      _unauthorizedListeners.add(listener);
  void removeUnauthorizedListener(void Function(String) listener) =>
      _unauthorizedListeners.remove(listener);

  ApiClient._internal(this._dio) {
    _dio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..sendTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      // Decode here so malformed JSON retains the HTTP status.
      ..responseType = ResponseType.plain
      ..followRedirects = false
      ..validateStatus = (status) =>
          status != null && status >= 200 && status < 300;
    _dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
  }

  // AuthProvider owns persistence. Requests never reload tokens from preferences.
  void setAuthToken(String? token) {
    _authToken = token;
    _tokenBaseUrl = token == null ? null : ApiConstants.baseUrl;
  }

  Future<String?> getAuthToken() async => _authToken;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) => _request(
    'GET',
    path,
    queryParameters: queryParameters,
    fromJson: fromJson,
  );

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool authenticated = true,
  }) => _request(
    'POST',
    path,
    data: data,
    queryParameters: queryParameters,
    fromJson: fromJson,
    authenticated: authenticated,
  );

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) => _request(
    'PUT',
    path,
    data: data,
    queryParameters: queryParameters,
    fromJson: fromJson,
  );

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) => _request(
    'PATCH',
    path,
    data: data,
    queryParameters: queryParameters,
    fromJson: fromJson,
  );

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) => _request(
    'DELETE',
    path,
    data: data,
    queryParameters: queryParameters,
    fromJson: fromJson,
  );

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool authenticated = true,
  }) async {
    late String url;
    try {
      url = ApiConstants.resolveEndpoint(path);
    } on FormatException catch (error) {
      return ApiResponse.error(
        error.message,
        errorType: ApiErrorType.configuration,
      );
    }
    final requestOrigin = ApiConstants.baseUrl;
    final requestToken = authenticated && _tokenBaseUrl == requestOrigin
        ? _authToken
        : null;
    try {
      final response = await _dio.request<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: {
            'Authorization': requestToken != null
                ? 'Bearer $requestToken'
                : null,
          },
        ),
      );
      try {
        final body = _decode(response);
        final rawData = body is Map<String, dynamic> && body.containsKey('data')
            ? body['data']
            : body;
        final parsed = fromJson != null
            ? fromJson(rawData)
            : rawData is T
            ? rawData
            : null;
        return ApiResponse.success(
          parsed,
          message: body is Map
              ? (body['message'] ?? body['Message'] ?? '').toString()
              : '',
          statusCode: response.statusCode,
        );
      } catch (_) {
        return ApiResponse.error(
          'Dữ liệu máy chủ trả về không đúng định dạng.',
          statusCode: response.statusCode,
          errorType: ApiErrorType.parse,
        );
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 &&
          requestToken != null &&
          requestToken == _authToken &&
          requestOrigin == ApiConstants.baseUrl &&
          requestOrigin == _tokenBaseUrl) {
        for (final listener in _unauthorizedListeners.toList()) {
          listener(requestToken);
        }
      }
      return _handleDioError<T>(error);
    } catch (_) {
      // Never include request objects, credentials or exception dumps in the UI.
      return ApiResponse.error(
        'Không thể xử lý yêu cầu. Vui lòng thử lại.',
        errorType: ApiErrorType.unknown,
      );
    }
  }

  dynamic _decode(Response response) {
    final body = response.data;
    if (body is! String || body.isEmpty) return body;
    final contentType = response.headers.value(Headers.contentTypeHeader) ?? '';
    return contentType.contains('json') ? jsonDecode(body) : body;
  }

  ApiResponse<T> _handleDioError<T>(DioException error) {
    final status = error.response?.statusCode;
    if (isTlsError(error.error)) {
      return ApiResponse.error(
        'Chứng chỉ hoặc kết nối HTTPS không hợp lệ. Kiểm tra chứng chỉ và địa chỉ máy chủ.',
        statusCode: status,
        errorType: ApiErrorType.tls,
      );
    }
    if (error.response != null) {
      dynamic body;
      try {
        body = _decode(error.response!);
      } catch (_) {
        /* Keep HTTP status. */
      }
      final details = body is Map
          ? body['errors']
          : body is List
          ? body
          : null;
      return ApiResponse.error(
        _errorMessage(body) ??
            (status != null && status >= 300 && status < 400
                ? 'Máy chủ chuyển hướng. Kiểm tra HTTP/HTTPS và cổng API.'
                : 'Lỗi HTTP $status'),
        errors: details,
        statusCode: status,
        errorType: ApiErrorType.http,
      );
    }
    final (type, message) = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => (
        ApiErrorType.timeout,
        'Quá thời gian kết nối. Vui lòng thử lại sau.',
      ),
      DioExceptionType.badCertificate => (
        ApiErrorType.tls,
        'Chứng chỉ HTTPS không được tin cậy. Kiểm tra chứng chỉ và địa chỉ máy chủ.',
      ),
      DioExceptionType.connectionError => (
        ApiErrorType.network,
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc địa chỉ API.',
      ),
      DioExceptionType.cancel => (ApiErrorType.cancelled, 'Yêu cầu đã bị hủy.'),
      _ =>
        error.error is FormatException
            ? (
                ApiErrorType.parse,
                'Dữ liệu máy chủ trả về không đúng định dạng.',
              )
            : (
                ApiErrorType.unknown,
                'Không thể kết nối hoặc xử lý phản hồi từ máy chủ.',
              ),
    };
    return ApiResponse.error(message, statusCode: status, errorType: type);
  }

  String? _errorMessage(dynamic body) {
    if (body is String) {
      return body.trim().isEmpty || body.trimLeft().startsWith('<')
          ? null
          : body;
    }
    if (body is List) {
      final messages = body.map(_errorMessage).whereType<String>().toList();
      return messages.isEmpty ? null : messages.join('\n');
    }
    if (body is Map) {
      for (final key in ['message', 'Message', 'description']) {
        final message = _errorMessage(body[key]);
        if (message != null) return message;
      }
      final errors = body['errors'];
      if (errors is Map) {
        final message = _errorMessage(errors.values.toList());
        if (message != null) return message;
      } else if (errors != null) {
        final message = _errorMessage(errors);
        if (message != null) return message;
      }
      return _errorMessage(body['title']);
    }
    return null;
  }
}
