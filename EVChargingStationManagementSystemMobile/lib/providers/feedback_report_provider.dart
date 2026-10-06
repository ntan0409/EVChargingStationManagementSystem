import 'package:flutter/material.dart';
import '../models/feedback_model.dart';
import '../models/report_model.dart';
import '../services/feedback_report_service.dart';

class FeedbackReportProvider extends ChangeNotifier {
  final FeedbackReportService _service = FeedbackReportService();

  List<FeedbackModel> _feedbacks = [];
  List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FeedbackModel> get feedbacks => _feedbacks;
  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFeedbacks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.getFeedbacks();
      if (response.success && response.data != null) {
        _feedbacks = response.data!;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.getMyReports();
      if (response.success && response.data != null) {
        _reports = response.data!;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback({
    required String stationId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.createFeedback(
        stationId: stationId,
        rating: rating,
        comment: comment,
      );
      _isLoading = false;
      await fetchFeedbacks();
      return response.success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReport(ReportModel report) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.createReport(report);
      _isLoading = false;
      await fetchReports();
      return response.success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
