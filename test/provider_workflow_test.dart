import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/provider_profile.dart';

Booking booking({
  BookingStatus status = BookingStatus.pending,
  String payment = 'paid',
  double? labor = 2000,
  double? total = 2500,
  double? fee = 500,
  DateTime? completed,
  DateTime? expires,
}) => Booking(
  id: 'job',
  customerId: 'customer',
  providerId: 'provider',
  serviceName: 'Repair',
  customerName: 'Customer',
  address: 'Address',
  status: status,
  paymentStatus: payment,
  laborCharge: labor,
  totalAmount: total,
  serviceFee: fee,
  completedAt: completed,
  expiresAt: expires,
);

void main() {
  final now = DateTime(2026, 10, 1, 12);

  test(
    'only pending -> confirmed/declined and confirmed -> completed are allowed',
    () {
      for (final source in BookingStatus.values) {
        for (final target in BookingStatus.values) {
          final valid =
              source == BookingStatus.pending &&
                  (target == BookingStatus.confirmed ||
                      target == BookingStatus.declined) ||
              source == BookingStatus.confirmed &&
                  target == BookingStatus.completed;
          void action() =>
              booking(status: source).validateTransition(target, now);
          if (valid) {
            expect(action, returnsNormally);
          } else {
            expect(action, throwsStateError);
          }
        }
      }
    },
  );

  test('expired requests reject acceptance including exact expiry, but permit decline', () {
    final expired = booking(expires: now);
    expect(
      () => expired.validateTransition(BookingStatus.confirmed, now),
      throwsStateError,
    );
    expect(
      () => expired.validateTransition(BookingStatus.declined, now),
      returnsNormally,
    );
    expect(
      () =>
          booking(expires: now.add(const Duration(seconds: 1)))
              .validateTransition(BookingStatus.confirmed, now),
      returnsNormally,
    );
  });

  test('Firestore timestamp and optional field round trip', () {
    final original = booking(completed: now, expires: now);
    final map = original.toMap();
    expect(map['completedAt'], isA<Timestamp>());
    final restored = Booking.fromMap('job', map);
    expect(restored.completedAt, now);
    expect(restored.expiresAt, now);
    expect(restored.providerId, 'provider');
    expect(restored.providerPayout, 2000);
    final missing = Booking.fromMap('missing', {});
    expect(missing.status, BookingStatus.unknown);
    expect(missing.scheduledAt, isNull);
    expect(missing.providerPayout, isNull);
  });

  test('earnings exclude unpaid, incomplete, unknown amounts and missing completion date', () {
    final earnings = ProviderEarnings([
      booking(status: BookingStatus.completed, completed: now),
      booking(
        status: BookingStatus.completed,
        completed: DateTime(2026, 9, 30),
        labor: 1000,
      ),
      booking(
        status: BookingStatus.completed,
        completed: now,
        payment: 'unpaid',
      ),
      booking(status: BookingStatus.confirmed, completed: now),
      booking(status: BookingStatus.completed),
      booking(
        status: BookingStatus.completed,
        completed: now,
        labor: null,
        total: null,
        fee: null,
      ),
    ], now);
    expect(earnings.monthlyTotal, 2000);
    expect(earnings.total, 3000);
    expect(earnings.entries, hasLength(2));
    expect(earnings.completedCount, 5);
  });

  test(
    'payout falls back to total less known fee, never to estimated price',
    () {
      expect(booking(labor: null).providerPayout, 2000);
      expect(booking(labor: null, fee: null).providerPayout, isNull);
      expect(booking(labor: null, total: 100, fee: 500).providerPayout, isNull);
      expect(ProviderEarnings([], now).monthlyTotal, 0);
    },
  );

  test('invalid money does not become earnings', () {
    final invalid = Booking.fromMap('bad', {
      'status': 'completed',
      'paymentStatus': 'paid',
      'completedAt': Timestamp.fromDate(now),
      'laborCharge': -10,
      'totalAmount': double.nan,
    });
    expect(invalid.earnsRevenue, isFalse);
  });

  test('profile saves editable fields only and validates pricing', () {
    const profile = ProviderProfile(
      providerId: 'provider',
      profession: 'Electrician',
      rating: 5,
      verificationStatus: 'verified',
    );
    expect(profile.validate, returnsNormally);
    expect(profile.editableFields().containsKey('rating'), isFalse);
    expect(profile.editableFields().containsKey('verificationStatus'), isFalse);
    expect(
      () => const ProviderProfile(
        providerId: 'provider',
        profession: 'Electrician',
        pricing: -1,
      ).validate(),
      throwsArgumentError,
    );
    final empty = ProviderProfile.fromMap('provider', {});
    expect(empty.availability, isFalse);
    expect(empty.verificationStatus, 'unverified');
  });
}
