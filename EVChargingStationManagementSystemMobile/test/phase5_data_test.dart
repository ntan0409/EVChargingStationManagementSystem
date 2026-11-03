import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ev_charging_station/core/constants/api_constants.dart';
import 'package:ev_charging_station/core/network/api_client.dart';
import 'package:ev_charging_station/models/booking_model.dart';
import 'package:ev_charging_station/providers/booking_provider.dart';
import 'package:ev_charging_station/providers/notification_provider.dart';
import 'package:ev_charging_station/services/booking_service.dart';
import 'package:ev_charging_station/services/notification_service.dart';
import 'support/fake_api.dart';
import 'support/phase4_fixtures.dart' as f;

Map<String, dynamic> bookingFixture() => {
  'id': f.sessionId,
  'stationId': f.stationId,
  'status': 'Scheduled',
  'checkInCode': 'fixture-code',
  'startTime': '2026-11-03T10:00:00',
  'endTime': '2026-11-03T11:00:00',
};
Map<String, dynamic> notificationFixture({bool read = false}) => {
  'id': f.otherId,
  'title': 'Backend notification',
  'message': 'Fixture only',
  'type': 'System',
  'isRead': read,
  'createdAt': '2026-11-02T12:00:00',
};

void main() {
  late FakeApiAdapter adapter;
  ApiClient client(FutureOr<ResponseBody> Function(RequestOptions) handler) {
    adapter = FakeApiAdapter(handler);
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(dio.close);
    return ApiClient(dio: dio);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConstants.setBaseUrl(testBaseUrl);
  });
  for (final status in [401, 409, 500]) {
    test(
      'Booking HTTP$status never creates or cancels a local booking',
      () async {
        final service = BookingService(
          apiClient: client(
            (_) => jsonResponse({'message': 'Denied'}, status: status),
          ),
        );
        final provider = BookingProvider(bookingService: service);
        addTearDown(provider.dispose);
        expect(
          await provider.createBooking(
            stationId: f.stationId,
            vehicleId: f.vehicleId,
            startTime: DateTime.now().add(const Duration(hours: 1)),
          ),
          isFalse,
        );
        expect(provider.bookings, isEmpty);
        expect(await provider.cancelBooking(f.sessionId), isFalse);
        expect(provider.errorMessage, 'Denied');
        expect(adapter.requests.length, 2);
      },
    );
  }
  for (final status in [200, 404, 500]) {
    test(
      'Booking list HTTP$status distinguishes empty from error without demo',
      () async {
        final result = await BookingService(
          apiClient: client(
            (_) => jsonResponse(
              status == 200 ? {'data': []} : {'message': 'No data'},
              status: status,
            ),
          ),
        ).getMyBookings();
        expect(result.success, status != 500);
        if (status != 500) expect(result.data, isEmpty);
      },
    );
  }
  test('Booking DTO does not invent vehicle, check-in code, cost or dates', () {
    final model = BookingModel.fromJson({
      ...bookingFixture(),
      'checkInCode': null,
    });
    expect(model.vehicleName, isNull);
    expect(model.checkInCode, isNull);
    expect(model.hasEstimatedCost, isFalse);
    expect(
      () => BookingModel.fromJson({...bookingFixture(), 'startTime': 'bad'}),
      throwsFormatException,
    );
    expect(
      () => BookingModel.fromJson({...bookingFixture(), 'id': 'bk-demo'}),
      throwsFormatException,
    );
  });
  test(
    'Booking mutation sends supported body once and accepts only backend DTO',
    () async {
      final provider = BookingProvider(
        bookingService: BookingService(
          apiClient: client(
            (_) => jsonResponse({'data': bookingFixture()}, status: 201),
          ),
        ),
      );
      addTearDown(provider.dispose);
      expect(
        await provider.createBooking(
          stationId: f.stationId,
          vehicleId: f.vehicleId,
          startTime: DateTime(2026, 11, 3, 10),
        ),
        isTrue,
      );
      expect(
        adapter.requests.single.data.keys,
        unorderedEquals(['stationId', 'vehicleId', 'startTime']),
      );
      expect(provider.bookings.single.id, f.sessionId);
      expect(provider.bookings.single.hasEstimatedCost, isFalse);
    },
  );
  test('Late booking response cannot leak across accounts', () async {
    final pending = Completer<ResponseBody>();
    final provider = BookingProvider(
      bookingService: BookingService(apiClient: client((_) => pending.future)),
    );
    addTearDown(provider.dispose);
    provider.bindAccount('A');
    final read = provider.fetchMyBookings();
    await Future<void>.delayed(Duration.zero);
    provider.bindAccount('B');
    pending.complete(
      jsonResponse({
        'data': [bookingFixture()],
      }),
    );
    await read;
    expect(provider.bookings, isEmpty);
    expect(provider.isLoading, isFalse);
  });
  test(
    'Notification pagination uses notification ID and server unread count',
    () async {
      final provider = NotificationProvider(
        service: NotificationService(
          apiClient: client(
            (r) => r.path.endsWith('unread-count')
                ? jsonResponse({'count': 42})
                : jsonResponse({
                    'data': [notificationFixture(read: true)],
                    'page': 1,
                    'pageSize': 100,
                    'totalCount': 1,
                    'totalPages': 1,
                  }),
          ),
        ),
      );
      addTearDown(provider.dispose);
      await provider.fetchNotifications();
      expect(provider.notifications.single.id, f.otherId);
      expect(provider.notifications.single.isRead, isTrue);
      expect(provider.unreadCount, 42);
      expect(adapter.requests.first.queryParameters, {
        'page': 1,
        'pageSize': 100,
      });
    },
  );
  for (final status in [200, 401, 500]) {
    test(
      'Notification HTTP$status empty/error never displays payment demo',
      () async {
        final provider = NotificationProvider(
          service: NotificationService(
            apiClient: client(
              (_) => status == 200
                  ? jsonResponse({'data': []})
                  : jsonResponse({'message': 'Denied'}, status: status),
            ),
          ),
        );
        addTearDown(provider.dispose);
        await provider.fetchNotifications();
        expect(provider.notifications, isEmpty);
        expect(provider.unreadCount, 0);
        if (status != 200) expect(provider.errorMessage, 'Denied');
      },
    );
  }
  test('Failed read request does not mark a notification as read', () async {
    final provider = NotificationProvider(
      service: NotificationService(
        apiClient: client(
          (r) => r.method == 'PATCH'
              ? jsonResponse({'message': 'Cannot read'}, status: 500)
              : r.path.endsWith('unread-count')
              ? jsonResponse({'count': 1})
              : jsonResponse({
                  'data': [notificationFixture()],
                }),
        ),
      ),
    );
    addTearDown(provider.dispose);
    await provider.fetchNotifications();
    await provider.markAsRead(f.otherId);
    expect(provider.notifications.single.isRead, isFalse);
    expect(provider.unreadCount, 1);
    expect(provider.errorMessage, 'Cannot read');
  });
  test(
    'Notification read refreshes the server instead of assuming local success',
    () async {
      var serverRead = false;
      final provider = NotificationProvider(
        service: NotificationService(
          apiClient: client((r) {
            if (r.method == 'PATCH') {
              serverRead = true;
              return jsonResponse('Read saved');
            }
            return r.path.endsWith('unread-count')
                ? jsonResponse({'count': serverRead ? 0 : 1})
                : jsonResponse({
                    'data': [notificationFixture(read: serverRead)],
                  });
          }),
        ),
      );
      addTearDown(provider.dispose);
      provider.bindAccount('A');
      await provider.fetchNotifications();
      await provider.markAsRead(f.otherId);
      expect(provider.notifications.single.isRead, isTrue);
      expect(provider.unreadCount, 0);
      expect(
        adapter.requests.where((r) => r.method == 'PATCH').single.path,
        endsWith('/Notification/${f.otherId}/read'),
      );
      provider.bindAccount(null);
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
    },
  );
  test(
    'Repeated create booking is single flight and never retries POST',
    () async {
      final pending = Completer<ResponseBody>();
      final provider = BookingProvider(
        bookingService: BookingService(
          apiClient: client((_) => pending.future),
        ),
      );
      addTearDown(provider.dispose);
      final first = provider.createBooking(
        stationId: f.stationId,
        vehicleId: f.vehicleId,
        startTime: DateTime.now(),
      );
      expect(
        await provider.createBooking(
          stationId: f.stationId,
          vehicleId: f.vehicleId,
          startTime: DateTime.now(),
        ),
        isFalse,
      );
      pending.complete(
        jsonResponse({
          'message': 'Timeout equivalent uncertain response',
        }, status: 500),
      );
      expect(await first, isFalse);
      expect(adapter.requests.length, 1);
    },
  );
}
