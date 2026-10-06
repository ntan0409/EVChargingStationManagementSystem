import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelNameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _capacityController = TextEditingController(text: '80');
  final _powerController = TextEditingController(text: '60');
  String _vehicleType = 'Car'; // Car or Bike

  @override
  void dispose() {
    _modelNameController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    _capacityController.dispose();
    _powerController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = VehicleModel(
      id: 'v-${DateTime.now().millisecondsSinceEpoch}',
      modelName: _modelNameController.text.trim(),
      modelYear: int.tryParse(_yearController.text.trim()) ?? 2024,
      vehicleType: _vehicleType,
      batteryCapacityKWh: int.tryParse(_capacityController.text.trim()) ?? 80,
      recommendedChargingPowerKW: int.tryParse(_powerController.text.trim()) ?? 60,
      licensePlate: _licensePlateController.text.trim(),
    );

    final success = await Provider.of<VehicleProvider>(context, listen: false).addVehicle(vehicle);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm xe mới thành công!'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Xe Điện Mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Type Selector (Car / Bike)
              const Text('Loại phương tiện', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _vehicleType = 'Car'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _vehicleType == 'Car' ? AppColors.primary.withOpacity(0.12) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _vehicleType == 'Car' ? AppColors.primary : Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car, color: _vehicleType == 'Car' ? AppColors.primary : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Ô tô điện', style: TextStyle(fontWeight: FontWeight.bold, color: _vehicleType == 'Car' ? AppColors.primary : null)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _vehicleType = 'Bike'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _vehicleType == 'Bike' ? AppColors.primary.withOpacity(0.12) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _vehicleType == 'Bike' ? AppColors.primary : Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.two_wheeler, color: _vehicleType == 'Bike' ? AppColors.primary : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Xe máy điện', style: TextStyle(fontWeight: FontWeight.bold, color: _vehicleType == 'Bike' ? AppColors.primary : null)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Model Name
              CustomTextField(
                label: 'Tên dòng xe / Model',
                hintText: 'VD: VinFast VF8, VF9, Tesla Model Y...',
                controller: _modelNameController,
                prefixIcon: const Icon(Icons.drive_file_rename_outline, color: AppColors.primary),
                validator: (val) => Validators.requiredField(val, message: 'Vui lòng nhập tên dòng xe'),
              ),
              const SizedBox(height: 16),

              // License Plate
              CustomTextField(
                label: 'Biển số xe',
                hintText: 'VD: 51K-123.45',
                controller: _licensePlateController,
                prefixIcon: const Icon(Icons.pin, color: AppColors.primary),
                validator: (val) => Validators.requiredField(val, message: 'Vui lòng nhập biển số xe'),
              ),
              const SizedBox(height: 16),

              // Battery Capacity & Power Output
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Dung lượng pin (kWh)',
                      hintText: '80',
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.battery_charging_full, color: AppColors.primary),
                      validator: (val) => Validators.requiredField(val, message: 'Nhập dung lượng pin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Công suất nhận (kW)',
                      hintText: '60',
                      controller: _powerController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.flash_on, color: AppColors.primary),
                      validator: (val) => Validators.requiredField(val, message: 'Nhập công suất nhận'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Year
              CustomTextField(
                label: 'Năm sản xuất',
                hintText: '2024',
                controller: _yearController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Lưu Xe Vào Gara',
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
