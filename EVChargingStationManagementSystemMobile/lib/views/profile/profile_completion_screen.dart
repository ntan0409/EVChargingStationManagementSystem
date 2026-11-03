import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/charging_session_provider.dart';
import '../../services/vehicle_service.dart';
import '../widgets/api_problem.dart';
import '../widgets/custom_button.dart';
import '../payment/transaction_history_screen.dart';
import '../charging/live_charging_screen.dart';
import '../booking/my_bookings_screen.dart';

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
  final _name = TextEditingController(), _phone = TextEditingController();
  List<VehicleModel> _catalog = [];
  VehicleModel? _selected;
  bool _loading = true, _saving = false;
  String? _error;
  bool _valid(VehicleModel v) =>
      v.status == 'Active' &&
      v.batteryCapacityKWh > 0 &&
      ['Car', 'Bike'].contains(v.vehicleType) &&
      v.recommendedChargingPowerKW >= 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = context.read<AuthProvider>().currentUser;
        _name.text = user?.name ?? '';
        _phone.text = user?.phone ?? '';
        _load();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final response = await VehicleService(
      apiClient: auth.apiClient,
    ).getVehicleModels();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        _catalog = response.data!;
        _selected = _catalog
            .where(
              (v) =>
                  _valid(v) && auth.currentUser!.vehicleModelIds.contains(v.id),
            )
            .firstOrNull;
      } else {
        _error = response.message;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final vehicle = _selected;
    if (vehicle == null || !_valid(vehicle)) {
      setState(
        () => _error =
            'Chọn xe hợp lệ từ catalog Admin. Xe thiếu thông số phải được Admin cập nhật.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    if (!auth.currentUser!.vehicleModelIds.contains(vehicle.id)) {
      final saved = await VehicleService(
        apiClient: auth.apiClient,
      ).addVehicle(vehicle);
      if (!mounted) return;
      if (!saved.success) {
        setState(() {
          _saving = false;
          _error = saved.message;
        });
        return;
      }
    }
    final saved = await auth.updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: auth.currentUser?.address,
    );
    if (!mounted) return;
    if (saved && auth.currentUser!.profileCompleted) widget.onCompleted?.call();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!saved)
        _error = auth.errorMessage ?? 'Chưa xác nhận lưu hồ sơ.';
      else if (!auth.currentUser!.profileCompleted)
        _error =
            'Máy chủ chưa xác nhận hồ sơ hoàn tất. Kiểm tra email và xe đã chọn.';
    });
  }

  String _reason(String code) => switch (code) {
    'name' => 'Họ và tên',
    'phoneNumber' => 'Số điện thoại',
    'emailVerification' => 'Email đã xác minh',
    'supportedVehicle' => 'Xe Active với thông số hợp lệ',
    'accountInactive' => 'Tài khoản/hồ sơ đang bị khóa',
    _ => 'Hồ sơ trên máy chủ',
  };
  Future<void> _resume() async {
    final charging = context.read<ChargingSessionProvider>();
    if (await charging.restoreSession() &&
        mounted &&
        charging.currentSession != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LiveChargingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn tất hồ sơ'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Cập nhật hồ sơ và chọn xe trong catalog do Admin quản lý trước khi đặt lịch hoặc tạo phiên sạc.',
          ),
          for (final code
              in widget.missingRequirements ??
                  auth.currentUser?.missingRequirements ??
                  <String>[])
            Text('• ${_reason(code)}'),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: (v) =>
                      v == null ||
                          v.trim().isEmpty ||
                          v.contains('Chưa cập nhật')
                      ? 'Nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null ||
                          v.trim().isEmpty ||
                          v.contains('Chưa cập nhật')
                      ? 'Nhập số điện thoại'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Chọn xe bạn sử dụng'),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) ApiProblem(message: _error!, onRetry: _load),
          if (!_loading && _catalog.isEmpty)
            const Text(
              'Catalog chưa có xe. Cần Admin bổ sung thông tin xe chính thức.',
            ),
          for (final vehicle in _catalog)
            Card(
              child: ListTile(
                title: Text(vehicle.modelName),
                subtitle: Text(
                  _valid(vehicle)
                      ? '${vehicle.batteryCapacityKWh} kWh · ${vehicle.vehicleType}'
                      : 'Không thể chọn: xe bị tắt hoặc thiếu thông số. Cần Admin xác nhận.',
                ),
                trailing: Icon(
                  _selected?.id == vehicle.id
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                ),
                onTap: _saving || !_valid(vehicle)
                    ? null
                    : () => setState(() => _selected = vehicle),
              ),
            ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Lưu và xác minh với máy chủ',
            isLoading: _saving || auth.isLoading,
            onPressed: _loading ? null : _save,
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
            child: const Text('Xem / hủy lịch đặt đã có'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TransactionHistoryScreen(),
              ),
            ),
            child: const Text('Xem lịch sử giao dịch'),
          ),
          TextButton(
            onPressed: _resume,
            child: const Text('Mở phiên/hóa đơn đang có để tiếp tục xử lý'),
          ),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    if (await auth.refreshProfile() &&
                        mounted &&
                        auth.currentUser!.profileCompleted)
                      widget.onCompleted?.call();
                  },
            child: const Text('Kiểm tra lại hồ sơ trên máy chủ'),
          ),
        ],
      ),
    );
  }
}
