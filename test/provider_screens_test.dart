import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/screens/provider/provider_dashboard_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_jobs_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_earnings_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_theme.dart';

const user = AppUser(
  uid: 'provider',
  name: 'Test Provider',
  email: 'provider@example.com',
  role: 'provider',
);

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: ProviderTheme.data,
    home: Scaffold(body: child),
  );

  testWidgets('new provider sees zeros and useful empty states', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ProviderDashboardScreen(
          user: user,
          bookings: const [],
          onOpen: (_) {},
          onViewJobs: () {},
        ),
      ),
    );
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('LKR 0'), findsOneWidget);
    expect(find.text('No upcoming jobs yet'), findsOneWidget);
    expect(find.text('No new job requests'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'job sections filter requests, confirmed and historical records',
    (tester) async {
      final bookings =
          [
                BookingStatus.pending,
                BookingStatus.confirmed,
                BookingStatus.declined,
                BookingStatus.completed,
                BookingStatus.cancelled,
              ]
              .map(
                (status) => Booking(
                  id: status.name,
                  customerId: 'customer',
                  providerId: 'provider',
                  serviceName: 'Service ${status.name}',
                  customerName: 'Customer',
                  address: 'Address',
                  status: status,
                ),
              )
              .toList();
      for (var tab = 0; tab < 3; tab++) {
        await tester.pumpWidget(
          app(
            ProviderJobsScreen(
              bookings: bookings,
              tab: tab,
              onTab: (_) {},
              onOpen: (_) {},
            ),
          ),
        );
        expect(
          find.text('Service pending'),
          tab == 0 ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Service confirmed'),
          tab == 1 ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Service declined'),
          tab == 2 ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Service completed'),
          tab == 2 ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Service cancelled'),
          tab == 2 ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('dashboard and earnings fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        ProviderDashboardScreen(
          user: user,
          bookings: const [],
          onOpen: (_) {},
          onViewJobs: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(ProviderEarningsScreen(bookings: const [], onOpen: (_) {})),
    );
    expect(find.text('No earnings yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(
        ProviderJobsScreen(
          bookings: const [],
          tab: 0,
          onTab: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
