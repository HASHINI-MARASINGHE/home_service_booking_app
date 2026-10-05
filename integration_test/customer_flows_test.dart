// End-to-end customer flows against the local Firebase emulators, using the
// real services, Firestore transactions and security rules.
//
// 1. Start emulators (Auth 9099, Firestore 8080 or FIRESTORE_EMULATOR_PORT)
//    with firestore.rules loaded, then seed: node tool/seed/seed.mjs --emulator
// 2. chromedriver --port=4444
// 3. flutter drive --driver=test_driver/integration_test.dart
//      --target=integration_test/customer_flows_test.dart -d web-server
//      --dart-define=FIRESTORE_EMULATOR_PORT=8085
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/firebase_options.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_cancelled_screen.dart';
import 'package:home_service_bookin_app/screens/customer/customer_home_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/services/customer_booking_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:integration_test/integration_test.dart';

const host = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
const firestorePort = int.fromEnvironment(
  'FIRESTORE_EMULATOR_PORT',
  defaultValue: 8080,
);
const bookingId = 'seed-bk-78924';

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
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
      .take(120)
      .join(' | ');
  throw TestFailure('Timed out waiting for $finder. On screen: $visible');
}

/// Waits for data, scrolling the visible vertical list to build lazy items.
Future<void> scrollFind(WidgetTester tester, Finder finder) async {
  // Give Firestore a moment first so loading lists aren't scrolled away.
  try {
    return await waitFor(tester, finder, timeout: const Duration(seconds: 4));
  } on TestFailure {
    // Not on screen yet: scroll to build lazily created items.
  }
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    final lists = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    if (lists.evaluate().isNotEmpty) {
      await tester.drag(lists.last, const Offset(0, -300));
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  await waitFor(tester, finder, timeout: const Duration(seconds: 1));
}

Future<void> scrollToTop(WidgetTester tester) async {
  final lists = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  for (var i = 0; i < 6 && lists.evaluate().isNotEmpty; i++) {
    await tester.drag(lists.last, const Offset(0, 600));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> tapWhenVisible(WidgetTester tester, Finder finder) async {
  await scrollFind(tester, finder);
  await tester.ensureVisible(finder.first);
  // Floating snack bars can sit on top of bottom buttons.
  for (final messenger in find.byType(ScaffoldMessenger).evaluate()) {
    (messenger as StatefulElement).state is ScaffoldMessengerState
        ? (messenger.state as ScaffoldMessengerState).clearSnackBars()
        : null;
  }
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<Map<String, dynamic>> doc(String path) async =>
    (await FirebaseFirestore.instance.doc(path).get()).data() ?? {};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String uid;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'customer@homecare.test',
      password: 'HomeCare@123',
    );
    uid = credential.user!.uid;
  });

  testWidgets('customer manages bookings and addresses end to end', (
    tester,
  ) async {
    final auth = AuthService();
    final profile = await auth.getUserProfile(uid);
    expect(profile?.role, 'customer');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CustomerHomeScreen(user: profile!, authService: auth),
      ),
    );

    // ---- Booking History → Booking Details (real backend data)
    await tapWhenVisible(tester, find.text('Bookings'));
    await waitFor(tester, find.text('Upcoming (2)'));
    await tapWhenVisible(tester, find.text('AC Deep Clean & Servicing'));
    await waitFor(tester, find.text('Code #BK-78924'));
    await waitFor(tester, find.text('Nuwan Fernando'));

    // ---- Edit Booking Details
    await tapWhenVisible(tester, find.text('Edit Details'));
    final notes = find.widgetWithText(
      TextField,
      'Blue gate, ring bell 2B. Please call before entering to secure pets.',
    );
    await scrollFind(tester, notes);
    await tester.enterText(notes, 'Gate code 4321. Dog is friendly.');
    await tapWhenVisible(tester, find.text('Save Changes'));
    await waitFor(tester, find.text('Booking details updated.'));
    await waitFor(tester, find.text('Booking Details'));
    expect(
      (await doc('bookings/$bookingId'))['accessNotes'],
      'Gate code 4321. Dog is friendly.',
    );

    // ---- Reschedule into a free slot
    final before = await doc('bookings/$bookingId');
    await tapWhenVisible(tester, find.text('Reschedule Booking'));
    await scrollFind(tester, find.textContaining('slots open'));
    await tapWhenVisible(tester, find.text('Select'));
    await tapWhenVisible(tester, find.textContaining('Confirm New Time'));
    await waitFor(tester, find.textContaining('Booking moved to'));
    await waitFor(tester, find.text('Booking Details'));
    final after = await doc('bookings/$bookingId');
    expect(after['slotLockId'], isNot(before['slotLockId']));
    final newLock = await doc('slotLocks/${after['slotLockId']}');
    expect(newLock['bookingId'], bookingId);
    expect(
      (await FirebaseFirestore.instance
              .doc('slotLocks/${before['slotLockId']}')
              .get())
          .exists,
      isFalse,
      reason: 'old slot released',
    );

    // ---- Cancel with refund
    await tapWhenVisible(tester, find.text('Cancel Booking'));
    await tapWhenVisible(tester, find.text('Changed my plans'));
    await tapWhenVisible(
      tester,
      find.widgetWithText(FilledButton, 'Cancel Booking'),
    );
    await tapWhenVisible(tester, find.text('Yes, Cancel Booking'));
    await waitFor(tester, find.byType(BookingCancelledScreen));
    await waitFor(tester, find.text('100% Full Refund'));
    final cancelled = await doc('bookings/$bookingId');
    expect(cancelled['status'], 'cancelled');
    expect(cancelled['paymentStatus'], 'refund_pending');
    final refund = await doc('refunds/$bookingId');
    expect(refund['amount'], 5500);
    expect(refund['status'], 'initiated');

    // ---- Saved addresses: add, then delete
    await tapWhenVisible(tester, find.text('Saved'));
    await waitFor(tester, find.text('Rapid dispatch ready'));
    await scrollToTop(tester);
    await waitFor(tester, find.text('All (3)'));
    await tapWhenVisible(tester, find.text('Add New'));
    await tapWhenVisible(tester, find.text('Other'));
    Finder field(String hint) => find.widgetWithText(TextFormField, hint);
    await scrollFind(tester, field('No. 42, Apt 4B'));
    await tester.enterText(field('Other'), 'Gym');
    await tester.enterText(field('No. 42, Apt 4B'), 'No. 9');
    await tester.enterText(field('Galle Road'), 'Duplication Road');
    await tester.enterText(field('Colombo 03 (00300)'), 'Colombo 04 (00400)');
    await tapWhenVisible(tester, find.text('Save Address'));
    await waitFor(tester, find.text('Address saved.'));
    await scrollToTop(tester);
    await waitFor(tester, find.text('All (4)'));
    final saved = await FirebaseFirestore.instance
        .collection('users/$uid/addresses')
        .where('label', isEqualTo: 'Gym')
        .get();
    expect(saved.docs.single.data()['postalCode'], '00400');

    await tapWhenVisible(tester, find.byTooltip('Delete Gym'));
    await tapWhenVisible(tester, find.text('Yes, Delete Address'));
    await waitFor(tester, find.text('Address deleted.'));
    await scrollToTop(tester);
    await waitFor(tester, find.text('All (3)'));

    // ---- Authorization: another customer's booking is not readable
    Object? denied;
    try {
      await CustomerBookingService().watchBooking('seed-bk-80117').first;
    } catch (error) {
      denied = error;
    }
    expect(denied, isA<FirebaseException>());
    expect((denied! as FirebaseException).code, 'permission-denied');
  });
}
