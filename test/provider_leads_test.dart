import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/screens/provider/provider_dashboard_screen.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/utils/formatters.dart';

const _provider = AppUser(
  uid: 'pro',
  name: 'Yash',
  email: 'yash@homecare.test',
  role: AppUser.providerRole,
);

Booking job(
  String id,
  BookingStatus status, {
  String service = 'Plumber',
  DateTime? at,
  double? price = 2500,
}) => Booking(
  id: id,
  customerId: 'customer',
  providerId: 'pro',
  serviceName: service,
  customerName: 'Neshan',
  address: 'No 10 Galle Rd, Colombo 03',
  status: status,
  scheduledAt: at ?? DateTime.now().add(const Duration(days: 1)),
  totalAmount: price,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<Booking> bookings, {
    ValueChanged<Booking>? onOpen,
    VoidCallback? onViewJobs,
    Size size = const Size(390, 2400),
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
          body: ProviderDashboardScreen(
            user: _provider,
            bookings: bookings,
            onOpen: onOpen ?? (_) {},
            onViewJobs: onViewJobs ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the banner greets the provider and the stats show the month', (
    tester,
  ) async {
    await pump(tester, [job('r', BookingStatus.pending)]);
    expect(find.text('Hello, Yash'), findsOneWidget);
    expect(find.text('👋'), findsOneWidget);
    expect(find.text('Your work, all in one place.'), findsOneWidget);
    final now = DateTime.now();
    expect(find.text('${Formatters.month(now)} ${now.year}'), findsOneWidget);
    expect(find.text('LKR 0'), findsOneWidget);
  });

  testWidgets('new requests show how many there are next to View all', (
    tester,
  ) async {
    var viewed = 0;
    await pump(tester, [
      job('a', BookingStatus.pending),
      job('b', BookingStatus.pending, service: 'Electrician'),
    ], onViewJobs: () => viewed++);
    expect(find.text('View all'), findsOneWidget);
    expect(find.text(' (2)'), findsOneWidget);
    await tester.tap(find.text('View all'));
    expect(viewed, 1);
  });

  testWidgets('a request card shows who, when, where, the amount and opens', (
    tester,
  ) async {
    Booking? opened;
    final request = job('r', BookingStatus.pending);
    await pump(tester, [request], onOpen: (b) => opened = b);
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.text('Neshan'), findsOneWidget);
    expect(find.text('No 10 Galle Rd, Colombo 03'), findsOneWidget);
    expect(find.text('LKR 2,500'), findsOneWidget);
    expect(find.text('New request'), findsOneWidget);
    await tester.tap(find.text('View request'));
    expect(opened?.id, 'r');
  });

  testWidgets('an upcoming job card says Confirmed and opens its details', (
    tester,
  ) async {
    Booking? opened;
    await pump(tester, [
      job('c', BookingStatus.confirmed),
    ], onOpen: (b) => opened = b);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    await tester.tap(find.text('View details'));
    expect(opened?.id, 'c');
  });

  testWidgets('a job without a price says so instead of showing zero', (
    tester,
  ) async {
    await pump(tester, [job('p', BookingStatus.pending, price: null)]);
    expect(find.text('Not provided'), findsOneWidget);
  });

  testWidgets('empty states stay when there are no jobs', (tester) async {
    await pump(tester, const []);
    expect(find.text('No upcoming jobs yet'), findsOneWidget);
    expect(find.text('No new job requests'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    // No count when there is nothing to count.
    expect(find.textContaining('('), findsNothing);
  });

  testWidgets('cards fit a narrow phone at double text size', (tester) async {
    await pump(
      tester,
      [job('c', BookingStatus.confirmed), job('r', BookingStatus.pending)],
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
