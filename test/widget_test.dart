// Customer shell smoke test (replaces the original Flutter counter template,
// which no longer matched the app).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_details_screen.dart';
import 'package:home_service_bookin_app/screens/customer/customer_home_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

void main() {
  testWidgets('bottom navigation keeps detail screens inside each tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CustomerHomeScreen(
          user: testUser,
          authService: AuthService(auth: _Auth(), firestore: _Db()),
          addressService: FakeAddressService([address(isDefault: true)]),
          bookingService: FakeBookingService(bookings: [booking()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nav = find.byType(NavigationBar);
    expect(nav, findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Booking History'), findsOneWidget);

    await tester.tap(find.text('AC Deep Clean & Servicing'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingDetailsScreen), findsOneWidget);
    expect(nav, findsOneWidget, reason: 'details stay inside the shell');

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('My Addresses'), findsOneWidget);

    // Returning to Bookings restores the open details screen; tapping the
    // active tab again pops back to its root.
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingDetailsScreen), findsOneWidget);
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingDetailsScreen), findsNothing);
    expect(find.text('Booking History'), findsOneWidget);
  });
}
