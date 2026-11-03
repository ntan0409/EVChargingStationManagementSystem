import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/vehicle_service.dart';
import '../widgets/api_problem.dart';

// Customers may link a catalog model; only Admin creates/edits vehicle specifications.
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});
  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  List<VehicleModel> _models = [];
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final result = await VehicleService(
      apiClient: auth.apiClient,
    ).getVehicleModels();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.data != null)
        _models = result.data!;
      else
        _error = result.message;
    });
  }

  Future<void> _select(VehicleModel vehicle) async {
    if (_saving) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final result = await VehicleService(
      apiClient: auth.apiClient,
    ).addVehicle(vehicle);
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _saving = false;
        _error = result.message;
      });
      return;
    }
    await auth.refreshProfile();
    if (!mounted) return;
    await context.read<VehicleProvider>().fetchVehicles();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chọn xe từ catalog Admin')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Chọn mẫu xe bạn thực sự sử dụng. Thông số và trạng thái do Admin quản lý.',
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) ApiProblem(message: _error!, onRetry: _load),
        if (!_loading && _models.isEmpty)
          const Text('Chưa có mẫu xe trong catalog.'),
        for (final v in _models)
          Card(
            child: ListTile(
              title: Text(v.modelName),
              subtitle: Text(
                v.status == 'Active' && v.batteryCapacityKWh > 0
                    ? '${v.batteryCapacityKWh} kWh · ${v.vehicleType}'
                    : 'Không thể chọn: bị tắt hoặc thiếu thông số. Cần Admin cập nhật.',
              ),
              trailing: _saving ? null : const Icon(Icons.add_circle_outline),
              onTap:
                  _saving || v.status != 'Active' || v.batteryCapacityKWh <= 0
                  ? null
                  : () => _select(v),
            ),
          ),
      ],
    ),
  );
}
