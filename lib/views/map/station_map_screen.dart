import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

class _StationMapScreenState extends State<StationMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(10.7769, 106.7009); // TP. Hồ Chí Minh
  StationModel? _selectedStation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StationProvider>(context, listen: false);
      provider.fetchStations();
    });
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
              initialCenter: _initialCenter,
              initialZoom: 13.0,
              onTap: (_, __) {
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
                markers: stations.map((station) {
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
                        _mapController.move(
                          LatLng(station.latitude, station.longitude),
                          14.5,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.primary : AppColors.statusOccupied,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3.5 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isAvailable ? AppColors.primary : AppColors.statusOccupied)
                                  .withOpacity(0.5),
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
                }).toList(),
              ),
            ],
          ),

          // Top Search & Filter Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => stationProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trạm sạc, địa chỉ, quận...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: stationProvider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => stationProvider.setSearchQuery(''),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        _buildFilterChip('Available', 'Còn chỗ trống', stationProvider),
                        const SizedBox(width: 8),
                        _buildFilterChip('FastDC', 'Siêu nhanh DC', stationProvider),
                        const SizedBox(width: 8),
                        _buildFilterChip('CCS2', 'Chuẩn CCS2', stationProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: _selectedStation != null ? 240 : 24,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: AppColors.primary,
              mini: true,
              child: const Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(_initialCenter, 13.5);
              },
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
              color: Colors.black.withOpacity(0.08),
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

  Widget _buildStationBottomPreview(BuildContext context, StationModel station) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: station.totalAvailableConnectors > 0 ? 'Available' : 'Faulted'),
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
                  const Icon(Icons.ev_station, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${station.totalAvailableConnectors}/${station.totalAllConnectors} Cổng trống',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.flash_on, color: AppColors.accent, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatCurrency(station.pricePerKWh) + '/kWh',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.navigation_outlined, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${station.distanceKm} km',
                    style: const TextStyle(fontSize: 13),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateBookingScreen(presetStationId: station.id),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StationDetailScreen(stationId: station.id),
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
