import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/station_model.dart';
import '../../providers/station_provider.dart';
import '../station/station_detail_screen.dart';
import '../booking/create_booking_screen.dart';
import '../widgets/status_badge.dart';

class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(21.0285, 105.8542); // Mặc định Hà Nội
  StationModel? _selectedStation;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StationProvider>(context, listen: false);
      provider.fetchStations();
      _initLocation();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _initLocation() async {
    await _fetchUserLocation(animateToUser: true);
    _startLocationTracking();
  }

  Future<void> _fetchUserLocation({
    bool animateToUser = false,
    bool showFeedback = false,
  }) async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          if (showFeedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Vui lòng bật định vị (GPS) trên thiết bị.'),
                action: SnackBarAction(
                  label: 'Bật GPS',
                  onPressed: () => Geolocator.openLocationSettings(),
                ),
              ),
            );
          }
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          if (showFeedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt.',
                ),
                action: SnackBarAction(
                  label: 'Cài đặt',
                  onPressed: () => Geolocator.openAppSettings(),
                ),
              ),
            );
          }
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          if (showFeedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chưa cấp quyền vị trí cho ứng dụng.'),
              ),
            );
          }
        }
        return;
      }

      // Lấy nhanh vị trí đã biết gần nhất
      Position? pos = await Geolocator.getLastKnownPosition();

      // Nếu chưa có, yêu cầu vị trí hiện tại
      if (pos == null) {
        LocationSettings locationSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: true, // Ép Android đọc trực tiếp từ GPS Provider của máy ảo / GPS phần cứng
            timeLimit: const Duration(seconds: 12),
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          );
        }

        try {
          pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
        } catch (_) {
          // Thử lại lần 2 bằng FusedLocationClient
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
        }
      }

      if (mounted) {
        final target = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = target;
          _isLoadingLocation = false;
        });

        if (animateToUser) {
          _moveMapTo(target, 15.0);
        }

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã định vị: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy tín hiệu GPS (hết thời gian chờ). Vui lòng thử lại.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi lấy vị trí: $e'),
            ),
          );
        }
      }
    }
  }

  void _moveMapTo(LatLng destLocation, double destZoom) {
    try {
      _animatedMapMove(destLocation, destZoom);
    } catch (_) {
      _mapController.move(destLocation, destZoom);
    }
  }

  void _startLocationTracking() {
    try {
      LocationSettings settings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
          distanceFilter: 10,
        );
      } else {
        settings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen((pos) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      });
    } catch (_) {}
  }

  void _moveToUserLocation() async {
    if (_userLocation != null) {
      _moveMapTo(_userLocation!, 15.0);
    }
    await _fetchUserLocation(animateToUser: true, showFeedback: true);
  }

  double? _getStationDistanceKm(StationModel station) {
    if (_userLocation != null && station.latitude != 0 && station.longitude != 0) {
      return Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            station.latitude,
            station.longitude,
          ) /
          1000.0;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final stations = stationProvider.stations;

    return Scaffold(
      body: Stack(
        children: [
          // Flutter OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? _initialCenter,
              initialZoom: 13.0,
              onTap: (_, _) {
                setState(() {
                  _selectedStation = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fptu.prm.ev_charging_station',
              ),
              MarkerLayer(
                markers: [
                  // Station Markers
                  ...stations.map((station) {
                    final isSelected = _selectedStation?.id == station.id;
                    final isAvailable = station.totalAvailableConnectors > 0;

                    return Marker(
                      point: LatLng(station.latitude, station.longitude),
                      width: isSelected ? 60 : 46,
                      height: isSelected ? 60 : 46,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStation = station;
                          });
                          _animatedMapMove(
                            LatLng(station.latitude, station.longitude),
                            14.5,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.primary
                                : AppColors.statusOccupied,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3.5 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isAvailable
                                        ? AppColors.primary
                                        : AppColors.statusOccupied)
                                    .withValues(alpha: 0.5),
                                blurRadius: isSelected ? 14 : 8,
                                spreadRadius: isSelected ? 3 : 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),

                  // User Current Location Navigation Marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Pulsing Accuracy Halo
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.24),
                            ),
                          ),
                          // Inner Navigation Arrow Circle
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.navigation_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Search & Filter Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => stationProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trạm sạc, địa chỉ, quận...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: stationProvider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    stationProvider.setSearchQuery(''),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'Tất cả', stationProvider),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Available',
                          'Còn chỗ trống',
                          stationProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'FastDC',
                          'Siêu nhanh DC',
                          stationProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('CCS2', 'Chuẩn CCS2', stationProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Location Button (Bottom-Right Corner)
          Positioned(
            right: 16,
            bottom: _selectedStation != null ? 240 : 30,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Colors.blue.shade600,
              elevation: 4,
              tooltip: 'Vị trí của bạn',
              onPressed: _moveToUserLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.my_location, size: 24),
            ),
          ),

          // Bottom Station Preview Card (When Selected)
          if (_selectedStation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildStationBottomPreview(context, _selectedStation!),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, StationProvider provider) {
    final isSelected = provider.selectedFilter == key;
    return GestureDetector(
      onTap: () => provider.setFilter(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStationBottomPreview(
    BuildContext context,
    StationModel station,
  ) {
    final distanceKm = _getStationDistanceKm(station);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  station.stationName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                status: station.totalAvailableConnectors > 0
                    ? 'Available'
                    : 'Faulted',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            station.location,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.ev_station,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${station.totalAvailableConnectors}/${station.totalAllConnectors} Cổng trống',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.flash_on, color: AppColors.accent, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${Formatters.formatCurrency(station.pricePerKWh)}/kWh',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.near_me,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distanceKm != null
                        ? '${distanceKm.toStringAsFixed(1)} km'
                        : '-- km',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateBookingScreen(
                          presetStationId: station.id,
                        ),
                      ),
                    );
                  },
                  child: const Text('Đặt Lịch Trước'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            StationDetailScreen(stationId: station.id),
                      ),
                    );
                  },
                  child: const Text('Xem Chi Tiết'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
