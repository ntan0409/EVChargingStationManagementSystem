import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  String? _authToken;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request & Response Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic base url check
          options.baseUrl = ApiConstants.baseUrl;

          // Inject Bearer Token
          if (_authToken == null) {
            final prefs = await SharedPreferences.getInstance();
            _authToken = prefs.getString('auth_token');
          }
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }

  // Generic GET
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Lỗi không xác định: $e');
    }
  }

  // Generic POST
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Lỗi không xác định: $e');
    }
  }

  // Generic PUT
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Lỗi không xác định: $e');
    }
  }

  // Generic PATCH
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Lỗi không xác định: $e');
    }
  }

  // Generic DELETE
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error('Lỗi không xác định: $e');
    }
  }

  // Response Handler
  ApiResponse<T> _handleResponse<T>(Response response, T Function(dynamic data)? fromJson) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? '';
      final rawData = body.containsKey('data') ? body['data'] : body;

      T? parsedData;
      if (fromJson != null && rawData != null) {
        parsedData = fromJson(rawData);
      } else if (rawData is T) {
        parsedData = rawData;
      }

      return ApiResponse.success(parsedData, message: message, statusCode: response.statusCode);
    } else {
      T? parsedData;
      if (fromJson != null) {
        parsedData = fromJson(body);
      } else if (body is T) {
        parsedData = body;
      }
      return ApiResponse.success(parsedData, statusCode: response.statusCode);
    }
  }

  // Error Handler
  ApiResponse<T> _handleDioError<T>(DioException e) {
    String errorMessage = 'Lỗi kết nối máy chủ';
    dynamic errors;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Quá thời gian kết nối. Vui lòng thử lại sau.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc địa chỉ API.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (data is Map<String, dynamic>) {
        errorMessage = data['message'] ?? data['title'] ?? 'Lỗi từ máy chủ ($statusCode)';
        errors = data['errors'];
      } else if (data is String && data.isNotEmpty) {
        errorMessage = data;
      } else {
        errorMessage = 'Lỗi HTTP $statusCode';
      }

      return ApiResponse.error(errorMessage, errors: errors, statusCode: statusCode);
    }

    return ApiResponse.error(errorMessage);
  }
}
