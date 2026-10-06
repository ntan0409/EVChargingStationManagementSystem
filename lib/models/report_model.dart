class ReportModel {
  final String id;
  final String title;
  final String description;
  final String category; // Malfunction, Connector Broken, Payment Issue, Cleanliness, Other
  final String stationId;
  final String? stationName;
  final String? chargingPostId;
  final String status; // Pending, InProgress, Resolved, Rejected
  final DateTime createdAt;
  final String? imageUrl;
  final String? adminNote;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.stationId,
    this.stationName,
    this.chargingPostId,
    this.status = 'Pending',
    required this.createdAt,
    this.imageUrl,
    this.adminNote,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Báo cáo sự cố',
      description: json['description']?.toString() ?? json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Sự cố đầu sạc',
      stationId: json['stationId']?.toString() ?? '',
      stationName: json['stationName']?.toString() ?? 'Trạm sạc',
      chargingPostId: json['chargingPostId']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      imageUrl: json['imageUrl']?.toString(),
      adminNote: json['adminNote']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'stationId': stationId,
      if (chargingPostId != null) 'chargingPostId': chargingPostId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
