import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/station_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/custom_button.dart';
import 'checkin_qr_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final String? presetStationId;

  const CreateBookingScreen({super.key, this.presetStationId});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  StationModel? _selectedStation;
  VehicleModel? _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _targetBattery = 80.0;
  double _currentBattery = 20.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = Provider.of<StationProvider>(context, listen: false);
      final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);

      if (stationProvider.stations.isNotEmpty) {
        if (widget.presetStationId != null) {
          _selectedStation = stationProvider.stations.firstWhere(
            (s) => s.id == widget.presetStationId,
            orElse: () => stationProvider.stations.first,
          );
        } else {
          _selectedStation = stationProvider.stations.first;
        }
      }

      if (vehicleProvider.vehicles.isNotEmpty) {
        _selectedVehicle = vehicleProvider.selectedVehicle ?? vehicleProvider.vehicles.first;
      }
      setState(() {});
    });
  }

  void _handleConfirmBooking() async {
    if (_selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạm sạc'), backgroundColor: AppColors.error),
      );
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await bookingProvider.createBooking(
      stationId: _selectedStation!.id,
      vehicleId: _selectedVehicle?.id ?? 'v-001',
      startTime: bookingDateTime,
    );

    if (!mounted) return;

    if (success) {
      final latestBooking = bookingProvider.bookings.first;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CheckinQrScreen(booking: latestBooking),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? 'Đặt lịch thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    final batteryCapacity = _selectedVehicle?.batteryCapacityKWh ?? 80;
    final neededBatteryPercent = (_targetBattery - _currentBattery).clamp(0, 100);
    final estimatedEnergyKWh = (batteryCapacity * (neededBatteryPercent / 100.0));
    final pricePerKWh = _selectedStation?.pricePerKWh ?? 3850.0;
    final estimatedCost = estimatedEnergyKWh * pricePerKWh * 1.10; // +10% VAT

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Lịch Sạc Trước'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Station
            const Text('1. Chọn trạm sạc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StationModel>(
                  isExpanded: true,
                  value: _selectedStation,
                  items: stationProvider.stations.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.stationName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (s) {
                    setState(() {
                      _selectedStation = s;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Select Vehicle
            const Text('2. Chọn xe điện của bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: Text('${v.modelName} (${v.licensePlate ?? "Chưa gắn biển"})',
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
            const SizedBox(height: 20),

            // Date & Time Picker
            const Text('3. Chọn thời gian sạc dự kiến', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 14)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(Formatters.formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('${_selectedTime.format(context)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Battery Target Sliders
            const Text('4. Mục tiêu mức pin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mức pin hiện tại: ${_currentBattery.toInt()}%', style: const TextStyle(fontSize: 13)),
                      Text('Mục tiêu: ${_targetBattery.toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _targetBattery,
                    min: _currentBattery + 5,
                    max: 100,
                    divisions: 15,
                    activeColor: AppColors.primary,
                    label: '${_targetBattery.toInt()}%',
                    onChanged: (val) {
                      setState(() {
                        _targetBattery = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cost & Energy Estimate Breakdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dự toán chi phí sạc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Năng lượng ước tính:', style: TextStyle(fontSize: 13)),
                      Text(Formatters.formatEnergy(estimatedEnergyKWh), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đơn giá điện:', style: TextStyle(fontSize: 13)),
                      Text('${Formatters.formatCurrency(pricePerKWh)}/kWh', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thuế VAT (10%):', style: TextStyle(fontSize: 13)),
                      Text(Formatters.formatCurrency(estimatedEnergyKWh * pricePerKWh * 0.1), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng chi phí tạm tính:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(Formatters.formatCurrency(estimatedCost), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Confirm Button
            CustomButton(
              text: 'Xác Nhận Đặt Lịch',
              isLoading: bookingProvider.isLoading,
              onPressed: _handleConfirmBooking,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
