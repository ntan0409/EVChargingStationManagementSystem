import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/feedback_report_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreateFeedbackScreen extends StatefulWidget {
  final String stationId;
  final String stationName;

  const CreateFeedbackScreen({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<CreateFeedbackScreen> createState() => _CreateFeedbackScreenState();
}

class _CreateFeedbackScreenState extends State<CreateFeedbackScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chia sẻ cảm nhận của bạn'), backgroundColor: AppColors.error),
      );
      return;
    }

    final success = await Provider.of<FeedbackReportProvider>(context, listen: false).submitFeedback(
      stationId: widget.stationId,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá!'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedbackReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh Giá Trạm Sạc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    widget.stationName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text('Bạn cảm thấy trải nghiệm sạc tại đây như thế nào?'),
                  const SizedBox(height: 20),

                  // Star Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        iconSize: 42,
                        icon: Icon(
                          starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comment textfield
            CustomTextField(
              label: 'Nội dung nhận xét',
              hintText: 'Tốc độ sạc, vị trí trạm, độ sạch sẽ, nhân viên hỗ trợ...',
              controller: _commentController,
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Gửi Đánh Giá',
              isLoading: provider.isLoading,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
