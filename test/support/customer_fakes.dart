import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/address.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/booking_policy.dart';
import 'package:home_service_bookin_app/models/professional.dart';
import 'package:home_service_bookin_app/models/receipt.dart';
import 'package:home_service_bookin_app/models/refund.dart';
import 'package:home_service_bookin_app/screens/customer/customer_scope.dart';
import 'package:home_service_bookin_app/services/address_service.dart';
import 'package:home_service_bookin_app/services/customer_booking_service.dart';
import 'package:home_service_bookin_app/services/location_service.dart';
import 'package:home_service_bookin_app/services/receipt_pdf_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/utils/formatters.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

class _Storage extends Fake implements FirebaseStorage {}

/// Fixed "now": Monday 10 Nov 2025, 09:00 Colombo time.
final testNow = DateTime.utc(2025, 11, 10, 3, 30);

const testUser = AppUser(
  uid: 'customer',
  name: 'Dilshan Perera',
  email: 'customer@homecare.test',
  role: AppUser.customerRole,
);

Address address({
  String id = 'home',
  AddressType type = AddressType.home,
  String label = 'Home',
  bool isDefault = false,
  String city = 'Colombo 03',
}) => Address(
  id: id,
  type: type,
  label: label,
  houseNumber: 'No. 42',
  street: 'Galle Road',
  city: city,
  postalCode: '00300',
  province: 'Western Province',
  landmark: 'Opposite Majestic City',
  isDefault: isDefault,
);

Booking booking({
  String id = 'b1',
  BookingStatus status = BookingStatus.confirmed,
  String paymentStatus = 'escrow',
  int daysAhead = 3,
  String? addressId = 'home',
  String serviceName = 'AC Deep Clean & Servicing',
}) {
  final date = DateTime(2025, 11, 10 + daysAhead);
  return Booking(
    id: id,
    reference: 'BK-${id.toUpperCase()}',
    customerId: testUser.uid,
    providerId: 'pro',
    providerName: 'Nuwan Fernando',
    serviceName: serviceName,
    serviceDetail: '2 Inverter Indoor & Outdoor Units',
    serviceTier: 'Domestic Tier 1',
    customerName: testUser.name,
    address: 'No. 42 Galle Road, Colombo 03',
    addressId: addressId,
    addressLabel: 'Home',
    addressArea: 'Kollupitiya Ward, Western Province',
    accessNotes: 'Blue gate, ring bell 2B.',
    contactPhone: '+94771234567',
    status: status,
    slotDate: '2025-11-${(10 + daysAhead).toString().padLeft(2, '0')}',
    startTime: '10:30',
    endTime: '12:00',
    slotLockId: 'pro_2025-11-${10 + daysAhead}_1030',
    scheduledAt: BookingPolicy.colomboInstant(date, '10:30'),
    endAt: BookingPolicy.colomboInstant(date, '12:00'),
    totalAmount: 5500,
    serviceFee: 200,
    paymentMethod: 'card',
    cardLast4: '8821',
    paymentStatus: paymentStatus,
    lineItems: const [
      BookingLineItem(label: 'Base AC Servicing (2 Units)', amount: 4500),
      BookingLineItem(label: 'Disinfection & Coil Flush', amount: 800),
      BookingLineItem(label: 'Platform SafeCare Fee', amount: 200),
    ],
  );
}

const professional = Professional(
  id: 'pro',
  name: 'Nuwan Fernando',
  specialty: 'Air Conditioning & Electrical Specialist',
  rating: 4.9,
  completedJobs: 128,
  verified: true,
  phone: '+94771112233',
  licenseNumber: 'LK-AC-409',
  area: 'Colombo 03',
);

class FakeAddressService extends AddressService {
  FakeAddressService([List<Address>? items])
    : items = items ?? [],
      super(auth: _Auth(), firestore: _Db());

  final List<Address> items;
  final _controller = StreamController<List<Address>>.broadcast();
  final deleted = <String>[];
  final linked = <String, List<Booking>>{};
  AddressInput? created;
  Object? deleteError;

  void _emit() => _controller.add(List.of(items));

  @override
  Stream<List<Address>> watchAddresses() async* {
    yield List.of(items);
    yield* _controller.stream;
  }

  @override
  Future<List<Address>> getAddresses() async => List.of(items);

  @override
  Future<Address?> getAddress(String id) async =>
      items.where((a) => a.id == id).firstOrNull;

  @override
  Future<String> create(AddressInput input) async {
    input.validate();
    created = input;
    return 'new-address';
  }

  @override
  Future<List<Booking>> linkedActiveBookings(String addressId) async =>
      linked[addressId] ?? const [];

  @override
  Future<void> delete(Address address) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(address.id);
    items.removeWhere((a) => a.id == address.id);
    _emit();
  }
}

class FakeBookingService extends CustomerBookingService {
  FakeBookingService({List<Booking>? bookings, this.receipt, this.refund})
    : bookings = bookings ?? [],
      super(
        auth: _Auth(),
        firestore: _Db(),
        storage: _Storage(),
        clock: () => testNow,
      );

  final List<Booking> bookings;
  final Receipt? receipt;
  Refund? refund;

  /// ISO date → {start time → booking ID holding the slot}.
  final locks = <String, Map<String, String>>{};
  final cancelled = <String, String>{};
  final rescheduled = <String, TimeSlot>{};

  @override
  Stream<List<Booking>> watchBookings() => Stream.value(bookings);

  @override
  Stream<Booking?> watchBooking(String id) =>
      Stream.value(bookings.where((b) => b.id == id).firstOrNull);

  @override
  Future<Professional?> getProfessional(
    String providerId, {
    bool refresh = false,
  }) async => professional;

  @override
  Stream<Refund?> watchRefund(String bookingId) => Stream.value(refund);

  @override
  Future<Receipt?> getReceipt(String bookingId) async => receipt;

  @override
  Future<List<TimeSlot>> availableSlots({
    required Booking booking,
    required Professional professional,
    required DateTime date,
  }) async => BookingPolicy.buildSlots(
    professional: professional,
    date: date,
    locks: locks[Formatters.isoDate(date)] ?? const {},
    bookingId: booking.id,
    now: now(),
  );

  @override
  Future<void> reschedule(Booking booking, TimeSlot slot) async {
    rescheduled[booking.id] = slot;
  }

  @override
  Future<CancellationResult> cancel(Booking booking, String reason) async {
    cancelled[booking.id] = reason;
    final i = bookings.indexWhere((b) => b.id == booking.id);
    bookings[i] = Booking.fromMap(booking.id, {
      ...booking.toMap(),
      'status': 'cancelled',
      'cancellationReason': reason,
    });
    refund = Refund(
      bookingId: booking.id,
      amount: BookingPolicy.refundAmount(booking, now()),
      status: RefundStatus.initiated,
      refundReference: 'REF-123456',
      method: 'card',
      cardLast4: booking.cardLast4,
      createdAt: now(),
    );
    return CancellationResult(
      fee: 0,
      refundAmount: refund!.amount,
      refundReference: refund!.refundReference,
    );
  }
}

/// Pumps [child] inside the customer scope with the HomeCare theme.
Future<List<int>> pumpCustomer(
  WidgetTester tester,
  Widget child, {
  AddressService? addresses,
  CustomerBookingService? bookings,
  Size size = const Size(390, 844),
}) async {
  final selectedTabs = <int>[];
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      // In the app every tab navigator sits below the scope; mirror that so
      // pushed screens can read it too.
      builder: (context, navigator) => CustomerScope(
        user: testUser,
        addresses: addresses ?? FakeAddressService(),
        bookings: bookings ?? FakeBookingService(),
        location: LocationService(),
        receipts: ReceiptPdfService(),
        selectTab: (tab, {reset = false}) => selectedTabs.add(tab),
        child: navigator!,
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
  return selectedTabs;
}
