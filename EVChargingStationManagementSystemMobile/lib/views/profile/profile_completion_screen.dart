import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'vehicle_selection_screen.dart';
import '../payment/transaction_history_screen.dart';
import '../main_navigation_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final List<String>? missingRequirements;
  final VoidCallback? onCompleted;

  const ProfileCompletionScreen({
    super.key,
    this.missingRequirements,
    this.onCompleted,
  });

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = context.read<AuthProvider>().currentUser;
        _name.text = user?.name ?? '';
        final currentPhone = user?.phone ?? '';
        _phone.text = currentPhone.contains('Chưa cập nhật')
            ? ''
            : currentPhone;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _skipForNow() {
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  void _goToVehicleSelection() {
    if (!_form.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleSelectionScreen(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          onCompleted: widget.onCompleted,
        ),
      ),
    );
  }

  String _reason(String code) => switch (code) {
    'name' => 'Họ và tên',
    'phoneNumber' => 'Số điện thoại (tùy chọn)',
    'emailVerification' => 'Email đã xác minh',
    'supportedVehicle' => 'Phương tiện hợp lệ',
    'accountInactive' => 'Tài khoản/hồ sơ đang bị khóa',
    _ => 'Thông tin trên máy chủ',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final missing =
        widget.missingRequirements ??
        auth.currentUser?.missingRequirements ??
        <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn tất hồ sơ'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skipForNow,
            child: const Text(
              'Để sau',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with helpful information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Bước 1: Thông tin cá nhân',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Vui lòng kiểm tra họ tên và số điện thoại (tùy chọn) trước khi chọn phương tiện di chuyển. Bạn có thể bổ sung số điện thoại bất kỳ lúc nào sau này.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          if (missing.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            for (final code in missing)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _reason(code),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Input
                    Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _name,
                            decoration: InputDecoration(
                              labelText: 'Họ và tên',
                              hintText: 'Nhập họ và tên đầy đủ',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v == null ||
                                    v.trim().isEmpty ||
                                    v.contains('Chưa cập nhật')
                                ? 'Vui lòng nhập họ và tên'
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // Phone Field (Optional)
                          TextFormField(
                            controller: _phone,
                            decoration: InputDecoration(
                              labelText: 'Số điện thoại (tùy chọn)',
                              hintText: 'VD: 0918306884 (có thể cập nhật sau)',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null ||
                                  v.trim().isEmpty ||
                                  v.contains('Chưa cập nhật')) {
                                return null; // Số điện thoại tùy chọn, có thể thêm sau
                              }
                              return Validators.phone(v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: 'Tiếp tục chọn xe',
                    onPressed: _goToVehicleSelection,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _skipForNow,
                    child: const Text('Bỏ qua, vào màn hình chính'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    ),
                    child: const Text('Xem lịch sử giao dịch'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
