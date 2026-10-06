class FeedbackModel {
  final String id;
  final String stationId;
  final String? stationName;
  final int rating; // 1 -> 5 stars
  final String comment;
  final DateTime createdAt;
  final String? userName;

  FeedbackModel({
    required this.id,
    required this.stationId,
    this.stationName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Trạm sạc',
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userName: json['userName']?.toString() ?? 'Khách hàng',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'rating': rating,
      'comment': comment,
    };
  }
}
