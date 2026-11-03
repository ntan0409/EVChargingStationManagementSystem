import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/station_service.dart';

class StationProvider extends ChangeNotifier {
  final StationService _stationService;
  StationProvider({StationService? stationService})
    : _stationService = stationService ?? StationService();
  List<StationModel> _stations = [];
  StationModel? _selectedStation;
  bool _isLoading = false;
  bool _disposed = false;
  int _epoch = 0;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  List<StationModel> get allStations => List.unmodifiable(_stations);
  List<StationModel> get stations => _stations.where((s) {
    final search =
        _searchQuery.isEmpty ||
        '${s.stationName} ${s.location} ${s.province}'.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
    final filter = switch (_selectedFilter) {
      'Available' => s.totalAvailableConnectors > 0,
      'FastDC' => s.chargingPosts.any((p) => p.maxPowerKw >= 60),
      'CCS2' => s.chargingPosts.any((p) => p.connectorType.contains('CCS2')),
      _ => true,
    };
    return search && filter;
  }).toList();
  StationModel? get selectedStation => _selectedStation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _notify();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _notify();
  }

  void selectStation(StationModel? station) {
    _selectedStation = station;
    _notify();
  }

  Future<void> fetchStations() async {
    if (_disposed) return;
    final epoch = ++_epoch;
    _isLoading = true;
    _errorMessage = null;
    _stations = [];
    _notify();
    try {
      final response = await _stationService.getStations();
      if (_disposed || epoch != _epoch) return;
      if (response.success && response.data != null) {
        _stations = response.data!;
      } else {
        _errorMessage = response.message;
      }
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        _errorMessage = 'Không tải được danh sách trạm sạc.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> fetchStationById(String id) async {
    if (_disposed) return;
    final epoch = ++_epoch;
    _isLoading = true;
    _errorMessage = null;
    _selectedStation = null;
    _notify();
    try {
      final response = await _stationService.getStationById(id);
      if (_disposed || epoch != _epoch) return;
      if (response.success && response.data != null) {
        _selectedStation = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        _errorMessage = 'Không tải được chi tiết trạm sạc.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
