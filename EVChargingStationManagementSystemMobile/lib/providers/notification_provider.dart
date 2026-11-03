import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0, _epoch = 0;
  bool _isLoading = false, _disposed = false, _mutating = false;
  String? _errorMessage, _account;
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isMutating => _mutating;
  String? get errorMessage => _errorMessage;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void bindAccount(String? account) {
    if (_account == account) return;
    _account = account;
    _epoch++;
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _mutating = false;
    _errorMessage = null;
    Future.microtask(_notify);
  }

  Future<void> fetchNotifications() async {
    if (_disposed || _isLoading) return;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notifications = [];
    _unreadCount = 0;
    _notify();
    try {
      final results = await Future.wait([
        _service.getNotifications(),
        _service.getUnreadCount(),
      ]);
      if (_disposed || epoch != _epoch) return;
      final list = results[0], count = results[1];
      if (list.success && list.data != null) {
        _notifications = List<NotificationModel>.from(list.data as List);
      } else {
        _errorMessage = list.message;
      }
      if (count.success && count.data is int) {
        _unreadCount = count.data as int;
      } else {
        _errorMessage ??= count.message;
      }
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        _errorMessage = 'Không tải được thông báo.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> _mark(Future<dynamic> Function() action) async {
    if (_disposed || _mutating || _isLoading) return;
    final epoch = _epoch;
    _mutating = true;
    _errorMessage = null;
    _notify();
    try {
      final result = await action();
      if (_disposed || epoch != _epoch) return;
      if (result.success) {
        await fetchNotifications();
      } else {
        _errorMessage = result.message;
      }
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        _errorMessage = 'Chưa xác nhận đã đọc thông báo.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _mutating = false;
        _notify();
      }
    }
  }

  Future<void> markAsRead(String id) => _mark(() => _service.markAsRead(id));
  Future<void> markAllAsRead() => _mark(_service.markAllAsRead);
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
