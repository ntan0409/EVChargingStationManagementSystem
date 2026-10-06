import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/report_model.dart';
import '../../models/station_model.dart';
import '../../providers/feedback_report_provider.dart';
import '../../providers/station_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'report_history_screen.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  StationModel? _selectedStation;
  String _selectedCategory = 'Sự cố đầu sạc';

  final List<String> _categories = [
    'Sự cố đầu sạc',
    'Trụ sạc không nhận thẻ/mã',
    'Không sạc được (Chập chờn)',
    'Lỗi thanh toán / Hóa đơn',
    'Chỗ đỗ xe bị chiếm dụng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = Provider.of<StationProvider>(context, listen: false);
      if (stationProvider.stations.isNotEmpty) {
        setState(() {
          _selectedStation = stationProvider.stations.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạm sạc gặp sự cố'), backgroundColor: AppColors.error),
      );
      return;
    }

    final report = ReportModel(
      id: 'rp-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      stationId: _selectedStation!.id,
      stationName: _selectedStation!.stationName,
      createdAt: DateTime.now(),
    );

    final success = await Provider.of<FeedbackReportProvider>(context, listen: false).submitReport(report);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi báo cáo sự cố thành công! Đội ngũ kỹ thuật đã tiếp nhận.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final reportProvider = context.watch<FeedbackReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Sự Cố'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
              );
            },
            child: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Chọn trạm sạc gặp sự cố', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StationModel>(
                    isExpanded: true,
                    value: _selectedStation,
                    items: stationProvider.stations.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.stationName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (s) => setState(() => _selectedStation = s),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('2. Phân loại sự cố', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (c) => setState(() => _selectedCategory = c!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              CustomTextField(
                label: '3. Tiêu đề sự cố',
                hintText: 'VD: Cổng CCS2 trụ #1 bị kẹt ngàm khóa',
                controller: _titleController,
                validator: (val) => Validators.requiredField(val, message: 'Vui lòng nhập tiêu đề'),
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                label: '4. Mô tả chi tiết vấn đề',
                hintText: 'Mô tả rõ biểu hiện, mã lỗi hiển thị trên màn hình trạm nếu có...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => Validators.requiredField(val, message: 'Vui lòng mô tả chi tiết'),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Gửi Báo Cáo Kỹ Thuật',
                isLoading: reportProvider.isLoading,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
