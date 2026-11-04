import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/empty_state.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  Future<void> _openAddVehicle() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
    if (!mounted) return;
    await context.read<VehicleProvider>().fetchVehicles();
    if (mounted) {
      await context.read<AuthProvider>().refreshProfile();
    }
  }

  void _showDeleteDialog(BuildContext context, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa xe khỏi danh sách?'),
        content: Text(
          'Bạn có chắc muốn xóa "${vehicle.modelName}" khỏi nhà để xe không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<VehicleProvider>(
                context,
                listen: false,
              ).deleteVehicle(vehicle.id);
              if (context.mounted && success) {
                await context.read<AuthProvider>().refreshProfile();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Đã xóa xe thành công' : 'Xóa xe thất bại',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Xóa xe'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();

    Widget body;
    if (vehicleProvider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vehicleProvider.vehicles.isEmpty) {
      body = vehicleProvider.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      vehicleProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vehicleProvider.fetchVehicles(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Chưa có xe nào trong gara',
              description:
                  'Thêm xe điện của bạn để tiện theo dõi dung lượng pin và nhận gợi ý chuẩn sạc tối ưu.',
              buttonText: 'Thêm Xe Mới',
              onButtonPressed: _openAddVehicle,
            );
    } else {
      body = RefreshIndicator(
        onRefresh: () => vehicleProvider.fetchVehicles(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: vehicleProvider.vehicles.length,
          itemBuilder: (context, index) {
            final car = vehicleProvider.vehicles[index];
            return _buildVehicleCard(context, vehicleProvider, car);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Xe Của Tôi (Garage)')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,


        icon: const Icon(Icons.add),
        label: const Text('Thêm Xe Mới'),
        onPressed: _openAddVehicle,
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    VehicleProvider provider,
    VehicleModel car,
  ) {
    final isSelected = provider.selectedVehicle?.id == car.id;
    final hasImage = car.imageUrl.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(
              child: Image.network(
                car.imageUrl.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: Container(
              color: hasImage
                  ? Colors.black.withValues(alpha: 0.65)
                  : const Color(0xFF1E293B),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.modelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Năm sản xuất: ${car.modelYear}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 26,
                      ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSpecItem('Dung lượng pin', '${car.batteryCapacityKWh} kWh', isDark: true),
                    _buildSpecItem('Công suất sạc', '${car.recommendedChargingPowerKW} kW', isDark: true),
                    _buildSpecItem('Biển số', car.licensePlate ?? 'Chưa có dữ liệu', isDark: true),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent.shade100,
                      ),
                      tooltip: 'Xóa xe',
                      onPressed: () => _showDeleteDialog(context, car),
                    ),
                    if (!isSelected) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final accepted = await provider.selectVehicle(car);
                          if (!context.mounted) return;
                          await context.read<AuthProvider>().refreshProfile();
                          if (context.mounted && !accepted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.errorMessage ?? 'Máy chủ chưa cho phép đổi xe.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Chọn xe này'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, {bool isDark = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
