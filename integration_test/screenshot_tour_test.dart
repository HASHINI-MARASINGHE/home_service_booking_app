// Screenshot tour of the real app (MyApp from launch) against the seeded
// Firebase emulators. Run with test_driver/screenshot_driver.dart:
//
//   flutter drive --driver=test_driver/screenshot_driver.dart
//     --target=integration_test/screenshot_tour_test.dart -d web-server
//     --browser-dimension=400,860@2 --dart-define=FIRESTORE_EMULATOR_PORT=8085
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/firebase_options.dart';
import 'package:home_service_bookin_app/main.dart';
import 'package:integration_test/integration_test.dart';

const host = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
const firestorePort = int.fromEnvironment(
  'FIRESTORE_EMULATOR_PORT',
  defaultValue: 8080,
);

late IntegrationTestWidgetsFlutterBinding binding;

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .take(60)
      .join(' | ');
  throw TestFailure('Timed out waiting for $finder. On screen: $visible');
}

Finder get _vertical => find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

Future<void> scrollFind(WidgetTester tester, Finder finder) async {
  try {
    return await waitFor(tester, finder, timeout: const Duration(seconds: 4));
  } on TestFailure {
    // Build lazily created list items below the fold.
  }
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    if (_vertical.evaluate().isNotEmpty) {
      await tester.drag(_vertical.last, const Offset(0, -300));
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  await waitFor(tester, finder, timeout: const Duration(seconds: 1));
}

Future<void> scrollToTop(WidgetTester tester) async {
  for (var i = 0; i < 8 && _vertical.evaluate().isNotEmpty; i++) {
    await tester.drag(_vertical.last, const Offset(0, 700));
    await tester.pump(const Duration(milliseconds: 150));
  }
  await settle(tester);
}

Future<void> scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(_vertical.last, Offset(0, -dy));
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void clearSnacks() {
  for (final e in find.byType(ScaffoldMessenger).evaluate()) {
    ((e as StatefulElement).state as ScaffoldMessengerState).clearSnackBars();
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await scrollFind(tester, finder);
  await tester.ensureVisible(finder.first);
  clearSnacks();
  await settle(tester);
  await tester.tap(finder.first);
  await settle(tester);
}

Future<void> shot(WidgetTester tester, String name) async {
  clearSnacks();
  await settle(tester);
  await binding.takeScreenshot(name);
}

Future<void> login(WidgetTester tester, String email) async {
  await waitFor(tester, find.widgetWithText(TextFormField, 'Email'));
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'HomeCare@123',
  );
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(const MyApp());

    // ---- Onboarding → Login → Home
    await waitFor(tester, find.byKey(const ValueKey('onboarding-skip')));
    await shot(tester, '01_onboarding');
    await tap(tester, find.byKey(const ValueKey('onboarding-skip')));
    await login(tester, 'customer@homecare.test');
    await shot(tester, '02_login');
    await tap(tester, find.widgetWithText(FilledButton, 'Log in'));
    await waitFor(tester, find.text('Services for your home'));
    await shot(tester, '03_home');

    // ---- Booking History
    await tap(tester, find.text('Bookings'));
    await waitFor(tester, find.text('AC Deep Clean & Servicing'));
    await shot(tester, '04_booking_history_upcoming');
    await tap(tester, find.textContaining('Past & Completed'));
    await waitFor(tester, find.text('Inverter AC Repair'));
    await shot(tester, '05_booking_history_past');
    await tap(tester, find.textContaining('Upcoming ('));

    // ---- Booking Details
    await tap(tester, find.text('AC Deep Clean & Servicing'));
    await waitFor(tester, find.text('Nuwan Fernando'));
    await shot(tester, '06_booking_details_top');
    await scrollBy(tester, 650);
    await shot(tester, '07_booking_details_middle');
    await scrollFind(tester, find.text('Cancel Booking'));
    await scrollBy(tester, 400);
    await shot(tester, '08_booking_details_actions');

    // ---- Edit Booking Details
    await tap(tester, find.text('Edit Details'));
    await waitFor(tester, find.text('Edit Booking Details'));
    await shot(tester, '09_edit_booking_top');
    await scrollBy(tester, 600);
    await shot(tester, '10_edit_booking_photos');
    await tester.pageBack();
    await waitFor(tester, find.text('Booking Details'));

    // ---- Reschedule
    await tap(tester, find.text('Reschedule Booking'));
    await scrollFind(tester, find.textContaining('slots open'));
    await scrollToTop(tester);
    await shot(tester, '11_reschedule_top');
    await tap(tester, find.text('Select'));
    await shot(tester, '12_reschedule_slot_selected');
    await tap(tester, find.textContaining('Confirm New Time'));
    await waitFor(tester, find.text('Booking Details'));
    await scrollToTop(tester);
    await shot(tester, '13_booking_rescheduled');

    // ---- Cancel → Cancelled / refund
    await tap(tester, find.text('Cancel Booking'));
    await tap(tester, find.text('Changed my plans'));
    await shot(tester, '14_cancel_reason');
    await tap(tester, find.widgetWithText(FilledButton, 'Cancel Booking'));
    await waitFor(tester, find.text('Cancel this booking?'));
    await shot(tester, '15_cancel_confirmation');
    await tap(tester, find.text('Yes, Cancel Booking'));
    await waitFor(tester, find.text('100% Full Refund'));
    await shot(tester, '16_booking_cancelled_refund');
    await scrollBy(tester, 650);
    await shot(tester, '17_refund_tracker');

    // ---- Receipt (completed booking)
    await tap(tester, find.text('Back to Bookings'));
    await tap(tester, find.textContaining('Past & Completed'));
    await tap(tester, find.text('Inverter AC Repair'));
    await tap(tester, find.text('View Receipt'));
    await waitFor(tester, find.textContaining('INV-'));
    await shot(tester, '18_receipt_top');
    await scrollBy(tester, 700);
    await shot(tester, '19_receipt_breakdown');
    await scrollFind(tester, find.text('Download PDF'));
    await shot(tester, '20_receipt_actions');

    // ---- Saved addresses
    await tap(tester, find.text('Saved'));
    await waitFor(tester, find.text('Rapid dispatch ready'));
    await scrollToTop(tester);
    await shot(tester, '21_my_addresses');
    await tap(tester, find.text('Add New'));
    await waitFor(tester, find.text('Add New Address'));
    await shot(tester, '22_add_address');
    await tester.pageBack();
    await settle(tester);
    await tap(tester, find.byTooltip('Delete Office • World Trade Center'));
    await waitFor(tester, find.text('Yes, Delete Address'));
    await shot(tester, '23_delete_address_confirmation');
    await tap(tester, find.text('Cancel & Keep Address'));
    await scrollToTop(tester);
    await tap(tester, find.text('Edit'));
    await waitFor(tester, find.text('Edit Address'));
    await shot(tester, '24_edit_address');
    await tester.pageBack();
    await settle(tester);

    // ---- Log out, then a brand-new customer sees the empty states
    await tap(tester, find.text('Profile'));
    await tap(tester, find.text('Log out'));
    await login(tester, 'newcustomer@homecare.test');
    await tap(tester, find.widgetWithText(FilledButton, 'Log in'));
    await waitFor(tester, find.text('Services for your home'));
    await tap(tester, find.text('Bookings'));
    await waitFor(tester, find.text('No Bookings Yet'));
    await shot(tester, '25_empty_bookings');
    await tap(tester, find.text('Saved'));
    await waitFor(tester, find.text('No Saved Addresses'));
    await shot(tester, '26_empty_addresses');
  });
}
