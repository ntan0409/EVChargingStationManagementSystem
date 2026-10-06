import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/feedback_report_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackReportProvider>(context, listen: false).fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<FeedbackReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Báo Cáo Sự Cố'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await reportProvider.fetchReports();
        },
        child: reportProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : reportProvider.reports.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Chưa có báo cáo sự cố nào',
                    description: 'Tất cả các báo cáo sự cố kỹ thuật bạn đã gửi sẽ được cập nhật trạng thái tại đây.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: reportProvider.reports.length,
                    itemBuilder: (context, index) {
                      final item = reportProvider.reports[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.stationName ?? "Trạm sạc"} • ${item.category}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.description,
                                style: const TextStyle(fontSize: 13, height: 1.3),
                              ),
                              if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.support_agent, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Phản hồi từ kỹ thuật: ${item.adminNote}',
                                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Divider(height: 20),
                              Text(
                                'Ngày gửi: ${Formatters.formatDateTime(item.createdAt)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
