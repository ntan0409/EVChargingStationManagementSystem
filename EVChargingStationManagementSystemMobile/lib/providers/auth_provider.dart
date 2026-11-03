import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/auth_token.dart';
import '../core/network/api_response.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_identity.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final GoogleIdentity googleIdentity;
  AuthProvider({AuthService? authService, GoogleIdentity? googleIdentity})
    : _authService = authService ?? AuthService(),
      googleIdentity = googleIdentity ?? SdkGoogleIdentity() {
    _authService.addUnauthorizedListener(_onUnauthorized);
  }
  Timer? _expiryTimer;
  String? _verifiedToken;

  void _onUnauthorized(String token) {
    if (_isAuthenticated && token == _verifiedToken) {
      unawaited(_invalidateSession());
    }
  }

  Future<void> _invalidateSession() async {
    if (_disposed || !_isAuthenticated) return;
    final operation = ++_operation;
    _clearMemory();
    _isLoading = false;
    _errorMessage =
        'Phiên đăng nhập đã hết hạn hoặc bị từ chối. Vui lòng đăng nhập lại.';
    _notify();
    try {
      await _storeSession(null, operation);
    } catch (_) {
      if (_active(operation)) {
        _errorMessage =
            'Không thể xóa phiên đã lưu. Vui lòng đăng xuất và đăng nhập lại.';
      }
    }
    if (_active(operation)) _notify();
  }

  void _armExpiry(String token) {
    _expiryTimer?.cancel();
    _verifiedToken = token;
    final remaining = AuthToken.parse(
      token,
    ).expiresAt.difference(DateTime.now().toUtc());
    _expiryTimer = Timer(remaining, () {
      if (_verifiedToken == token) unawaited(_invalidateSession());
    });
  }

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  int _operation = 0;
  Future<void> _storageQueue = Future.value();
  static const _sessionKeys = [
    'auth_token',
    'auth_base_url',
    'user_id',
    'user_name',
    'user_email',
    'user_role',
    'user_phone',
  ];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ApiClient get apiClient => _authService.apiClient;

  Future<bool> refreshProfile() async {
    if (_disposed || _isLoading || !_isAuthenticated || _currentUser == null)
      return false;
    final operation = _begin();
    final current = _currentUser!;
    try {
      final response = await _authService.getProfile();
      if (!_active(operation)) return false;
      if (!response.success || response.data == null) {
        _errorMessage = response.message;
        if (response.statusCode == 401 || response.statusCode == 403)
          await _rejectSession(operation, response.message);
        return false;
      }
      if (response.data!.id != current.id ||
          response.data!.accountId != current.accountId)
        return false;
      _currentUser = response.data;
      return true;
    } finally {
      if (_active(operation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  bool _active(int operation) => !_disposed && operation == _operation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  int _begin() {
    _isLoading = true;
    _errorMessage = null;
    final operation = ++_operation;
    _notify();
    return operation;
  }

  // Serialize persistence so a late login cannot overwrite a subsequent logout.
  Future<void> _storeSession(String? token, int operation) {
    final task = _storageQueue.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (token != null && !_active(operation)) return;
      for (final key in _sessionKeys) {
        if (!await prefs.remove(key)) throw StateError('Cannot clear session');
      }
      if (token != null && _active(operation)) {
        if (!await prefs.setString('auth_token', token)) {
          throw StateError('Cannot save session');
        }
        if (!await prefs.setString('auth_base_url', ApiConstants.baseUrl)) {
          throw StateError('Cannot save session origin');
        }
      }
    });
    _storageQueue = task;
    return task;
  }

  void _clearMemory() {
    _expiryTimer?.cancel();
    _verifiedToken = null;
    _authService.setSessionToken(null);
    _currentUser = null;
    _isAuthenticated = false;
  }

  Future<void> _rejectSession(int operation, String message) async {
    if (!_active(operation)) return;
    _clearMemory();
    _errorMessage = message;
    try {
      await _storeSession(null, operation);
    } catch (_) {
      if (_active(operation)) {
        _errorMessage = '$message Không thể xóa phiên đã lưu trên thiết bị.';
      }
    }
  }

  Future<void> initAuth() async {
    if (_disposed || _isLoading) return;
    final operation = _begin();
    _clearMemory();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_active(operation)) return;
      final token = prefs.getString('auth_token');
      if (token == null) {
        await _storeSession(null, operation);
        return;
      }
      if (prefs.getString('auth_base_url') != ApiConstants.baseUrl) {
        throw const FormatException(
          'Phiên đăng nhập thuộc cấu hình máy chủ khác hoặc phiên cũ.',
        );
      }
      // Decoding is not signature verification. The backend must accept this
      // token at GET /EVDriver/profile before any authenticated UI is shown.
      final claims = AuthToken.parse(token);
      _authService.setSessionToken(token);
      final profile = await _authService.getProfile();
      if (!_active(operation)) return;
      if (!profile.success || profile.data == null) {
        await _rejectSession(
          operation,
          profile.message.isEmpty
              ? 'Không thể xác minh phiên đăng nhập.'
              : profile.message,
        );
        return;
      }
      AuthToken.parse(
        token,
      ); // A token may expire while the request is in flight.
      if (!claims.roles.contains('EVDriver') ||
          profile.data!.accountId?.toLowerCase() !=
              claims.accountId.toLowerCase()) {
        await _rejectSession(
          operation,
          'Hồ sơ không khớp với phiên đăng nhập.',
        );
        return;
      }
      _currentUser = profile.data;
      _isAuthenticated = true;
      _armExpiry(token);
    } on FormatException {
      await _rejectSession(
        operation,
        'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
      );
    } catch (_) {
      await _rejectSession(
        operation,
        'Không thể khôi phục phiên đăng nhập. Vui lòng đăng nhập lại.',
      );
    } finally {
      if (_active(operation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> _completeLogin(
    ApiResponse<AuthResponseModel> response,
    int operation,
    bool rememberMe,
  ) async {
    if (!_active(operation)) return false;
    if (!response.success || response.data == null) {
      await _rejectSession(
        operation,
        response.message.isEmpty ? 'Đăng nhập thất bại.' : response.message,
      );
      return false;
    }
    final token = response.data!.token;
    final claims = AuthToken.parse(token);
    _authService.setSessionToken(token);
    final profile = await _authService.getProfile();
    if (!_active(operation)) return false;
    if (!profile.success || profile.data == null) {
      await _rejectSession(
        operation,
        profile.message.isEmpty
            ? 'Không tải được hồ sơ tài xế.'
            : profile.message,
      );
      return false;
    }
    AuthToken.parse(token);
    if (!claims.roles.contains('EVDriver') ||
        profile.data!.accountId?.toLowerCase() !=
            claims.accountId.toLowerCase()) {
      await _rejectSession(
        operation,
        'Hồ sơ không khớp với phiên đăng nhập hoặc tài khoản không có quyền EVDriver.',
      );
      return false;
    }
    await _storeSession(rememberMe ? token : null, operation);
    if (!_active(operation)) return false;
    _currentUser = profile.data;
    _isAuthenticated = true;
    _armExpiry(token);
    return true;
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    if (_disposed || _isLoading) return false;
    final operation = _begin();
    _clearMemory();
    try {
      return await _completeLogin(
        await _authService.login(email, password),
        operation,
        rememberMe,
      );
    } on FormatException {
      await _rejectSession(
        operation,
        'Token đăng nhập không hợp lệ hoặc đã hết hạn.',
      );
      return false;
    } catch (_) {
      await _rejectSession(
        operation,
        'Không thể hoàn tất đăng nhập. Vui lòng thử lại.',
      );
      return false;
    } finally {
      if (_active(operation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> loginWithGoogle({
    bool rememberMe = true,
    GoogleCredential? credential,
  }) async {
    if (_disposed || _isLoading) return false;
    final operation = _begin();
    _clearMemory();
    var accepted = false;
    try {
      final result = credential ?? await googleIdentity.authenticate();
      if (!_active(operation)) return false;
      final failure = result.failure;
      if (failure != null) {
        if (failure.code == GoogleFailureCode.canceled) {
          await _storeSession(null, operation);
          return false; // Cancellation is not an authentication error.
        }
        await _rejectSession(operation, failure.message);
        return false;
      }
      final idToken = result.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        await _rejectSession(
          operation,
          const GoogleSignInFailure(GoogleFailureCode.emptyToken).message,
        );
        return false;
      }
      // Only the Google ID token goes to the exchange endpoint. Persistence and
      // profile verification exclusively use the backend's returned system JWT.
      accepted = await _completeLogin(
        await _authService.loginGoogle(idToken),
        operation,
        rememberMe,
      );
      return accepted;
    } on FormatException {
      await _rejectSession(
        operation,
        'JWT hệ thống trả về không hợp lệ hoặc đã hết hạn.',
      );
      return false;
    } catch (error) {
      await _rejectSession(
        operation,
        SdkGoogleIdentity.failureFor(error).message,
      );
      return false;
    } finally {
      if (!accepted) {
        try {
          await googleIdentity.signOut();
        } catch (_) {
          /* Keep the original failure. */
        }
      }
      if (_active(operation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    if (_disposed || _isLoading) return false;
    final operation = _begin();
    try {
      final response = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (!_active(operation)) return false;
      if (!response.success) {
        _errorMessage = response.message.isEmpty
            ? 'Đăng ký thất bại.'
            : response.message;
      }
      // Registration never changes an existing session/profile.
      return response.success;
    } catch (_) {
      if (_active(operation)) {
        _errorMessage = 'Không thể đăng ký tài khoản. Vui lòng thử lại.';
      }
      return false;
    } finally {
      if (_active(operation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? address,
  }) async {
    if (_disposed || _isLoading || !_isAuthenticated || _currentUser == null) {
      return false;
    }
    final operation = _begin();
    final current = _currentUser!;
    try {
      final response = await _authService.updateProfile(
        current,
        name: name,
        phone: phone,
        address: address,
      );
      if (!_active(operation)) return false;
      if (!response.success || response.data == null) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await _rejectSession(operation, response.message);
        } else {
          _errorMessage = response.message.isEmpty
              ? 'Không thể cập nhật hồ sơ.'
              : response.message;
        }
        return false;
      }
      if (response.data!.id != current.id ||
          response.data!.accountId != current.accountId) {
        _errorMessage = 'Hồ sơ máy chủ trả về không khớp với tài khoản.';
        return false;
      }
      _currentUser = response.data;
      return true;
    } catch (_) {
      if (_active(operation)) {
        _errorMessage = 'Không thể cập nhật hồ sơ. Vui lòng thử lại.';
      }
      return false;
    } finally {
      if (_active(operation)) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> logout() async {
    if (_disposed) return;
    final operation = ++_operation;
    _clearMemory();
    _isLoading = false;
    _errorMessage = null;
    _notify();
    try {
      await _storeSession(null, operation);
    } catch (_) {
      if (_active(operation)) {
        _errorMessage =
            'Đã thoát phiên hiện tại nhưng không thể xóa phiên đã lưu trên thiết bị.';
        _notify();
      }
    }
    try {
      await googleIdentity.signOut();
    } catch (_) {
      if (_active(operation)) {
        _errorMessage =
            'Phiên hệ thống đã được xóa; chưa thể hoàn tất đăng xuất Google. Vui lòng thử lại khi có mạng.';
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _authService.removeUnauthorizedListener(_onUnauthorized);
    _disposed = true;
    ++_operation;
    _authService.setSessionToken(null);
    super.dispose();
  }
}
