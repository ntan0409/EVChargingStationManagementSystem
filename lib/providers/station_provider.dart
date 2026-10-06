import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/station_service.dart';

class StationProvider extends ChangeNotifier {
  final StationService _stationService = StationService();

  List<StationModel> _stations = [];
  StationModel? _selectedStation;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, CCS2, FastDC, Available

  List<StationModel> get stations {
    if (_searchQuery.isEmpty && _selectedFilter == 'All') {
      return _stations;
    }

    return _stations.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.stationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.province.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_selectedFilter == 'Available') {
        matchesFilter = s.totalAvailableConnectors > 0;
      } else if (_selectedFilter == 'FastDC') {
        matchesFilter = s.chargingPosts.any((p) => p.maxPowerKw >= 60);
      } else if (_selectedFilter == 'CCS2') {
        matchesFilter = s.chargingPosts.any((p) => p.connectorType.contains('CCS2'));
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  StationModel? get selectedStation => _selectedStation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void selectStation(StationModel? station) {
    _selectedStation = station;
    notifyListeners();
  }

  Future<void> fetchStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _stationService.getStations();
      if (response.success && response.data != null) {
        _stations = response.data!;
        if (_selectedStation == null && _stations.isNotEmpty) {
          _selectedStation = _stations.first;
        }
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStationById(String stationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _stationService.getStationById(stationId);
      if (response.success && response.data != null) {
        _selectedStation = response.data;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
