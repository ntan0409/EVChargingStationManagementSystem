import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/connector_model.dart';
import '../../models/station_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/charging_session_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'live_charging_screen.dart';

class StartChargingScreen extends StatefulWidget {
  final ConnectorModel connector;
  final StationModel station;

  const StartChargingScreen({
    super.key,
    required this.connector,
    required this.station,
  });

  @override
  State<StartChargingScreen> createState() => _StartChargingScreenState();
}

class _StartChargingScreenState extends State<StartChargingScreen> {
  double _initialBattery = 20.0;
  double _targetBattery = 80.0;
  VehicleModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
      if (vehicleProvider.vehicles.isNotEmpty) {
        setState(() {
          _selectedVehicle = vehicleProvider.selectedVehicle ?? vehicleProvider.vehicles.first;
        });
      }
    });
  }

  void _handleStartCharging() async {
    final chargingProvider = Provider.of<ChargingSessionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final batteryCapacity = _selectedVehicle?.batteryCapacityKWh ?? 80;

    final success = await chargingProvider.startCharging(
      connectorId: widget.connector.id,
      batteryCapacityKWh: batteryCapacity,
      initialBatteryLevelPercent: _initialBattery.toInt(),
      expectedEnergiesKWh: _targetBattery.toInt(),
      phone: authProvider.currentUser?.phone ?? '0912345678',
      vehicleModelId: _selectedVehicle?.id,
      stationPowerKw: double.tryParse(widget.connector.maxPower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 60.0,
      price: widget.station.pricePerKWh,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LiveChargingScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chargingProvider.errorMessage ?? 'Không thể bắt đầu phiên sạc'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final chargingProvider = context.watch<ChargingSessionProvider>();

    final batteryCapacity = _selectedVehicle?.batteryCapacityKWh ?? 80;
    final neededPercent = (_targetBattery - _initialBattery).clamp(0, 100);
    final energyToChargeKWh = batteryCapacity * (neededPercent / 100.0);
    final estimatedCost = energyToChargeKWh * widget.station.pricePerKWh * 1.10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết Lập Phiên Sạc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station & Connector Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.station.stationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const StatusBadge(status: 'Available'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.station.location,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.power_input, color: AppColors.primaryLight, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            widget.connector.connectorName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.connector.type} • ${widget.connector.maxPower}',
                        style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Vehicle
            const Text('Xe điện kết nối sạc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleModel>(
                  isExpanded: true,
                  value: _selectedVehicle,
                  items: vehicleProvider.vehicles.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text('${v.modelName} (Pin ${v.batteryCapacityKWh} kWh)',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedVehicle = v;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Current Battery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mức pin xe hiện tại:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('${_initialBattery.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ],
            ),
            Slider(
              value: _initialBattery,
              min: 5,
              max: 90,
              divisions: 17,
              activeColor: AppColors.secondary,
              label: '${_initialBattery.toInt()}%',
              onChanged: (val) {
                setState(() {
                  _initialBattery = val;
                  if (_targetBattery <= _initialBattery) {
                    _targetBattery = _initialBattery + 10;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Target Battery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mục tiêu sạc tới:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('${_targetBattery.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            Slider(
              value: _targetBattery,
              min: _initialBattery + 5,
              max: 100,
              divisions: 19,
              activeColor: AppColors.primary,
              label: '${_targetBattery.toInt()}%',
              onChanged: (val) {
                setState(() {
                  _targetBattery = val;
                });
              },
            ),
            const SizedBox(height: 20),

            // Estimate Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Năng lượng cần sạc:'),
                      Text(Formatters.formatEnergy(energyToChargeKWh), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ước tính chi phí sạc:'),
                      Text(Formatters.formatCurrency(estimatedCost), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Start Charging Button
            CustomButton(
              text: 'Cắm Sạc & Bắt Đầu',
              icon: const Icon(Icons.bolt, color: Colors.white),
              isLoading: chargingProvider.isLoading,
              onPressed: _handleStartCharging,
            ),
          ],
        ),
      ),
    );
  }
}
