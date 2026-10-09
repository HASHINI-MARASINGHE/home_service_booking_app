import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/screens/provider/provider_jobs_screen.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

Booking job(
  String id,
  BookingStatus status, {
  String service = 'Plumber',
  String customer = 'Neshan Perera',
  double? price = 2500,
  String payment = 'unpaid',
  String phone = '',
  String notes = '',
  Duration? length = const Duration(minutes: 90),
  int daysAhead = 1,
}) {
  final start = DateTime.now().add(Duration(days: daysAhead));
  return Booking(
    id: id,
    customerId: 'customer',
    providerId: 'pro',
    serviceName: service,
    customerName: customer,
    address: 'No 10, Galle Road, Colombo 03',
    addressArea: 'Western Province',
    status: status,
    scheduledAt: start,
    endAt: length == null ? null : start.add(length),
    totalAmount: price,
    paymentStatus: payment,
    contactPhone: phone,
    jobNotes: notes,
  );
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<Booking> bookings, {
    int tab = 0,
    ValueChanged<int>? onTab,
    ValueChanged<Booking>? onOpen,
    Size size = const Size(390, 3000),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: ProviderJobsScreen(
            bookings: bookings,
            tab: tab,
            onTab: onTab ?? (_) {},
            onOpen: onOpen ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final mixed = [
    job('r1', BookingStatus.pending),
    job('r2', BookingStatus.pending, service: 'Electrician'),
    job('c1', BookingStatus.confirmed, phone: '+94771234567'),
    job(
      'h1',
      BookingStatus.completed,
      payment: 'paid',
      notes: 'Pipe repair finished with a leak check.',
      daysAhead: -2,
    ),
    job('h2', BookingStatus.cancelled, price: null, daysAhead: -1),
  ];

  group('tabs', () {
    testWidgets('show how many requests and confirmed jobs there are', (
      tester,
    ) async {
      await pump(tester, mixed);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('jobs-count-0')),
                matching: find.byType(Text),
              ),
            )
            .data,
        '2',
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('jobs-count-1')),
                matching: find.byType(Text),
              ),
            )
            .data,
        '1',
      );
      expect(find.byKey(const ValueKey('jobs-count-2')), findsNothing);
    });

    testWidgets('tapping a tab reports its index', (tester) async {
      final taps = <int>[];
      await pump(tester, mixed, onTab: taps.add);
      await tester.tap(find.byKey(const ValueKey('jobs-tab-1')));
      await tester.tap(find.byKey(const ValueKey('jobs-tab-2')));
      expect(taps, [1, 2]);
    });

    testWidgets('no count when nothing is waiting', (tester) async {
      await pump(tester, const []);
      expect(find.byKey(const ValueKey('jobs-count-0')), findsNothing);
      expect(find.byKey(const ValueKey('jobs-count-1')), findsNothing);
    });
  });

  group('Requests', () {
    testWidgets('a request shows who, when, where, the payout and opens', (
      tester,
    ) async {
      Booking? opened;
      await pump(tester, [
        job('r1', BookingStatus.pending, notes: 'Tap and drainage repair'),
      ], onOpen: (b) => opened = b);
      expect(find.text('Plumber'), findsOneWidget);
      expect(find.text('Tap and drainage repair'), findsOneWidget);
      expect(find.text('Neshan Perera'), findsOneWidget);
      expect(find.text('No 10, Galle Road, Colombo 03'), findsOneWidget);
      expect(find.text('Western Province'), findsOneWidget);
      expect(find.text('ESTIMATED PAYOUT'), findsOneWidget);
      expect(find.text('LKR 2,500'), findsOneWidget);
      expect(find.text('Est. 1h 30m'), findsOneWidget);
      expect(find.text('New request'), findsOneWidget);
      await tester.tap(find.text('View request details'));
      expect(opened?.id, 'r1');
    });

    testWidgets('no duration when the slot has no end', (tester) async {
      await pump(tester, [job('r1', BookingStatus.pending, length: null)]);
      expect(find.textContaining('Est. '), findsNothing);
    });

    testWidgets('shows only what the app really knows', (tester) async {
      await pump(tester, mixed);
      expect(find.textContaining('km away'), findsNothing);
      expect(find.text('Verified'), findsNothing);
      expect(find.textContaining('Guarantee'), findsNothing);
    });

    testWidgets('an empty list says so', (tester) async {
      await pump(tester, const []);
      expect(find.text('No new job requests'), findsOneWidget);
    });
  });

  group('Confirmed', () {
    testWidgets('summarises the booked jobs and what they add up to', (
      tester,
    ) async {
      await pump(tester, [
        job('c1', BookingStatus.confirmed, price: 2500, daysAhead: 1),
        job(
          'c2',
          BookingStatus.confirmed,
          service: 'Electrical Repair',
          price: 3800,
          daysAhead: 2,
        ),
      ], tab: 1);
      expect(find.text('2 Jobs Booked'), findsOneWidget);
      expect(find.textContaining('Next: '), findsOneWidget);
      expect(find.text('TOTAL BOOKED'), findsOneWidget);
      expect(find.text('LKR 6,300'), findsOneWidget);
    });

    testWidgets('one job reads "1 Job Booked"', (tester) async {
      await pump(tester, [job('c1', BookingStatus.confirmed)], tab: 1);
      expect(find.text('1 Job Booked'), findsOneWidget);
    });

    testWidgets('a card shows the customer, a call button and opens', (
      tester,
    ) async {
      Booking? opened;
      await pump(
        tester,
        [job('c1', BookingStatus.confirmed, phone: '+94771234567')],
        tab: 1,
        onOpen: (b) => opened = b,
      );
      expect(find.text('NP'), findsOneWidget);
      expect(find.text('Neshan Perera'), findsOneWidget);
      expect(find.byKey(const ValueKey('call-c1')), findsOneWidget);
      expect(find.text('Confirmed'), findsWidgets);
      await tester.tap(find.text('View details'));
      expect(opened?.id, 'c1');
    });

    testWidgets('no call button without a customer phone', (tester) async {
      await pump(tester, [job('c1', BookingStatus.confirmed)], tab: 1);
      expect(find.byKey(const ValueKey('call-c1')), findsNothing);
    });

    testWidgets('no total when no job has a price', (tester) async {
      await pump(tester, [
        job('c1', BookingStatus.confirmed, price: null),
      ], tab: 1);
      expect(find.text('TOTAL BOOKED'), findsNothing);
      expect(find.text('Not provided'), findsOneWidget);
    });
  });

  group('History', () {
    testWidgets('lists past jobs with a count and an end marker', (
      tester,
    ) async {
      await pump(tester, mixed, tab: 2);
      expect(find.text('Past Jobs'), findsOneWidget);
      expect(find.text('2 Total'), findsOneWidget);
      expect(find.text('End of recorded history'), findsOneWidget);
      expect(find.text('Pipe repair finished with a leak check.'), findsOne);
    });

    testWidgets('a paid job says Amount paid, one without a price says so', (
      tester,
    ) async {
      await pump(tester, mixed, tab: 2);
      expect(find.text('AMOUNT PAID'), findsOneWidget);
      expect(find.text('FEE STATUS'), findsOneWidget);
      expect(find.text('Not provided'), findsOneWidget);
    });

    testWidgets('View details opens the job', (tester) async {
      Booking? opened;
      await pump(
        tester,
        [job('h1', BookingStatus.completed, payment: 'paid', daysAhead: -1)],
        tab: 2,
        onOpen: (b) => opened = b,
      );
      await tester.tap(find.text('View details'));
      expect(opened?.id, 'h1');
    });

    testWidgets('an empty history says so', (tester) async {
      await pump(tester, const [], tab: 2);
      expect(find.text('No job history yet'), findsOneWidget);
      expect(find.text('Past Jobs'), findsNothing);
    });
  });

  testWidgets('every tab fits a narrow phone at double text size', (
    tester,
  ) async {
    for (var tab = 0; tab < 3; tab++) {
      await pump(
        tester,
        mixed,
        tab: tab,
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
  });
}
