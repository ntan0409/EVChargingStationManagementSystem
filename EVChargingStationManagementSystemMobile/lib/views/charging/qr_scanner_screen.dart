import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/connector_model.dart';
import '../../models/station_model.dart';
import '../../providers/station_provider.dart';
import 'start_charging_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualIdController = TextEditingController();
  bool _isTorchOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      _handleScannedCode(code);
    }
  }

  void _handleScannedCode(String code) {
    setState(() => _isProcessing = true);

    final stationProvider = Provider.of<StationProvider>(context, listen: false);
    final stations = stationProvider.stations;

    // Resolve connector and station
    StationModel targetStation = stations.isNotEmpty ? stations.first : StationModel(
      id: 'st-001',
      stationName: 'Trạm Sạc EV Hub - Landmark 81',
      location: '720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP.HCM',
      province: 'Hồ Chí Minh',
      latitude: 10.7951,
      longitude: 106.7218,
    );

    ConnectorModel targetConnector = ConnectorModel(
      id: code.isNotEmpty ? code : 'conn-01',
      connectorName: 'Cổng Sạc DC 120kW #1',
      type: 'CCS2',
      maxPower: '120 kW',
      status: 'Available',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã nhận diện mã trụ sạc: $code'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StartChargingScreen(
          connector: targetConnector,
          station: targetStation,
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập Mã Trụ / Cổng Sạc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập mã định danh được in trên thân trụ sạc (VD: CONN-01, POST-120KW):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualIdController,
              decoration: const InputDecoration(
                hintText: 'Nhập mã trụ sạc...',
                prefixIcon: Icon(Icons.qr_code, color: AppColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final text = _manualIdController.text.trim();
              Navigator.of(ctx).pop();
              _handleScannedCode(text.isNotEmpty ? text : 'CONN-01');
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét Mã QR Sạc Pin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              _scannerController.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // QR Target Frame Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom instruction & Manual entry button
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hướng camera vào mã QR được dán tại đầu cổng sạc hoặc thân trụ sạc',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.keyboard_outlined, size: 22),
                  label: const Text('Nhập mã thủ công / Chọn cổng sạc'),
                  onPressed: _showManualEntryDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
