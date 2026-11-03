import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveUrl(String url) async {
    final auth = context.read<AuthProvider>();
    final previousUrl = ApiConstants.baseUrl;
    try {
      await ApiConstants.setBaseUrl(url);
      if (previousUrl != ApiConstants.baseUrl) await auth.logout();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Không thể lưu cấu hình API.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật API Base URL: ${ApiConstants.baseUrl}'),
        backgroundColor: AppColors.success,
      ),
    );
    if (previousUrl != ApiConstants.baseUrl) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu Hình Kết Nối API')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ máy chủ Backend (ASP.NET Core)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Thiết lập đường dẫn API để ứng dụng mobile kết nối tới máy chủ backend của hệ thống.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            CustomTextField(
              label: 'API Base URL',
              controller: _urlController,
              prefixIcon: const Icon(Icons.link, color: AppColors.primary),
            ),
            const SizedBox(height: 20),

            const Text(
              'Cấu hình nhanh (Presets):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (!kReleaseMode)
              _buildPresetOption(
                title: 'Android Emulator (10.0.2.2)',
                subtitle: 'http://10.0.2.2:5058/api (debug)',
                url: 'http://10.0.2.2:5058/api',
              ),
            const SizedBox(height: 8),

            if (!kReleaseMode)
              _buildPresetOption(
                title: 'Localhost HTTP (Web / Windows debug)',
                subtitle: 'http://localhost:5058/api',
                url: 'http://localhost:5058/api',
              ),
            const SizedBox(height: 8),

            _buildPresetOption(
              title: 'Localhost HTTPS (cần chứng chỉ tin cậy)',
              subtitle: 'https://localhost:7252/api',
              url: 'https://localhost:7252/api',
            ),
            const SizedBox(height: 8),

            _buildPresetOption(
              title: 'Thiết bị thật (nhập host/IP LAN của backend)',
              subtitle: kReleaseMode
                  ? 'HTTPS với chứng chỉ được tin cậy'
                  : 'Debug HTTP 5058; HTTPS 7252 cần chứng chỉ tin cậy',
              url: kReleaseMode ? 'https://' : 'http://',
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Lưu Cấu Hình',
              onPressed: () => _saveUrl(_urlController.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetOption({
    required String title,
    required String subtitle,
    required String url,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _urlController.text = url;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hub_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
