import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/services/provider_booking_service.dart';
import 'package:home_service_bookin_app/screens/provider/provider_job_actions.dart';
import 'package:home_service_bookin_app/screens/provider/provider_job_details_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_theme.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _Service extends ProviderBookingService {
  _Service({this.onAccept}) : super(auth: _Auth(), firestore: _Firestore());
  final VoidCallback? onAccept;
  int declines = 0;
  int completions = 0;
  @override
  Future<void> accept(String id) async {
    onAccept?.call();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  @override
  Future<void> decline(String id) async {
    declines++;
  }

  @override
  Future<void> complete(String id) async {
    completions++;
  }
}

Booking job(BookingStatus status) => Booking(
  id: 'booking',
  customerId: 'customer',
  providerId: 'provider',
  serviceName: 'Test service',
  customerName: 'Test customer',
  address: 'Test address',
  status: status,
  estimatedPrice: 2500,
);

void main() {
  testWidgets('accept success survives realtime pending-to-confirmed rebuild', (
    tester,
  ) async {
    final current = ValueNotifier(job(BookingStatus.pending));
    addTearDown(current.dispose);
    BookingStatus? result;
    final service = _Service(
      onAccept: () => current.value = job(BookingStatus.confirmed),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ProviderTheme.data,
        home: Scaffold(
          body: ValueListenableBuilder<Booking>(
            valueListenable: current,
            builder: (context, booking, _) => ProviderJobDetailsScreen(
              booking: booking,
              service: service,
              onChanged: (status) => result = status,
              onPayment: () {},
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(result, BookingStatus.confirmed);
    expect(find.text('Job accepted.'), findsOneWidget);
    expect(find.text('Job completion / payment'), findsOneWidget);
    expect(find.text('Mark Job Complete'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('decline cancellation performs no write; confirm performs one', (
    tester,
  ) async {
    final service = _Service();
    BookingStatus? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ProviderTheme.data,
        home: Scaffold(
          body: ProviderJobActions(
            booking: job(BookingStatus.pending),
            service: service,
            onChanged: (status) => result = status,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Decline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Decline this job request?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.declines, 0);
    expect(result, isNull);
    await tester.tap(find.text('Decline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Confirm Decline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.declines, 1);
    expect(result, BookingStatus.declined);
    expect(find.text('Job request declined.'), findsOneWidget);
  });

  testWidgets('completion requires confirmation and reports completed status', (
    tester,
  ) async {
    final service = _Service();
    BookingStatus? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ProviderTheme.data,
        home: Scaffold(
          body: ProviderJobActions(
            booking: job(BookingStatus.confirmed),
            service: service,
            onChanged: (status) => result = status,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mark Job Complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.completions, 0);
    await tester.tap(find.text('Mark Complete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.completions, 1);
    expect(result, BookingStatus.completed);
  });
}
