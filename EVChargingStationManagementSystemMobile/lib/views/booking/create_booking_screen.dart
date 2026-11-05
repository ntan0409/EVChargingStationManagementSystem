import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
import '../widgets/driver_journey_guard.dart';
import '../../models/driver_journey_model.dart';
import '../../services/driver_journey_service.dart';

class CreateBookingScreen extends StatelessWidget {
  final String? presetStationId;
  final DriverJourneyService? journeyService;

  const CreateBookingScreen({
    super.key,
    this.presetStationId,
    this.journeyService,
  });
  @override
  Widget build(BuildContext context) => DriverJourneyGuard(
    step: DriverJourneyStep.booking,
    service: journeyService,
    builder: (context, state) => _CreateBookingContent(
      presetStationId: presetStationId,
      eligibility: state,
    ),
  );
}

class _CreateBookingContent extends StatefulWidget {
  final String? presetStationId;
  final DriverJourneyModel eligibility;
  const _CreateBookingContent({
    this.presetStationId,
    required this.eligibility,
  });

  @override
  State<_CreateBookingContent> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<_CreateBookingContent> {
  StationModel? _selectedStation;
  VehicleModel? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 10));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(minutes: 10)),
  );
  double _targetBattery = 80.0;
  double _currentBattery = 20.0;
  Position? _currentPosition;
  bool _filterNearby20kmOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final stationProvider = Provider.of<StationProvider>(
        context,
        listen: false,
      );
      final vehicleProvider = Provider.of<VehicleProvider>(
        context,
        listen: false,
      );

      await Future.wait([
        stationProvider.fetchStations(),
        vehicleProvider.fetchVehicles(),
        _fetchUserLocation(),
      ]);
      if (!mounted) return;

      _selectedVehicle = vehicleProvider.vehicles
          .where(
            (v) => widget.eligibility.eligibleVehicleModelIds.contains(v.id),
          )
          .firstOrNull;
      if (_selectedVehicle == null && vehicleProvider.vehicles.isNotEmpty) {
        _selectedVehicle = vehicleProvider.selectedVehicle ?? vehicleProvider.vehicles.first;
      }

      if (stationProvider.allStations.isNotEmpty) {
        if (widget.presetStationId != null) {
          _selectedStation = stationProvider.allStations
              .where((s) => s.id == widget.presetStationId)
              .firstOrNull;
        } else {
          // Sort stations by distance
          final sorted = List<StationModel>.from(stationProvider.allStations);
          sorted.sort((a, b) => _calculateDistanceKm(a).compareTo(_calculateDistanceKm(b)));

          // Prefer closest station within 20km with available slots
          _selectedStation = sorted.where((s) {
            final dist = _calculateDistanceKm(s);
            final slots = _getAvailableSlots(s);
            return dist <= 20.0 && slots > 0;
          }).firstOrNull ?? sorted.first;
        }
      }

      setState(() {});
    });
  }

  Future<void> _fetchUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
          });
        }
      }
    } catch (_) {}
  }

  double _calculateDistanceKm(StationModel station) {
    if (station.latitude == 0 && station.longitude == 0) return 0.0;
    // Default reference is Hanoi center (21.0285, 105.8542) if GPS is not yet acquired
    final userLat = _currentPosition?.latitude ?? 21.0285;
    final userLng = _currentPosition?.longitude ?? 105.8542;
    return Geolocator.distanceBetween(
          userLat,
          userLng,
          station.latitude,
          station.longitude,
        ) /
        1000.0;
  }

  int _getAvailableSlots(StationModel station) {
    final isBike = _selectedVehicle?.vehicleType.toLowerCase() == 'bike';
    return isBike
        ? station.availableBikeConnectors
        : station.availableCarConnectors;
  }

  int _getTotalSlots(StationModel station) {
    final isBike = _selectedVehicle?.vehicleType.toLowerCase() == 'bike';
    return isBike
        ? station.totalBikeConnectors
        : station.totalCarChargingConnectors;
  }

  String _getSlotTypeLabel() {
    final isBike = _selectedVehicle?.vehicleType.toLowerCase() == 'bike';
    return isBike ? 'cổng xe máy' : 'cổng ô tô';
  }

  void _handleConfirmBooking() async {
    if (_selectedStation == null ||
        _selectedVehicle == null ||
        _selectedVehicle!.batteryCapacityKWh <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chọn trạm và xe có dung lượng pin đã được quản trị xác nhận.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final availableSlots = _getAvailableSlots(_selectedStation!);
    if (availableSlots <= 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Trạm sạc hiện hết slot'),
          content: Text(
            'Trạm "${_selectedStation!.stationName}" hiện không còn ${_getSlotTypeLabel()} trống. Bạn có chắc chắn muốn tiếp tục đặt lịch trước không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Chọn trạm khác'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vẫn đặt lịch'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!mounted) return;

    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await bookingProvider.createBooking(
      stationId: _selectedStation!.id,
      vehicleId: _selectedVehicle!.id,
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

  void _showStationSelectionSheet(
    BuildContext context,
    StationProvider stationProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filterMode = _filterNearby20kmOnly ? 'nearby' : 'all'; // 'all', 'nearby', 'available'

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final all = stationProvider.allStations;
            final sorted = List<StationModel>.from(all);
            sorted.sort((a, b) => _calculateDistanceKm(a).compareTo(_calculateDistanceKm(b)));

            final nearbyList = sorted.where((s) => _calculateDistanceKm(s) <= 20.0).toList();
            final availableList = sorted.where((s) => _getAvailableSlots(s) > 0).toList();

            List<StationModel> displayed;
            if (filterMode == 'nearby') {
              displayed = nearbyList;
            } else if (filterMode == 'available') {
              displayed = availableList;
            } else {
              displayed = sorted;
            }

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chọn Trạm Sạc',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentPosition != null
                                  ? 'Đang dùng vị trí GPS hiện tại'
                                  : 'Khoảng cách ước tính từ vị trí của bạn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: filterMode == 'all',
                          label: Text('Tất cả (${sorted.length})'),
                          onSelected: (_) => setSheetState(() => filterMode = 'all'),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: filterMode == 'nearby',
                          avatar: const Icon(Icons.near_me, size: 16),
                          label: Text('Gần bạn (< 20km) (${nearbyList.length})'),
                          onSelected: (_) => setSheetState(() => filterMode = 'nearby'),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: filterMode == 'available',
                          avatar: const Icon(Icons.check_circle_outline, size: 16),
                          label: Text('Còn slot trống (${availableList.length})'),
                          onSelected: (_) => setSheetState(() => filterMode = 'available'),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // Station List
                  Expanded(
                    child: displayed.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_off_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    filterMode == 'nearby'
                                        ? 'Không có trạm sạc nào trong bán kính 20km.'
                                        : 'Không tìm thấy trạm sạc phù hợp.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => setSheetState(() => filterMode = 'all'),
                                    child: const Text('Xem tất cả các trạm sạc'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: displayed.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final station = displayed[idx];
                              final isSelected = station.id == _selectedStation?.id;
                              final distance = _calculateDistanceKm(station);
                              final isNearby = distance <= 20.0;
                              final availSlots = _getAvailableSlots(station);
                              final totSlots = _getTotalSlots(station);

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedStation = station;
                                  });
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.withValues(alpha: 0.25),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isSelected ? 0.08 : 0.03,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: (isNearby
                                                      ? AppColors.primary
                                                      : Colors.grey.shade600)
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.ev_station,
                                              color: isNearby
                                                  ? AppColors.primary
                                                  : Colors.grey.shade700,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  station.stationName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${station.location}, ${station.province}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          // Distance Chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (isNearby
                                                      ? Colors.green.shade50
                                                      : Colors.orange.shade50),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isNearby
                                                    ? Colors.green.shade300
                                                    : Colors.orange.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.near_me,
                                                  size: 13,
                                                  color: isNearby
                                                      ? Colors.green.shade800
                                                      : Colors.orange.shade800,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isNearby
                                                      ? '${distance.toStringAsFixed(1)} km (Trong 20km)'
                                                      : '${distance.toStringAsFixed(0)} km (Ngoài 20km)',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isNearby
                                                        ? Colors.green.shade800
                                                        : Colors.orange.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Available Slots Chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: availSlots > 0
                                                  ? AppColors.primary.withValues(alpha: 0.1)
                                                  : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: availSlots > 0
                                                    ? AppColors.primary.withValues(alpha: 0.4)
                                                    : Colors.red.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  availSlots > 0
                                                      ? Icons.bolt
                                                      : Icons.cancel_outlined,
                                                  size: 13,
                                                  color: availSlots > 0
                                                      ? AppColors.primaryDark
                                                      : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  availSlots > 0
                                                      ? 'Còn trống $availSlots/$totSlots ${_getSlotTypeLabel()}'
                                                      : 'Hết slot ${_getSlotTypeLabel()}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: availSlots > 0
                                                      ? AppColors.primaryDark
                                                      : Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Price
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${Formatters.formatCurrency(station.pricePerKWh)}/kWh',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStationSelector(StationProvider stationProvider) {
    if (stationProvider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Đang tải danh sách trạm sạc…', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (stationProvider.errorMessage != null && stationProvider.allStations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stationProvider.errorMessage!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: stationProvider.fetchStations,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final station = _selectedStation;
    if (station == null) {
      return InkWell(
        onTap: () => _showStationSelectionSheet(context, stationProvider),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chạm để chọn trạm sạc', style: TextStyle(fontSize: 14)),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      );
    }

    final distance = _calculateDistanceKm(station);
    final isNearby = distance <= 20.0;
    final availSlots = _getAvailableSlots(station);
    final totSlots = _getTotalSlots(station);

    return InkWell(
      onTap: () => _showStationSelectionSheet(context, stationProvider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNearby
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.orange.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Name, Address & Change button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.ev_station,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.stationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${station.location}, ${station.province}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đổi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 22),

            // Distance & Slots
            Row(
              children: [
                // Distance badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isNearby
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isNearby
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 14,
                              color: isNearby ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Khoảng cách',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isNearby ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          isNearby ? 'Trong bán kính 20km' : 'Ngoài bán kính 20km',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isNearby ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Available slots badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: availSlots > 0
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: availSlots > 0
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              availSlots > 0 ? Icons.bolt : Icons.cancel_outlined,
                              size: 14,
                              color: availSlots > 0
                                  ? AppColors.primaryDark
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Slot khả dụng',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          availSlots > 0 ? '$availSlots/$totSlots slot' : 'Hết chỗ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: availSlots > 0
                                ? AppColors.primaryDark
                                : Colors.red.shade700,
                          ),
                        ),
                        Text(
                          '${station.availableCarConnectors} ô tô • ${station.availableBikeConnectors} xe máy',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (!isNearby) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Trạm này cách xa hơn 20km. Hãy kiểm tra thời gian di chuyển trước khi đặt.',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt Lịch Sạc Trước')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Select Station Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '1. Chọn trạm sạc',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () => _showStationSelectionSheet(context, stationProvider),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 15,
                          color: _filterNearby20kmOnly
                              ? AppColors.primary
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bán kính 20km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _filterNearby20kmOnly
                                ? AppColors.primary
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Station Selector Card
            _buildStationSelector(stationProvider),
            const SizedBox(height: 20),

            // 2. Select Vehicle
            const Text(
              '2. Chọn xe điện của bạn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleModel>(
                  isExpanded: true,
                  value: _selectedVehicle,
                  items: vehicleProvider.vehicles
                      .where(
                        (v) => widget.eligibility.eligibleVehicleModelIds.isEmpty ||
                            widget.eligibility.eligibleVehicleModelIds.contains(v.id),
                      )
                      .map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${v.modelName} (${v.licensePlate ?? "Chưa gắn biển"})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedVehicle = v;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Date & Time Picker
            const Text(
              '3. Chọn thời gian sạc dự kiến',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.formatDate(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Battery Target Sliders
            const Text(
              '4. Mục tiêu mức pin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mức pin hiện tại: ${_currentBattery.toInt()}%',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Mục tiêu: ${_targetBattery.toInt()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dự toán chi phí sạc',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Divider(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Năng lượng ước tính:',
                        style: TextStyle(fontSize: 13),
                      ),
                      Flexible(
                        child: Text(
                          'Chưa có số đo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đơn giá điện:',
                        style: TextStyle(fontSize: 13),
                      ),
                      Flexible(
                        child: Text(
                          _selectedStation?.hasPrice == true
                              ? '${Formatters.formatCurrency(_selectedStation!.pricePerKWh)}/kWh'
                              : 'Chưa có đơn giá',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thuế VAT:', style: TextStyle(fontSize: 13)),
                      Flexible(child: Text('Theo hóa đơn máy chủ')),
                    ],
                  ),
                  const Divider(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng chi phí tạm tính:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Máy chủ chưa cung cấp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
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
