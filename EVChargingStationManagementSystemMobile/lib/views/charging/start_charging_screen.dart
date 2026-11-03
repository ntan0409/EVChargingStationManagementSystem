import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connector_model.dart';
import '../../models/station_model.dart';
import '../../models/vehicle_model.dart';
import '../../providers/charging_session_provider.dart';
import '../../services/station_service.dart';
import '../../services/vehicle_service.dart';
import '../widgets/api_problem.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'live_charging_screen.dart';
import '../widgets/driver_journey_guard.dart';
import '../../models/booking_model.dart';
import '../../services/driver_journey_service.dart';

class StartChargingScreen extends StatelessWidget {
  final ConnectorModel connector;
  final StationModel station;
  final DriverJourneyService? journeyService;
  const StartChargingScreen({
    super.key,
    required this.connector,
    required this.station,
    this.journeyService,
  });
  @override
  Widget build(BuildContext context) => DriverJourneyGuard(
    step: DriverJourneyStep.charging,
    connectorId: connector.id,
    service: journeyService,
    builder: (context, state) => _StartChargingContent(
      connector: connector,
      station: station,
      booking: state.activeBooking!,
    ),
  );
}

class _StartChargingContent extends StatefulWidget {
  final ConnectorModel connector;
  final StationModel station;
  final BookingModel booking;
  const _StartChargingContent({
    required this.connector,
    required this.station,
    required this.booking,
  });
  @override
  State<_StartChargingContent> createState() => _StartChargingScreenState();
}

class _StartChargingScreenState extends State<_StartChargingContent> {
  final _vehicles = VehicleService();
  List<VehicleModel> _choices = [];
  VehicleModel? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _inGarage = false;
  String? _error;
  double _initial = 20;
  double _target = 80;
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
      _choices = [];
      _selected = null;
    });
    final owned = await _vehicles.getMyVehicleModels();
    if (!mounted) return;
    if (!owned.success || owned.data == null) {
      setState(() {
        _loading = false;
        _error = owned.message;
      });
      return;
    }
    if (owned.data!.isNotEmpty) {
      setState(() {
        _choices = owned.data!
            .where((v) => v.id == widget.booking.vehicleId)
            .toList();
        _selected = _choices.firstOrNull;
        _inGarage = true;
        _loading = false;
      });
      return;
    }
    final catalog = await _vehicles.getVehicleModels();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _inGarage = false;
      if (catalog.success && catalog.data != null) {
        _choices = catalog.data!;
      } else {
        _error = catalog.message;
      }
    });
  }

  Future<void> _saveVehicle() async {
    final vehicle = _selected;
    if (vehicle == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _vehicles.addVehicle(vehicle);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!result.success) _error = result.message;
    });
    if (result.success) await _load();
  }

  Future<void> _start() async {
    final vehicle = _selected;
    if (vehicle == null ||
        !_inGarage ||
        vehicle.batteryCapacityKWh <= 0 ||
        _target <= _initial) {
      return;
    }
    final charging = context.read<ChargingSessionProvider>();
    // Re-read the real connector immediately before the user-requested mutation.
    setState(() {
      _saving = true;
      _error = null;
    });
    final location = await StationService().resolveConnector(
      widget.connector.id,
    );
    if (!mounted) return;
    if (!location.success ||
        location.data == null ||
        !location.data!.connector.canStart) {
      setState(() {
        _saving = false;
        _error = location.success
            ? 'Cổng chưa sẵn sàng. Cần cắm xe và không còn khóa thanh toán.'
            : location.message;
      });
      return;
    }
    final accepted = await charging.startCharging(
      connectorId: location.data!.connector.id,
      batteryCapacityKWh: vehicle.batteryCapacityKWh,
      initialBatteryLevelPercent: _initial.toInt(),
      expectedEnergiesKWh: _target.toInt(),
      vehicleModelId: vehicle.id,
      bookingId: widget.booking.id,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!accepted) _error = charging.errorMessage;
    });
    if (accepted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LiveChargingScreen()),
      );
    }
  }

  Future<void> _recover() async {
    final charging = context.read<ChargingSessionProvider>();
    final accepted = await charging.restoreSession();
    if (!mounted) return;
    if (accepted && charging.currentSession != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LiveChargingScreen()),
      );
    } else {
      setState(
        () => _error =
            charging.errorMessage ??
            'Không có phiên chưa thanh toán trên máy chủ.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final charging = context.watch<ChargingSessionProvider>();
    final busy = charging.isLoading || _saving;
    return Scaffold(
      appBar: AppBar(title: const Text('Thiết Lập Phiên Sạc')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.station.stationName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(widget.station.location),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(widget.connector.connectorName),
              subtitle: Text(
                '${widget.connector.type} • ${widget.connector.maxPower}',
              ),
              trailing: StatusBadge(status: widget.connector.status),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ApiProblem(message: _error!, onRetry: _load),
          if (!_loading && _choices.isEmpty && _error == null)
            const Text(
              'Chưa có mẫu xe trên máy chủ. Liên hệ quản trị viên để bổ sung.',
            ),
          if (_choices.isNotEmpty) ...[
            Text(
              _inGarage
                  ? 'Xe trong hồ sơ của bạn'
                  : 'Chọn mẫu xe và lưu vào hồ sơ trước khi sạc',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<VehicleModel>(
              initialValue: _selected,
              isExpanded: true,
              hint: const Text('Chọn mẫu xe từ máy chủ'),
              items: _choices
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '${v.modelName} • ${v.batteryCapacityKWh} kWh',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: busy ? null : (v) => setState(() => _selected = v),
            ),
            if (!_inGarage) ...[
              const SizedBox(height: 12),
              CustomButton(
                text: 'Lưu xe vào hồ sơ',
                onPressed: _selected == null || busy ? null : _saveVehicle,
                isLoading: _saving,
              ),
            ],
          ],
          if (_selected != null && _selected!.batteryCapacityKWh <= 0)
            const Text(
              'Mẫu xe trên máy chủ chưa có dung lượng pin hợp lệ. Cần quản trị viên cập nhật đúng thông số trước khi sạc.',
            ),
          const SizedBox(height: 24),
          Text('Mức pin bạn nhập: ${_initial.toInt()}%'),
          Slider(
            value: _initial,
            min: 0,
            max: 99,
            divisions: 99,
            onChanged: busy ? null : (v) => setState(() => _initial = v),
          ),
          Text('Mức pin mục tiêu: ${_target.toInt()}%'),
          Slider(
            value: _target,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: busy ? null : (v) => setState(() => _target = v),
          ),
          if (_target <= _initial)
            const Text('Mục tiêu phải lớn hơn mức pin ban đầu.'),
          const Text(
            'Chi phí được máy chủ tính theo điện năng đo được khi dừng phiên. Không dùng số liệu mô phỏng.',
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Bắt đầu sạc',
            isLoading: busy,
            onPressed:
                busy ||
                    !_inGarage ||
                    _selected == null ||
                    _selected!.batteryCapacityKWh <= 0 ||
                    _target <= _initial ||
                    charging.needsReconciliation
                ? null
                : _start,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy ? null : _recover,
            child: const Text('Kiểm tra / mở lại phiên hiện tại'),
          ),
        ],
      ),
    );
  }
}
