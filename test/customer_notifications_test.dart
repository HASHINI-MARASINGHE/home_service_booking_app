import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:home_service_bookin_app/models/app_notification.dart';
import 'package:home_service_bookin_app/models/dispute.dart';
import 'package:home_service_bookin_app/screens/customer/customer_notifications_screen.dart';
import 'package:home_service_bookin_app/screens/customer/disputes/dispute_screen.dart';
import 'package:home_service_bookin_app/services/dispute_service.dart';
import 'package:home_service_bookin_app/services/provider_notification_service.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _Notifications extends ProviderNotificationService {
  _Notifications(this.items) : super(auth: _Auth(), firestore: _Firestore());
  final List<AppNotification> items;
  final read = <String>[];

  @override
  Stream<List<AppNotification>> watchNotifications() => Stream.value(items);

  @override
  Stream<int> watchUnreadCount() =>
      Stream.value(items.where((i) => !i.read).length);

  @override
  Future<void> markRead(String id) async => read.add(id);
}

class _FakeDisputeService extends DisputeService {
  _FakeDisputeService(this.dispute)
    : super(auth: _Auth(), firestore: _Firestore(), clock: () => testNow);
  final Dispute? dispute;

  @override
  Stream<Dispute?> watchDispute(String bookingId) => Stream.value(dispute);

  @override
  Stream<List<DisputePhoto>> watchPhotos(String bookingId) =>
      Stream.value(const []);
}

void main() {
  AppNotification note({
    String type = AppNotification.disputeType,
    bool read = false,
  }) => AppNotification(
    id: 'n1',
    recipientId: 'customer',
    type: type,
    bookingId: 'b1',
    title: 'Dispute under review',
    body: 'The safety desk is reviewing your dispute.',
    read: read,
    createdAt: DateTime(2026, 10, 9),
  );

  testWidgets(
    'renders dispute notification with icon, marks read, and opens dispute on tap',
    (tester) async {
      final b = booking(id: 'b1');
      final disp = Dispute(
        id: 'b1',
        bookingId: 'b1',
        customerId: 'customer',
        providerId: 'pro',
        reason: 'Poor work quality',
        description: 'Breaker issues',
        status: DisputeStatus.underReview,
        photoCount: 0,
        serviceName: 'AC Cleaning',
        customerName: 'Dilshan',
        providerName: 'Nuwan',
        bookingRef: 'BK-001',
      );
      DisputeScreen.serviceFactory = () => _FakeDisputeService(disp);
      addTearDown(() => DisputeScreen.serviceFactory = DisputeService.new);

      final service = _Notifications([note()]);
      final bookings = FakeBookingService(bookings: [b]);

      await pumpCustomer(
        tester,
        CustomerNotificationsScreen(service: service),
        bookings: bookings,
      );

      expect(find.text('Dispute under review'), findsOneWidget);
      expect(
        find.text('The safety desk is reviewing your dispute.'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);

      await tester.tap(find.text('Dispute under review'));
      await tester.pumpAndSettle();

      expect(service.read, contains('n1'));
      expect(find.byType(DisputeScreen), findsOneWidget);
    },
  );

  testWidgets('shows empty state when notifications list is empty', (
    tester,
  ) async {
    final service = _Notifications(const []);

    await pumpCustomer(
      tester,
      CustomerNotificationsScreen(service: service),
    );

    expect(find.text('No notifications yet'), findsOneWidget);
  });
}
