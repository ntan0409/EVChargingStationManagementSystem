import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/formatters.dart';
import '../../providers/station_provider.dart';
import '../charging/start_charging_screen.dart';
import '../widgets/api_problem.dart';
import '../widgets/status_badge.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationId;
  const StationDetailScreen({super.key, required this.stationId});
  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() =>
      context.read<StationProvider>().fetchStationById(widget.stationId);
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final station = provider.selectedStation;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi Tiết Trạm Sạc')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(
              child: ApiProblem(
                message: provider.errorMessage!,
                onRetry: _load,
              ),
            )
          : station == null
          ? Center(
              child: ApiProblem(
                message: 'Chưa tải được trạm sạc.',
                onRetry: _load,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    station.stationName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(station.location),
                  const SizedBox(height: 12),
                  StatusBadge(status: station.status),
                  const SizedBox(height: 12),
                  Text(
                    station.hasPrice
                        ? 'Đơn giá hiện tại: ${Formatters.formatCurrency(station.pricePerKWh)}/kWh'
                        : 'Chưa có đơn giá từ máy chủ.',
                  ),
                  const Text(
                    'Hóa đơn và thuế được xác nhận trên máy chủ sau khi dừng sạc.',
                  ),
                  const SizedBox(height: 20),
                  if (station.chargingPosts.isEmpty)
                    const Text('Trạm chưa có trụ sạc trong dữ liệu máy chủ.'),
                  for (final post in station.chargingPosts)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              post.postName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${post.connectorType} • ${post.maxPowerKw} kW • ${post.status}',
                            ),
                            if (post.connectors.isEmpty)
                              const Text('Chưa có cổng sạc.'),
                            for (final connector in post.connectors)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Divider(),
                                  Text(connector.connectorName),
                                  SelectableText(connector.id),
                                  StatusBadge(status: connector.status),
                                  if (connector.isLocked)
                                    const Text(
                                      'Cổng đang khóa bởi phiên / hóa đơn trước.',
                                    ),
                                  if (connector.isAvailable)
                                    const Text(
                                      'Cần cắm xe vào cổng trước khi bắt đầu, sau đó tải lại trạng thái.',
                                    ),
                                  OutlinedButton(
                                    onPressed: !connector.canStart
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  StartChargingScreen(
                                                    connector: connector,
                                                    station: station,
                                                  ),
                                            ),
                                          ),
                                    child: const Text('Thiết lập phiên sạc'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
