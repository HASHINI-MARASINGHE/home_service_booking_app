import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/address.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/receipt.dart';
import 'package:home_service_bookin_app/models/refund.dart';
import 'package:home_service_bookin_app/screens/customer/addresses/address_form_screen.dart';
import 'package:home_service_bookin_app/screens/customer/addresses/my_addresses_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_cancelled_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_details_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_history_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/edit_booking_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/receipt_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/reschedule_booking_screen.dart';
import 'package:home_service_bookin_app/screens/customer/customer_scope.dart';

import 'support/customer_fakes.dart';

Receipt receipt() => Receipt.fromMap('done', {
  'receiptNumber': 'INV-2024-8841',
  'bookingReference': 'BK-78924',
  'providerName': 'Nuwan Fernando',
  'providerTitle': 'AC Maintenance Specialist',
  'licenseNumber': 'LK-AC-409',
  'customerName': 'Dilshan Perera',
  'serviceAddress': 'No. 42 Galle Road, Colombo 03',
  'paymentMethod': 'card',
  'cardLast4': '8821',
  'paymentStatus': 'paid',
  'paymentNote': 'Released from escrow after sign-off.',
  'lineItems': [
    {'label': 'Base AC Deep Clean', 'detail': '2 units', 'amount': 4500},
    {'label': 'Replacement Capacitor & Filter', 'amount': 6200},
    {'label': 'VAT / Municipality Taxes', 'amount': 800},
  ],
  'totalAmount': 11500,
});

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('My Addresses', () {
    testWidgets('empty list shows the saved-address empty state', (
      tester,
    ) async {
      await pumpCustomer(tester, const MyAddressesScreen());
      expect(find.text('No Saved Addresses'), findsOneWidget);
      expect(find.text('Add Your First Address'), findsOneWidget);
      expect(find.text('Use Current GPS Location'), findsOneWidget);
      expect(find.text('Popular Service Zones'.toUpperCase()), findsOneWidget);
    });

    testWidgets('lists addresses, filters by category and searches', (
      tester,
    ) async {
      final service = FakeAddressService([
        address(isDefault: true),
        address(
          id: 'office',
          type: AddressType.office,
          label: 'Office • WTC',
          city: 'Colombo 01',
        ),
        address(id: 'parents', type: AddressType.parents, label: "Parents'"),
      ]);
      await pumpCustomer(tester, const MyAddressesScreen(), addresses: service);
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Rapid dispatch ready'), findsOneWidget);

      await tester.ensureVisible(find.text('Workplace'));
      await tester.tap(find.text('Workplace'));
      await tester.pumpAndSettle();
      expect(find.text('Office • WTC'), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      await tester.ensureVisible(find.text('All (3)'));
      await tester.tap(find.text('All (3)'));
      await tester.enterText(find.byType(TextField), 'colombo 01');
      await tester.pumpAndSettle();
      expect(find.text('Office • WTC'), findsOneWidget);
      expect(find.text("Parents'"), findsNothing);
    });

    testWidgets('delete warns about a linked booking, then deletes', (
      tester,
    ) async {
      final service = FakeAddressService([
        address(id: 'office', type: AddressType.office, label: 'Office'),
      ])..linked['office'] = [booking(addressId: 'office')];
      await pumpCustomer(tester, const MyAddressesScreen(), addresses: service);
      await tester.tap(find.byTooltip('Delete Office'));
      await tester.pumpAndSettle();
      expect(find.text("Delete 'Office' address?"), findsOneWidget);
      expect(find.text('ACTIVE BOOKING LINKED'), findsOneWidget);

      await tester.tap(find.text('Cancel & Keep Address'));
      await tester.pumpAndSettle();
      expect(service.deleted, isEmpty);

      await tester.tap(find.byTooltip('Delete Office'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Delete Address'));
      await tester.pumpAndSettle();
      expect(service.deleted, ['office']);
      expect(find.text('No Saved Addresses'), findsOneWidget);
    });

    testWidgets('a blocked delete shows the server reason in the sheet', (
      tester,
    ) async {
      final service = FakeAddressService([address()])
        ..deleteError = StateError('A professional is already on the way.');
      await pumpCustomer(tester, const MyAddressesScreen(), addresses: service);
      await tester.tap(find.byTooltip('Delete Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Delete Address'));
      await tester.pumpAndSettle();
      expect(
        find.text('A professional is already on the way.'),
        findsOneWidget,
      );
      expect(service.items, hasLength(1));
    });
  });

  group('Add address form', () {
    testWidgets('validates required fields and saves parsed values', (
      tester,
    ) async {
      final service = FakeAddressService();
      await pumpCustomer(tester, const AddressFormScreen(), addresses: service);
      expect(find.text('Add New Address'), findsOneWidget);
      await scrollTo(tester, find.text('Save Address'));
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the street name.'), findsOneWidget);
      expect(service.created, isNull);

      Finder field(String hint) => find.widgetWithText(TextFormField, hint);
      await tester.ensureVisible(find.text('Office'));
      await tester.tap(find.text('Office'));
      await tester.enterText(field('No. 42, Apt 4B'), 'Level 14');
      await tester.enterText(field('Galle Road'), 'Echelon Square');
      await tester.enterText(field('Colombo 03 (00300)'), 'Colombo 01 (00100)');
      await scrollTo(tester, find.text('Save Address'));
      await tester.tap(find.text('Save Address'));
      await tester.pumpAndSettle();
      expect(service.created?.type, AddressType.office);
      expect(service.created?.city, 'Colombo 01');
      expect(service.created?.postalCode, '00100');
    });
  });

  group('Booking History', () {
    testWidgets('no bookings shows the empty state and Find a Service', (
      tester,
    ) async {
      final tabs = await pumpCustomer(tester, const BookingHistoryScreen());
      expect(find.text('Upcoming (0)'), findsOneWidget);
      expect(find.text('Past & Completed (0)'), findsOneWidget);
      expect(find.text('No Bookings Yet'), findsOneWidget);
      await tester.tap(find.text('Find a Service →'));
      expect(tabs, [CustomerTab.home]);
    });

    testWidgets('splits upcoming and past bookings', (tester) async {
      await pumpCustomer(
        tester,
        const BookingHistoryScreen(),
        bookings: FakeBookingService(
          bookings: [
            booking(),
            booking(
              id: 'old',
              status: BookingStatus.completed,
              serviceName: 'Inverter AC Repair',
            ),
          ],
        ),
      );
      expect(find.text('Upcoming (1)'), findsOneWidget);
      expect(find.text('AC Deep Clean & Servicing'), findsOneWidget);
      expect(find.text('Inverter AC Repair'), findsNothing);
      await tester.tap(find.text('Past & Completed (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Inverter AC Repair'), findsOneWidget);
      expect(find.text('View receipt'), findsOneWidget);
    });
  });

  group('Booking Details', () {
    testWidgets('renders backend status, professional and payment', (
      tester,
    ) async {
      await pumpCustomer(
        tester,
        const BookingDetailsScreen(bookingId: 'b1'),
        bookings: FakeBookingService(bookings: [booking()]),
      );
      expect(find.text('Code #BK-B1'), findsOneWidget);
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('Nuwan Fernando'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      await scrollTo(tester, find.text('Payment Status: In Escrow'));
      expect(find.text('LKR 5,500'), findsOneWidget);
      await scrollTo(tester, find.text('Cancel Booking'));
      expect(find.text('Reschedule Booking'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);
    });

    testWidgets('completed booking offers receipt instead of changes', (
      tester,
    ) async {
      await pumpCustomer(
        tester,
        const BookingDetailsScreen(bookingId: 'b1'),
        bookings: FakeBookingService(
          bookings: [booking(status: BookingStatus.completed)],
        ),
      );
      await scrollTo(tester, find.text('View Receipt'));
      expect(find.text('Reschedule Booking'), findsNothing);
      expect(find.text('Cancel Booking'), findsNothing);
    });

    testWidgets('cancel flow: reason → confirm sheet → cancelled screen', (
      tester,
    ) async {
      final service = FakeBookingService(bookings: [booking()]);
      await pumpCustomer(
        tester,
        const BookingDetailsScreen(bookingId: 'b1'),
        bookings: service,
      );
      await scrollTo(tester, find.text('Cancel Booking'));
      await tester.tap(find.text('Cancel Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Free cancellation'), findsOneWidget);

      await tester.tap(find.text('Booked by mistake'));
      await tester.pumpAndSettle();
      await scrollTo(
        tester,
        find.widgetWithText(FilledButton, 'Cancel Booking'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this booking?'), findsOneWidget);
      expect(find.text('Instant refund authorization'), findsOneWidget);

      await tester.tap(find.text('Yes, Cancel Booking'));
      await tester.pumpAndSettle();
      expect(service.cancelled, {'b1': 'Booked by mistake'});
      expect(find.byType(BookingCancelledScreen), findsOneWidget);
      expect(find.text('LKR 5,500'), findsWidgets);
      expect(find.text('REF-123456'), findsOneWidget);
    });
  });

  group('Reschedule', () {
    testWidgets('shows slot states and confirms a free slot', (tester) async {
      final service = FakeBookingService(bookings: [booking()]);
      service.locks['2025-11-13'] = {'10:30': 'b1', '15:30': 'other'};
      await pumpCustomer(
        tester,
        RescheduleBookingScreen(booking: booking(), professional: professional),
        bookings: service,
      );
      await scrollTo(tester, find.text('Select a new time'));
      await scrollTo(tester, find.text('03:30 PM – 05:00 PM'));
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);

      await scrollTo(tester, find.text('01:30 PM – 03:00 PM'));
      await tester.tap(find.text('01:30 PM – 03:00 PM'));
      await tester.pumpAndSettle();
      expect(find.text('Nuwan confirmed available'), findsOneWidget);
      final confirm = find.text('Confirm New Time — Thu 13 Nov, 1:30 PM');
      await scrollTo(tester, confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(service.rescheduled['b1']?.start, '13:30');
    });
  });

  group('Edit booking', () {
    testWidgets('prefills booking details and counts access notes', (
      tester,
    ) async {
      await pumpCustomer(tester, EditBookingScreen(booking: booking()));
      expect(find.text('Edit Booking Details'), findsOneWidget);
      expect(find.text('077 123 4567'), findsOneWidget);
      expect(find.text('24/200'), findsOneWidget);
    });
  });

  group('Receipt and refund', () {
    testWidgets('receipt shows itemized backend data', (tester) async {
      await pumpCustomer(
        tester,
        const ReceiptScreen(bookingId: 'b1'),
        bookings: FakeBookingService(
          bookings: [booking(status: BookingStatus.completed)],
          receipt: receipt(),
        ),
      );
      expect(find.text('INV-2024-8841'), findsOneWidget);
      expect(find.text('Lic #LK-AC-409'), findsOneWidget);
      await scrollTo(tester, find.text('LKR 11,500'));
      expect(find.text('3 Items'), findsOneWidget);
    });

    testWidgets('missing receipt shows a not-issued state', (tester) async {
      await pumpCustomer(
        tester,
        const ReceiptScreen(bookingId: 'b1'),
        bookings: FakeBookingService(bookings: [booking()]),
      );
      expect(find.text('Receipt not issued yet'), findsOneWidget);
    });

    testWidgets('refund tracker reflects backend refund status', (
      tester,
    ) async {
      final service = FakeBookingService(
        bookings: [booking(status: BookingStatus.cancelled)],
        refund: Refund(
          bookingId: 'b1',
          amount: 5500,
          status: RefundStatus.processing,
          refundReference: 'REF-992014',
          gateway: 'PayHere',
          bankName: 'Commercial Bank of Ceylon',
          createdAt: testNow,
        ),
      );
      await pumpCustomer(
        tester,
        const BookingCancelledScreen(bookingId: 'b1'),
        bookings: service,
      );
      expect(find.text('100% Full Refund'), findsOneWidget);
      await scrollTo(tester, find.text('Refunded to Bank'));
      expect(find.text('In Progress'), findsOneWidget);
      expect(
        find.textContaining('via PayHere Gateway to Commercial Bank'),
        findsOneWidget,
      );
    });
  });

  group('Small phones (320 × 640) render without overflow', () {
    final small = const Size(320, 640);
    final cases = <String, (Widget, FakeBookingService)>{
      'details': (
        const BookingDetailsScreen(bookingId: 'b1'),
        FakeBookingService(bookings: [booking()]),
      ),
      'history': (
        const BookingHistoryScreen(),
        FakeBookingService(bookings: [booking()]),
      ),
      'empty history': (const BookingHistoryScreen(), FakeBookingService()),
      'reschedule': (
        RescheduleBookingScreen(booking: booking(), professional: professional),
        FakeBookingService(bookings: [booking()]),
      ),
      'edit': (EditBookingScreen(booking: booking()), FakeBookingService()),
      'receipt': (
        const ReceiptScreen(bookingId: 'b1'),
        FakeBookingService(
          bookings: [booking(status: BookingStatus.completed)],
          receipt: receipt(),
        ),
      ),
    };
    for (final MapEntry(key: name, value: (screen, service)) in cases.entries) {
      testWidgets(name, (tester) async {
        await pumpCustomer(tester, screen, bookings: service, size: small);
        // Scroll through the whole page so every section lays out.
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 12; i++) {
          await tester.drag(scrollable, const Offset(0, -400));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('addresses', (tester) async {
      await pumpCustomer(
        tester,
        const MyAddressesScreen(),
        addresses: FakeAddressService([
          address(isDefault: true),
          address(
            id: 'o',
            type: AddressType.office,
            label: 'Office • World Trade Center',
          ),
        ]),
        size: small,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
