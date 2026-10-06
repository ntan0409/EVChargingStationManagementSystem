import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class ConfirmEmailScreen extends StatefulWidget {
  final String email;

  const ConfirmEmailScreen({super.key, required this.email});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final _tokenController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _handleConfirm() async {
    if (_tokenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã token xác thực'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authService.confirmEmail(
      userId: widget.email,
      token: _tokenController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : 'Xác thực email thành công! Bạn có thể đăng nhập ngay.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleResend() async {
    setState(() => _isLoading = true);
    final res = await _authService.resendConfirmEmail(widget.email);
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : 'Đã gửi lại mã xác nhận email.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Thực Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Kiểm tra hộp thư đến',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Chúng tôi đã gửi mã xác thực đến địa chỉ:\n${widget.email}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                label: 'Mã xác thực Token / OTP',
                hintText: 'Nhập mã xác nhận',
                controller: _tokenController,
                prefixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                validator: (val) => Validators.requiredField(val, message: 'Vui lòng nhập mã xác nhận'),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Xác Nhận Email',
                isLoading: _isLoading,
                onPressed: _handleConfirm,
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _handleResend,
                  child: const Text('Chưa nhận được mã? Gửi lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
