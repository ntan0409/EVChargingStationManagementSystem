import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleSendEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _authService.forgotPassword(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;

    setState(() {
      _codeSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : 'Đã gửi mã khôi phục đến email của bạn!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final res = await _authService.resetPassword(
      userId: _emailController.text.trim(),
      token: _tokenController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message.isNotEmpty ? res.message : 'Đặt lại mật khẩu thành công!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên Mật Khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Khôi phục mật khẩu',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Nhập email đã đăng ký để nhận mã xác thực đặt lại mật khẩu',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Email
                CustomTextField(
                  label: 'Email tài khoản',
                  hintText: 'Nhập email của bạn',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                if (!_codeSent) ...[
                  CustomButton(
                    text: 'Gửi Mã Xác Thực',
                    isLoading: _isLoading,
                    onPressed: _handleSendEmail,
                  ),
                ] else ...[
                  // Token
                  CustomTextField(
                    label: 'Mã xác thực (Token)',
                    hintText: 'Nhập mã gồm các chữ số gửi qua email',
                    controller: _tokenController,
                    prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
                    validator: (val) => Validators.requiredField(val, message: 'Vui lòng nhập mã xác thực'),
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  CustomTextField(
                    label: 'Mật khẩu mới',
                    hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
                    controller: _newPasswordController,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Đặt Lại Mật Khẩu',
                    isLoading: _isLoading,
                    onPressed: _handleResetPassword,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _handleSendEmail,
                      child: const Text('Gửi lại mã xác thực'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
