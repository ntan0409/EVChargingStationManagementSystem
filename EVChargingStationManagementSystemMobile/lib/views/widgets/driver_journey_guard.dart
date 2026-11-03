import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/driver_journey_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/charging_session_provider.dart';
import '../../services/driver_journey_service.dart';
import '../profile/profile_completion_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../charging/live_charging_screen.dart';
import 'api_problem.dart';

enum DriverJourneyStep { booking, charging }

class DriverJourneyGuard extends StatefulWidget {
  final DriverJourneyStep step;
  final String? connectorId;
  final DriverJourneyService? service;
  final Widget Function(BuildContext, DriverJourneyModel) builder;
  const DriverJourneyGuard({
    super.key,
    required this.step,
    required this.builder,
    this.connectorId,
    this.service,
  });
  @override
  State<DriverJourneyGuard> createState() => _DriverJourneyGuardState();
}

class _DriverJourneyGuardState extends State<DriverJourneyGuard>
    with WidgetsBindingObserver {
  DriverJourneyModel? _state;
  String? _error;
  bool _loading = true;
  int _epoch = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _epoch++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final epoch = ++_epoch;
    setState(() {
      _loading = true;
      _error = null;
      _state = null;
    });
    final auth = context.read<AuthProvider?>();
    final result =
        await (widget.service ??
                DriverJourneyService(apiClient: auth?.apiClient))
            .getState();
    if (!mounted || epoch != _epoch) return;
    setState(() {
      _loading = false;
      if (result.success &&
          result.data != null &&
          (auth == null ||
              auth.currentUser?.accountId == result.data!.accountId))
        _state = result.data;
      else
        _error = result.message.isEmpty
            ? 'Chưa xác minh điều kiện sử dụng với máy chủ.'
            : result.message;
    });
  }

  Future<void> _resume() async {
    final provider = context.read<ChargingSessionProvider>();
    if (await provider.restoreSession() &&
        mounted &&
        provider.currentSession != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LiveChargingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null)
      return Scaffold(
        appBar: AppBar(title: const Text('Kiểm tra điều kiện')),
        body: ApiProblem(message: _error!, onRetry: _load),
      );
    final state = _state!;
    if (!state.profileCompleted)
      return ProfileCompletionScreen(
        missingRequirements: state.missingRequirements,
        onCompleted: _load,
      );
    final booking = state.activeBooking;
    final allowed = widget.step == DriverJourneyStep.booking
        ? state.canBook
        : booking != null &&
              booking.status == 'InProgress' &&
              booking.vehicleId != null &&
        (widget.connectorId == null || booking.connectorId == widget.connectorId) &&
              state.currentSessionId == null;
    if (allowed) return widget.builder(context, state);
    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn tất bước trước')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.step == DriverJourneyStep.charging
                ? 'Cần lịch đặt của bạn đã check-in, đúng xe và cổng trước khi bắt đầu sạc.'
                : 'Bạn còn lịch đặt, phiên sạc hoặc hóa đơn chưa hoàn tất, hoặc đang bị khóa đặt lịch.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                )
                .then((_) {
                  if (mounted) _load();
                }),
            child: const Text('Mở lịch đặt để tiếp tục'),
          ),
          if (state.currentSessionId != null)
            TextButton(
              onPressed: _resume,
              child: const Text('Mở phiên/hóa đơn hiện tại'),
            ),
          TextButton(
            onPressed: _load,
            child: const Text('Kiểm tra lại với máy chủ'),
          ),
        ],
      ),
    );
  }
}
