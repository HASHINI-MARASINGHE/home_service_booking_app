import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/address.dart';
import 'package:home_service_bookin_app/models/professional.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_details_screen.dart';
import 'package:home_service_bookin_app/screens/customer/customer_home_screen.dart';
import 'package:home_service_bookin_app/screens/customer/providers/all_providers_screen.dart';
import 'package:home_service_bookin_app/screens/customer/providers/book_service_screen.dart';
import 'package:home_service_bookin_app/screens/customer/providers/provider_details_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/widgets/common/app_bottom_nav.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

const newcomer = Professional(id: 'new', name: 'Amali Perera');

Widget details() => const ProviderDetailsScreen(providerId: 'pro');

void main() {
  testWidgets('provider profile shows the real listing fields', (tester) async {
    await pumpCustomer(
      tester,
      Material(child: details()),
      size: const Size(390, 1800),
    );
    expect(find.text('Nuwan Fernando'), findsOneWidget);
    expect(
      find.text('Licensed Air Conditioning & Electrical Specialist'),
      findsOneWidget,
    );
    expect(find.text('Colombo 03'), findsOneWidget);
    expect(find.text('8+ Years Experience'), findsOneWidget);
    expect(
      find.text('Certified AC and electrical technician.'),
      findsOneWidget,
    );
    expect(find.text('Electrical Repair'), findsOneWidget);
    expect(find.text('From LKR 2,500'), findsNWidgets(2));
    expect(
      find.text('From LKR 2,500 (estimate, final price quoted per job)'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('128 jobs completed'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Verified professional'), findsOneWidget);
  });

  testWidgets('Book Now opens Book Service for this provider', (tester) async {
    await pumpCustomer(tester, Scaffold(body: details()));
    await tester.tap(find.text('Book Now'));
    await tester.pumpAndSettle();
    expect(find.byType(BookServiceScreen), findsOneWidget);
    expect(find.text('Electrical Repair'), findsOneWidget);
    expect(find.text('Nuwan Fernando'), findsOneWidget);
  });

  group('Book Service', () {
    Future<FakeBookingService> pumpBook(
      WidgetTester tester, {
      Professional pro = professional,
      List<Address>? addresses,
      Size size = const Size(390, 844),
    }) async {
      final bookings = FakeBookingService(professionals: [pro]);
      await pumpCustomer(
        tester,
        Scaffold(body: BookServiceScreen(professional: pro)),
        bookings: bookings,
        addresses: FakeAddressService(addresses ?? [address(isDefault: true)]),
        size: size,
      );
      return bookings;
    }

    testWidgets('shows the real service, provider, address and price', (
      tester,
    ) async {
      await pumpBook(tester);
      expect(find.text('Electrical Repair'), findsOneWidget);
      expect(
        find.text('Verified Air Conditioning & Electrical Specialist'),
        findsOneWidget,
      );
      expect(find.text('4.9 ★ • 128 jobs'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      // The price is quoted per job: the starting price is only an estimate.
      expect(find.byKey(const ValueKey('price-quote-pending')), findsOneWidget);
      expect(
        find.text(
          'Provider estimate: from LKR 2,500 (final price quoted per job).',
        ),
        findsOneWidget,
      );
      expect(find.text(address().line), findsOneWidget);
      expect(
        find.textContaining('09:00 AM'),
        findsNothing,
        reason: 'uses real slots',
      );
      expect(find.textContaining('08:30 AM –'), findsOneWidget);
    });

    testWidgets('confirm needs a time, then sends the booking', (tester) async {
      final bookings = await pumpBook(tester);
      await tester.ensureVisible(find.textContaining('Confirm Booking'));
      await tester.tap(find.textContaining('Confirm Booking'));
      await tester.pump();
      expect(find.text('Select a time.'), findsOneWidget);
      expect(bookings.created, isEmpty);
      // Let the snack bar go away so it does not cover the button.
      ScaffoldMessenger.of(tester.element(find.byType(BookServiceScreen)))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('01:30 PM –'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('01:30 PM –'));
      await tester.pump();
      await tester.tap(find.textContaining('Confirm Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Check your booking'), findsOneWidget);
      await tester.tap(find.text('Send booking request'));
      await tester.pumpAndSettle();
      expect(find.text('Booking request sent'), findsOneWidget);
      await tester.tap(find.text('View my booking'));
      await tester.pumpAndSettle();
      final request = bookings.created.single;
      expect(request.professional.id, 'pro');
      expect(request.serviceName, 'Electrical Repair');
      expect(request.slot.start, '13:30');
      expect(request.address.id, 'home');
      expect(request.customerName, testUser.name);
      expect(find.byType(BookingDetailsScreen), findsOneWidget);
    });

    testWidgets('service can be changed when the provider offers several', (
      tester,
    ) async {
      final bookings = await pumpBook(tester);
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC Servicing').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('01:30 PM –'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('01:30 PM –'));
      await tester.pump();
      await tester.tap(find.textContaining('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send booking request'));
      await tester.pumpAndSettle();
      expect(bookings.created.single.serviceName, 'AC Servicing');
    });

    testWidgets(
      'no base price still books as a pending quote; no address asks to add one',
      (tester) async {
        await pumpBook(
          tester,
          pro: const Professional(
            id: 'pro',
            name: 'Amali Perera',
            specialty: 'Plumber',
          ),
          addresses: [],
        );
        expect(find.text('Plumber'), findsWidgets);
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('price-quote-pending')),
          findsOneWidget,
        );
        expect(find.textContaining('Provider estimate'), findsNothing);
        expect(find.text('On inspection'), findsNothing);
        expect(find.text('LKR 0'), findsNothing);
        expect(find.text('Add a service address'), findsOneWidget);
      },
    );

    testWidgets('fits a 320 × 640 phone', (tester) async {
      await pumpBook(tester, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a provider without details shows friendly fallbacks', (
    tester,
  ) async {
    await pumpCustomer(
      tester,
      const Material(child: ProviderDetailsScreen(providerId: 'new')),
      bookings: FakeBookingService(professionals: [newcomer]),
    );
    expect(find.text('About'), findsNothing);
    expect(find.text('Services'), findsNothing);
    expect(find.text('No ratings yet'), findsOneWidget);
  });

  testWidgets('all providers list searches by name and service', (
    tester,
  ) async {
    await pumpCustomer(
      tester,
      const Material(child: AllProvidersScreen()),
      bookings: FakeBookingService(professionals: [professional, newcomer]),
    );
    expect(find.text('Nuwan Fernando'), findsOneWidget);
    expect(find.text('Amali Perera'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ac servicing');
    await tester.pumpAndSettle();
    expect(find.text('Nuwan Fernando'), findsOneWidget);
    expect(find.text('Amali Perera'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No providers match "zzz".'), findsOneWidget);
  });

  testWidgets('home avatar and See all open provider pages inside the tab', (
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
          addressService: FakeAddressService(),
          bookingService: FakeBookingService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The home screen lists the verified providers as cards.
    await tester.ensureVisible(find.text('Nuwan Fernando'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuwan Fernando'));
    await tester.pumpAndSettle();
    expect(find.byType(ProviderDetailsScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('see-all-providers')));
    await tester.pumpAndSettle();
    expect(find.byType(AllProvidersScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);

    await tester.tap(find.text('Nuwan Fernando'));
    await tester.pumpAndSettle();
    expect(find.byType(ProviderDetailsScreen), findsOneWidget);
  });

  for (final screen in [details(), const AllProvidersScreen()]) {
    testWidgets('${screen.runtimeType} fits a 320 × 640 phone', (tester) async {
      await pumpCustomer(
        tester,
        Material(child: screen),
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
