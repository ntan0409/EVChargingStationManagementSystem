import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final res = await _authService.changePassword(
      oldPassword: _oldPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại mật khẩu cũ.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi Mật Khẩu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Mật khẩu hiện tại',
                hintText: 'Nhập mật khẩu đang dùng',
                controller: _oldPasswordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                validator: (val) => Validators.requiredField(val, message: 'Vui lòng nhập mật khẩu hiện tại'),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Mật khẩu mới',
                hintText: 'Tối thiểu 6 ký tự',
                controller: _newPasswordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
                validator: Validators.password,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Xác nhận mật khẩu mới',
                hintText: 'Nhập lại mật khẩu mới',
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.primary),
                validator: (val) => Validators.confirmPassword(val, _newPasswordController.text),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Cập Nhật Mật Khẩu',
                isLoading: _isLoading,
                onPressed: _handleChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
