import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/auth_token.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/vehicle_service.dart';
import '../widgets/api_problem.dart';
import '../widgets/custom_button.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final String name;
  final String phone;
  final VoidCallback? onCompleted;

  const VehicleSelectionScreen({
    super.key,
    required this.name,
    required this.phone,
    this.onCompleted,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VehicleModel> _catalog = [];
  List<VehicleModel> _filteredCatalog = [];
  VehicleModel? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _selectedType = 'ALL'; // 'ALL', 'Car', 'Bike'

  bool _valid(VehicleModel v) =>
      v.status == 'Active' &&
      v.batteryCapacityKWh > 0 &&
      ['Car', 'Bike'].contains(v.vehicleType) &&
      v.recommendedChargingPowerKW >= 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCatalog();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
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
        final userVehicles = auth.currentUser?.vehicleModelIds ?? [];
        _selected = _catalog
            .where((v) => _valid(v) && userVehicles.contains(v.id))
            .firstOrNull;
        _applyFilter();
      } else {
        _error = response.message;
      }
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredCatalog = _catalog.where((vehicle) {
        final matchesQuery = query.isEmpty ||
            vehicle.modelName.toLowerCase().contains(query) ||
            vehicle.vehicleType.toLowerCase().contains(query);
        final matchesType = _selectedType == 'ALL' ||
            vehicle.vehicleType.toLowerCase() == _selectedType.toLowerCase();
        return matchesQuery && matchesType;
      }).toList();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final vehicle = _selected;
    if (vehicle == null || !_valid(vehicle)) {
      setState(() {
        _error = 'Vui lòng chọn một phương tiện hợp lệ từ danh sách.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final driverId = auth.currentUser?.id;

    if (driverId == null || !AuthToken.isGuid(driverId)) {
      setState(() {
        _saving = false;
        _error = 'Không tìm thấy hồ sơ tài xế.';
      });
      return;
    }

    final currentVehicles = auth.currentUser?.vehicleModelIds ?? [];
    final updatedVehicles = {...currentVehicles, vehicle.id}.toList();

    // Gửi cập nhật đồng thời Họ tên, SĐT và Danh sách xe trong một request duy nhất
    final updateResult = await auth.apiClient.put<Map<String, dynamic>>(
      ApiConstants.updateDriverProfile,
      data: {
        'driverId': driverId,
        'name': widget.name.trim(),
        'phoneNumber': widget.phone.trim(),
        'address': auth.currentUser?.address,
        'profilePictureUrl': auth.currentUser?.avatar,
        'vehicleModelIds': updatedVehicles,
      },
    );

    if (!mounted) return;

    if (!updateResult.success) {
      setState(() {
        _saving = false;
        _error = updateResult.message.isEmpty
            ? 'Không thể lưu hồ sơ lên máy chủ.'
            : updateResult.message;
      });
      return;
    }

    // Làm mới hồ sơ trên máy chủ
    await auth.refreshProfile();

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (auth.currentUser?.profileCompleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ và phương tiện thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onCompleted?.call();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final missing = auth.currentUser?.missingRequirements ?? [];
      final missingText = missing.map((m) {
        if (m == 'phoneNumber') return 'Số điện thoại';
        if (m == 'supportedVehicle') return 'Phương tiện hợp lệ';
        if (m == 'emailVerification') return 'Xác thực email';
        if (m == 'name') return 'Họ và tên';
        return m;
      }).join(', ');

      setState(() {
        _error = missing.isNotEmpty
            ? 'Còn thiếu các thông tin bắt buộc: $missingText.'
            : (auth.errorMessage ?? 'Máy chủ chưa xác nhận hoàn tất hồ sơ. Vui lòng thử lại.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn phương tiện'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên mẫu xe...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'ALL'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ô tô điện', 'Car'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Xe máy điện', 'Bike'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ApiProblem(message: _error!, onRetry: _save),
            ),

          // Vehicle List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCatalog.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined,
                                size: 64, color: Colors.grey[350]),
                            const SizedBox(height: 12),
                            Text(
                              _catalog.isEmpty
                                  ? 'Catalog chưa có phương tiện khả dụng'
                                  : 'Không tìm thấy phương tiện phù hợp',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _filteredCatalog.length,
                        itemBuilder: (context, index) {
                          final vehicle = _filteredCatalog[index];
                          final isValid = _valid(vehicle);
                          final isSelected = _selected?.id == vehicle.id;

                          return _buildVehicleCard(vehicle, isValid, isSelected);
                        },
                      ),
          ),

          // Bottom Action Bar - Duy nhất nút Lưu
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Xác nhận xe và lưu hồ sơ',
                isLoading: _saving,
                onPressed: (_loading || _selected == null || !_valid(_selected!))
                    ? null
                    : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _applyFilter();
          });
        }
      },
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle, bool isValid, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isValid ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isValid ? Colors.grey[200]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (isValid && !_saving)
              ? () => setState(() => _selected = vehicle)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Vehicle Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 64,
                    color: Colors.grey[100],
                    child: vehicle.imageUrl.isNotEmpty
                        ? Image.network(
                            vehicle.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Icon(
                              vehicle.vehicleType == 'Bike'
                                  ? Icons.two_wheeler
                                  : Icons.directions_car,
                              size: 36,
                              color: Colors.grey[400],
                            ),
                          )
                        : Icon(
                            vehicle.vehicleType == 'Bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 36,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Vehicle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.modelName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isValid ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.modelYear} · ${vehicle.vehicleType == 'Bike' ? 'Xe máy điện' : 'Ô tô điện'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isValid)
                        Row(
                          children: [
                            _buildSpecBadge(
                              '🔋 ${vehicle.batteryCapacityKWh} kWh',
                              Colors.blue[50]!,
                              Colors.blue[700]!,
                            ),
                            const SizedBox(width: 6),
                            _buildSpecBadge(
                              '⚡ ${vehicle.recommendedChargingPowerKW} kW',
                              Colors.amber[50]!,
                              Colors.amber[800]!,
                            ),
                          ],
                        )
                      else
                        Text(
                          'Xe bị tắt hoặc thiếu thông số',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                // Selection Radio Indicator
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected
                      ? AppColors.primary
                      : (isValid ? Colors.grey[350] : Colors.grey[200]),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
