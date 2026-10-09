import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/screens/provider/provider_earnings_screen.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

Booking job(
  String id, {
  required DateTime completedAt,
  double labor = 2000,
  String payment = 'paid',
  String name = 'AC Deep Clean',
}) => Booking(
  id: id,
  customerId: 'customer',
  providerId: 'pro',
  serviceName: name,
  customerName: 'Dilshan Perera',
  address: 'No. 42 Galle Road, Colombo 03',
  status: BookingStatus.completed,
  paymentStatus: payment,
  laborCharge: labor,
  completedAt: completedAt,
);

void main() {
  final now = DateTime.now();
  // A paid job done this month, a paid job from last year, and a completed
  // job that was never paid (counted as completed, but not as earnings).
  final thisMonth = job('m', completedAt: now, name: 'AC Deep Clean');
  final lastYear = job(
    'y',
    completedAt: DateTime(now.year - 1, 6, 15),
    labor: 1000,
    name: 'Switchboard Repair',
  );
  final unpaid = job('u', completedAt: now, payment: 'unpaid');

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  Future<void> pump(
    WidgetTester tester,
    List<Booking> bookings, {
    ValueChanged<Booking>? onOpen,
    VoidCallback? onExploreLeads,
    Size size = const Size(390, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        ProviderEarningsScreen(
          bookings: bookings,
          onOpen: onOpen ?? (_) {},
          onExploreLeads: onExploreLeads,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('earnings-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('with no paid jobs it shows zero and an empty state', (
    tester,
  ) async {
    var explored = 0;
    await pump(tester, const [], onExploreLeads: () => explored++);
    expect(find.text("THIS MONTH'S EARNINGS"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('month-total')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(find.text('.00'), findsOneWidget);
    expect(find.text('Completed & paid jobs only'), findsOneWidget);
    expect(find.text('No earnings yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('explore-leads')));
    expect(explored, 1);
  });

  testWidgets('the empty state has no leads button without a destination', (
    tester,
  ) async {
    await pump(tester, const []);
    expect(find.byKey(const ValueKey('explore-leads')), findsNothing);
  });

  testWidgets('shows only what the app really knows', (tester) async {
    await pump(tester, const []);
    // Mock-up figures that have no data behind them are not shown.
    expect(find.textContaining('Tuesday'), findsNothing);
    expect(find.textContaining('On Time'), findsNothing);
    expect(find.textContaining('Commercial Bank'), findsNothing);
    expect(find.textContaining('12%'), findsNothing);
  });

  testWidgets('totals count completed and paid jobs only', (tester) async {
    await pump(tester, [thisMonth, lastYear, unpaid]);
    // This month: 2,000. All time: 3,000 over 3 completed jobs.
    expect(find.text('2,000'), findsOneWidget);
    expect(find.text('LKR 3,000'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('completed-jobs'))).data,
      '3',
    );
    expect(find.text('No earnings yet'), findsNothing);
  });

  testWidgets('the list follows This Month, This Year and All Time', (
    tester,
  ) async {
    await pump(tester, [thisMonth, lastYear]);
    // Default is This Year: only the job done this year.
    expect(find.text('This Year'), findsOneWidget);
    expect(find.text('AC Deep Clean'), findsOneWidget);
    expect(find.text('Switchboard Repair'), findsNothing);

    await choose(tester, 'All Time');
    expect(find.text('AC Deep Clean'), findsOneWidget);
    expect(find.text('Switchboard Repair'), findsOneWidget);

    await choose(tester, 'This Month');
    expect(find.text('AC Deep Clean'), findsOneWidget);
    expect(find.text('Switchboard Repair'), findsNothing);
  });

  testWidgets('a period with no earnings says so, All Time shows them', (
    tester,
  ) async {
    await pump(tester, [lastYear]);
    expect(find.byKey(const ValueKey('none-in-range')), findsOneWidget);
    expect(find.text('Switchboard Repair'), findsNothing);
    await choose(tester, 'All Time');
    expect(find.byKey(const ValueKey('none-in-range')), findsNothing);
    expect(find.text('Switchboard Repair'), findsOneWidget);
  });

  testWidgets('View details opens that job', (tester) async {
    Booking? opened;
    await pump(tester, [thisMonth], onOpen: (b) => opened = b);
    await tester.tap(find.text('View details'));
    expect(opened?.id, 'm');
  });

  testWidgets('Payout cycle explains how earnings are counted', (tester) async {
    await pump(tester, const []);
    await tester.tap(find.byKey(const ValueKey('payout-cycle')));
    await tester.pumpAndSettle();
    expect(find.text('Earnings & Payouts'), findsOneWidget);
    expect(find.text('Completed and paid'), findsOneWidget);
    expect(
      find.text('Labor charge, or total less the service fee'),
      findsOneWidget,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Earnings & Payouts'), findsNothing);
  });

  testWidgets('Total earnings jumps to the recent earnings', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 8; i++) job('j$i', completedAt: now),
    ], size: const Size(390, 700));
    await tester.tap(find.byKey(const ValueKey('total-earnings')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Recent earnings'), findsOneWidget);
  });

  testWidgets('a big amount fits a narrow phone', (tester) async {
    await pump(tester, [
      job('big', completedAt: now, labor: 123456789),
    ], size: const Size(320, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('123,456,789'), findsOneWidget);
  });
}
