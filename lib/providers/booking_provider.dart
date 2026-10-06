import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get activeBookings =>
      _bookings.where((b) => b.isScheduled || b.isInProgress).toList();
  List<BookingModel> get historyBookings =>
      _bookings.where((b) => b.isCompleted || b.isCancelled).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _bookingService.getMyBookings();
      if (response.success && response.data != null) {
        _bookings = response.data!;
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

  Future<bool> createBooking({
    required String stationId,
    required String vehicleId,
    required DateTime startTime,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _bookingService.createBooking(
        stationId: stationId,
        vehicleId: vehicleId,
        startTime: startTime,
      );

      _isLoading = false;
      if (response.success && response.data != null) {
        _bookings.insert(0, response.data!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkIn(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _bookingService.checkInBooking(code);
      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _bookingService.cancelBooking(bookingId);
      _isLoading = false;
      if (response.success) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = BookingModel(
            id: _bookings[index].id,
            checkInCode: _bookings[index].checkInCode,
            startTime: _bookings[index].startTime,
            endTime: _bookings[index].endTime,
            status: 'Cancelled',
            stationId: _bookings[index].stationId,
            stationName: _bookings[index].stationName,
            location: _bookings[index].location,
            chargingPostName: _bookings[index].chargingPostName,
            connectorName: _bookings[index].connectorName,
            vehicleName: _bookings[index].vehicleName,
            estimatedCost: _bookings[index].estimatedCost,
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
