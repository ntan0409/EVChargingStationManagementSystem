import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../auth/login_screen.dart';
import '../garage/my_vehicles_screen.dart';
import '../payment/transaction_history_screen.dart';
import '../vouchers/voucher_list_screen.dart';
import '../feedback_report/report_history_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'server_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất tài khoản?'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng EVOne không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final user = authProvider.currentUser;
    final isDark = themeProvider.isDarkMode;

    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey('profile-scroll'),
        child: Column(
          children: [
            // =========================================================
            // 1. HERO COVER & DRIVER PROFILE BANNER (Matching Web EVOne)
            // =========================================================
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover gradient banner (Clean & Minimalist)
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF090D16),
                        Color(0xFF064E3B),
                        Color(0xFF10B981),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Card body below cover
                Container(
                  margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar overlapping top edge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -45),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cardBg, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      color: AppColors.primaryContainer,
                                    ),
                                    child: ClipOval(
                                      child: (user?.avatar != null &&
                                              user!.avatar!.trim().isNotEmpty)
                                          ? Image.network(
                                              user.avatar!.trim(),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Center(
                                                child: Text(
                                                  user.name.isNotEmpty
                                                      ? user.name.characters.first.toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                user != null && user.name.isNotEmpty
                                                    ? user.name.characters.first.toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Camera edit avatar button
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: cardBg, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Name on clean white background (shifted up slightly to counter offset)
                            Transform.translate(
                              offset: const Offset(0, -32),
                              child: Column(
                                children: [
                                  Text(
                                    user?.name ?? 'Tài xế EVOne',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(9999),
                                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                        ),
                                        child: const Text(
                                          'TÀI XẾ EVONE',
                                          style: TextStyle(
                                            color: AppColors.primaryDark,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        user?.email ?? 'driver@evone.vn',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Đã kích hoạt',
                                            style: TextStyle(
                                              color: AppColors.primaryDark,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Side by side Pill Buttons (Matching Web EVOne)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                            side: BorderSide(
                                              color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(9999),
                                            ),
                                          ),
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text(
                                            'Chỉnh sửa hồ sơ',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: cardBg,
                                            foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            side: BorderSide(
                                              color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(9999),
                                            ),
                                          ),
                                          icon: const Icon(Icons.lock_outline, size: 16),
                                          label: const Text(
                                            'Đổi mật khẩu',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4-item Stats Strip inside card
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            border: Border(top: BorderSide(color: borderColor)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Lịch sử sạc', '${user?.score ?? 12} lượt', Icons.bolt, AppColors.primary),
                              _buildStatItem('Xe ghép', '${vehicleProvider.vehicles.length} xe', Icons.directions_car, AppColors.secondary),
                              _buildStatItem('Đánh giá', '4.9 ★', Icons.star, AppColors.accent),
                              _buildStatItem('Bảo mật', 'KYC ✓', Icons.verified_user, AppColors.accentPurple),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =========================================================
            // 2. QUICK ACTIONS (BENTO GRID - Matching Web EVOne)
            // =========================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Tiện Ích & Thao Tác Nhanh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _buildBentoTile(
                        context,
                        title: 'Garage Xe Điện',
                        subtitle: 'Quản lý phương tiện',
                        icon: Icons.directions_car_filled_rounded,
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyVehiclesScreen()),
                          );
                        },
                      ),
                      _buildBentoTile(
                        context,
                        title: 'Lịch Sử Giao Dịch',
                        subtitle: 'Hóa đơn & Nạp tiền',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                          );
                        },
                      ),
                      _buildBentoTile(
                        context,
                        title: 'Kho Voucher',
                        subtitle: 'Mã ưu đãi sạc điện',
                        icon: Icons.confirmation_number_rounded,
                        color: AppColors.accent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VoucherListScreen()),
                          );
                        },
                      ),
                      _buildBentoTile(
                        context,
                        title: 'Báo Cáo Sự Cố',
                        subtitle: 'Theo dõi khiếu nại',
                        icon: Icons.support_agent_rounded,
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =========================================================
                  // 3. SETTINGS & SYSTEM PREFERENCES
                  // =========================================================
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                          child: Text(
                            'Cài đặt ứng dụng & Hệ thống',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        SwitchListTile(
                          secondary: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          title: const Text(
                            'Chế độ giao diện tối (Dark Mode)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          value: isDark,
                          activeColor: AppColors.primary,
                          onChanged: (val) => themeProvider.toggleTheme(),
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.dns_outlined, color: AppColors.secondary, size: 22),
                          title: const Text(
                            'Cấu hình máy chủ API (Backend)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Localhost / LAN IP / Cloud Server', style: TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================================================
                  // 4. SUPPORT 24/7 BANNER (Matching Web EVOne)
                  // =========================================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF090D16), Color(0xFF064E3B), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Hỗ Trợ Kỹ Thuật 24/7',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Đội ngũ EVOne luôn sẵn sàng hỗ trợ bạn khi sạc pin hoặc phát sinh sự cố tại trạm.',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF065F46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(0, 42),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
                              );
                            },
                            child: const Text('Gửi Yêu Cầu Hỗ Trợ', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.3), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppColors.error.withOpacity(0.04),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text(
                        'Đăng Xuất Khỏi Tài Khoản',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showLogoutDialog(context, authProvider),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBentoTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
