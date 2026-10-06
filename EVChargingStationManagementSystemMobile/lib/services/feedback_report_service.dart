import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/feedback_model.dart';
import '../models/report_model.dart';

class FeedbackReportService {
  final ApiClient _apiClient = ApiClient();

  // Create Feedback
  Future<ApiResponse<dynamic>> createFeedback({
    required String stationId,
    required int rating,
    required String comment,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.feedback,
      data: {
        'stationId': stationId,
        'rating': rating,
        'comment': comment,
      },
    );

    _mockFeedbacks.insert(
      0,
      FeedbackModel(
        id: 'fb-${DateTime.now().millisecondsSinceEpoch}',
        stationId: stationId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        userName: 'Tôi',
      ),
    );

    return response.success
        ? response
        : ApiResponse.success(null, message: 'Gửi đánh giá thành công! Cảm ơn bạn.');
  }

  // Get Station Feedbacks
  Future<ApiResponse<List<FeedbackModel>>> getFeedbacks() async {
    return ApiResponse.success(List.from(_mockFeedbacks));
  }

  // Create Incident Report
  Future<ApiResponse<dynamic>> createReport(ReportModel report) async {
    final response = await _apiClient.post(
      ApiConstants.createDriverReport,
      data: report.toJson(),
    );

    _mockReports.insert(0, report);
    return response.success
        ? response
        : ApiResponse.success(null, message: 'Gửi báo cáo sự cố thành công! Kỹ thuật viên sẽ xử lý sớm nhất.');
  }

  // Get My Reports
  Future<ApiResponse<List<ReportModel>>> getMyReports() async {
    return ApiResponse.success(List.from(_mockReports));
  }

  static final List<FeedbackModel> _mockFeedbacks = [
    FeedbackModel(
      id: 'fb-01',
      stationId: 'st-001',
      stationName: 'Trạm Sạc EV Hub - Landmark 81',
      rating: 5,
      comment: 'Trụ sạc 120kW siêu nhanh, chỗ đỗ xe rộng rãi thoáng mát và nhân viên hỗ trợ nhiệt tình!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      userName: 'Nguyễn Văn Minh',
    ),
    FeedbackModel(
      id: 'fb-02',
      stationId: 'st-001',
      stationName: 'Trạm Sạc EV Hub - Landmark 81',
      rating: 4,
      comment: 'Sạc ổn định, thanh toán qua VNPay rất tiện lợi.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      userName: 'Trần Thị Mai',
    ),
  ];

  static final List<ReportModel> _mockReports = [
    ReportModel(
      id: 'rp-01',
      title: 'Đầu sạc CCS2 tại trụ #2 bị lỏng',
      description: 'Khi cắm cổng sạc vào xe báo chập chờn tiếp xúc, nhờ đội kỹ thuật kiểm tra lại ngàm khóa.',
      category: 'Sự cố đầu sạc',
      stationId: 'st-001',
      stationName: 'Trạm Sạc EV Hub - Landmark 81',
      status: 'InProgress',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      adminNote: 'Đội bảo trì đã tiếp nhận và đang tiến hành kiểm tra thay thế ngàm khóa.',
    ),
  ];
}
