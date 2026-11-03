import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/charging_session_provider.dart';
import '../../services/station_service.dart';
import 'live_charging_screen.dart';
import 'start_charging_screen.dart';
import '../widgets/driver_journey_guard.dart';

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});
  @override
  Widget build(BuildContext context) => DriverJourneyGuard(
    step: DriverJourneyStep.charging,
    builder: (_, state) => const _QrScannerContent(),
  );
}

class _QrScannerContent extends StatefulWidget {
  const _QrScannerContent();
  @override
  State<_QrScannerContent> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerContent> {
  final _scanner = MobileScannerController();
  bool _processing = false;
  String? _failedCode;
  String? _error;
  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _resolve(String code) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    final response = await StationService().resolveConnector(code.trim());
    if (!mounted) return;
    if (!response.success || response.data == null) {
      setState(() {
        _processing = false;
        _failedCode = code;
        _error = response.message;
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StartChargingScreen(
          connector: response.data!.connector,
          station: response.data!.station,
        ),
      ),
    );
  }

  Future<void> _manual() async {
    var input = '';
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập mã GUID cổng sạc'),
        content: TextField(
          onChanged: (value) => input = value,
          decoration: const InputDecoration(labelText: 'Mã cổng từ máy chủ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, input),
            child: const Text('Tra cứu'),
          ),
        ],
      ),
    );
    if (code != null && mounted) await _resolve(code);
  }

  Future<void> _recover() async {
    final provider = context.read<ChargingSessionProvider>();
    final found = await provider.restoreSession();
    if (!mounted) return;
    if (found && provider.currentSession != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LiveChargingScreen()),
      );
    } else {
      setState(
        () => _error =
            provider.errorMessage ?? 'Máy chủ không có phiên chưa thanh toán.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quét Mã Cổng Sạc')),
    body: Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scanner,
            onDetect: (capture) {
              if (_processing) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null && code != _failedCode) _resolve(code);
            },
          ),
        ),
        if (_processing) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Quét mã GUID thật của cổng. Cổng và trạm được tra cứu lại từ máy chủ.',
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_failedCode != null && !_processing)
                TextButton(
                  onPressed: () => _resolve(_failedCode!),
                  child: const Text('Tra cứu lại cổng'),
                ),
              OutlinedButton(
                onPressed: _processing ? null : _manual,
                child: const Text('Nhập mã cổng sạc'),
              ),
              TextButton(
                onPressed: _processing ? null : _recover,
                child: const Text('Mở lại phiên / hóa đơn hiện tại'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
