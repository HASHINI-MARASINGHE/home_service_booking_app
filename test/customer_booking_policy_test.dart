import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/address.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/booking_policy.dart';
import 'package:home_service_bookin_app/models/professional.dart';
import 'package:home_service_bookin_app/models/receipt.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/edit_booking_screen.dart';
import 'package:home_service_bookin_app/services/customer_booking_service.dart';
import 'package:home_service_bookin_app/utils/formatters.dart';

import 'support/customer_fakes.dart';

void main() {
  group('BookingPolicy', () {
    test('Colombo slot instants are UTC+05:30', () {
      final at = BookingPolicy.colomboInstant(DateTime(2025, 11, 16), '13:30');
      expect(at, DateTime.utc(2025, 11, 16, 8, 0));
      expect(
        BookingPolicy.colomboToday(DateTime.utc(2025, 11, 15, 19, 0)),
        DateTime(2025, 11, 16),
      );
    });

    test('free cancellation more than 2 hours ahead refunds 100%', () {
      final b = booking();
      expect(BookingPolicy.isFreeCancellation(b, testNow), isTrue);
      expect(BookingPolicy.cancellationFee(b, testNow), 0);
      expect(BookingPolicy.refundAmount(b, testNow), 5500);
      expect(BookingPolicy.refundPercentage(5500, 5500), 100);
    });

    test('late cancellation keeps a floored 20% fee', () {
      final b = booking();
      final late = b.scheduledAt!.subtract(const Duration(minutes: 90));
      expect(BookingPolicy.isFreeCancellation(b, late), isFalse);
      expect(BookingPolicy.cancellationFee(b, late), 1100);
      expect(BookingPolicy.refundAmount(b, late), 4400);
      expect(BookingPolicy.refundPercentage(4400, 5500), 80);
    });

    test('unpaid bookings have nothing to refund', () {
      final b = booking(paymentStatus: 'unpaid');
      expect(BookingPolicy.hasCapturedPayment(b), isFalse);
      expect(BookingPolicy.refundAmount(b, testNow), 0);
    });

    test('status rules for edit, reschedule and cancel', () {
      expect(BookingPolicy.canEdit(booking()), isTrue);
      expect(BookingPolicy.canReschedule(booking(), testNow), isTrue);
      final soon = booking().scheduledAt!.subtract(const Duration(hours: 1));
      expect(BookingPolicy.canReschedule(booking(), soon), isFalse);
      for (final status in [
        BookingStatus.onTheWay,
        BookingStatus.inProgress,
        BookingStatus.completed,
        BookingStatus.cancelled,
      ]) {
        final b = booking(status: status);
        expect(BookingPolicy.canEdit(b), isFalse, reason: status.name);
        expect(BookingPolicy.canCancel(b), isFalse, reason: status.name);
        expect(BookingPolicy.canReschedule(b, testNow), isFalse);
      }
    });

    test('slot states: booked, current, closed days and past slots', () {
      const pro = Professional(id: 'pro', name: 'Nuwan');
      final date = DateTime(2025, 11, 13); // Thursday
      final slots = BookingPolicy.buildSlots(
        professional: pro,
        date: date,
        locks: {'10:30': 'b1', '15:30': 'someone-else'},
        bookingId: 'b1',
        now: testNow,
      );
      expect(slots.map((s) => s.state), [
        SlotState.available,
        SlotState.current,
        SlotState.available,
        SlotState.booked,
        SlotState.available,
      ]);
      final sunday = BookingPolicy.buildSlots(
        professional: pro,
        date: DateTime(2025, 11, 16),
        locks: const {},
        bookingId: 'b1',
        now: testNow,
      );
      expect(sunday.every((s) => s.state == SlotState.unavailable), isTrue);
      // 09:00 Colombo now: 08:30 is past and 10:30 is inside the 2 h window.
      final today = BookingPolicy.buildSlots(
        professional: pro,
        date: DateTime(2025, 11, 10),
        locks: const {},
        bookingId: 'b1',
        now: testNow,
      );
      expect(today[0].state, SlotState.unavailable);
      expect(today[1].state, SlotState.unavailable);
      expect(today[2].state, SlotState.available);
    });

    test('slot lock IDs match the security-rule format', () {
      expect(
        BookingPolicy.slotLockId('pro', '2025-11-16', '13:30'),
        'pro_2025-11-16_1330',
      );
      expect(BookingPolicy.newRefundReference(), matches(r'^REF-\d{6}$'));
    });
  });

  group('Address', () {
    test('splits city and postal code', () {
      expect(AddressInput.splitCityAndPostalCode('Colombo 03 (00300)'), (
        'Colombo 03',
        '00300',
      ));
      expect(AddressInput.splitCityAndPostalCode('Dehiwala 10350'), (
        'Dehiwala',
        '10350',
      ));
      expect(AddressInput.splitCityAndPostalCode('Kandy'), ('Kandy', ''));
    });

    test('validation requires house, street and city', () {
      AddressInput input(String street) => AddressInput(
        type: AddressType.home,
        label: '',
        houseNumber: 'No. 1',
        street: street,
        cityAndPostalCode: 'Colombo 03',
      );
      expect(() => input('  ').validate(), throwsArgumentError);
      expect(() => input('Galle Road').validate(), returnsNormally);
      expect(input('Galle Road').toMap()['label'], 'Home');
    });

    test('formats and searches saved addresses', () {
      final a = Address.fromMap('x', {
        'type': 'office',
        'label': '',
        'houseNumber': 'Level 14',
        'street': 'Echelon Square',
        'city': 'Colombo 01',
        'province': 'Western Province',
        'landmark': 'Security desk',
        'isDefault': true,
      });
      expect(a.label, 'Office');
      expect(a.type.category, 'Workplace');
      expect(
        a.fullAddress,
        'Level 14 Echelon Square, Colombo 01, Western Province',
      );
      expect(a.matches('security'), isTrue);
      expect(a.matches('kandy'), isFalse);
    });
  });

  group('Booking model', () {
    test('customer fields round-trip through Firestore maps', () {
      final original = booking();
      final restored = Booking.fromMap(original.id, original.toMap());
      expect(restored.slotDate, original.slotDate);
      expect(restored.lineItems.map((i) => i.amount), [4500, 800, 200]);
      expect(restored.cardLast4, '8821');
      expect(
        restored.scheduledAt!.isAtSameMomentAs(original.scheduledAt!),
        isTrue,
      );
      expect(restored.toMap()['scheduledAt'], isA<Timestamp>());
      expect(restored.displayReference, 'BK-B1');
      expect(Booking.fromMap('abcdefgh', {}).displayReference, 'BK-ABCDEF');
    });

    test('new statuses parse and group as upcoming', () {
      expect(BookingStatus.parse('onTheWay'), BookingStatus.onTheWay);
      expect(BookingStatus.inProgress.isUpcoming, isTrue);
      expect(BookingStatus.completed.isUpcoming, isFalse);
    });

    test('receipt totals fall back to line items', () {
      final r = Receipt.fromMap('b', {
        'receiptNumber': 'INV-1',
        'bookingReference': 'BK-1',
        'lineItems': [
          {'label': 'A', 'amount': 100},
          {'label': 'B', 'amount': 50},
          {'label': 'bad', 'amount': 'x'},
        ],
      });
      expect(r.lineItems, hasLength(2));
      expect(r.totalAmount, 150);
      expect(r.verificationPayload, 'HOMECARE|INV-1|BK-1|150');
    });
  });

  group('BookingEdit validation', () {
    BookingEdit edit({String phone = '+94771234567', int photos = 0}) =>
        BookingEdit(
          address: 'No. 42 Galle Road',
          accessNotes: '',
          contactPhone: phone,
          jobNotes: '',
          keptPhotoUrls: List.generate(photos, (i) => 'u$i'),
        );

    test('rejects bad phones and too many photos', () {
      expect(() => edit().validate(), returnsNormally);
      expect(() => edit(phone: '12').validate(), throwsArgumentError);
      expect(() => edit(photos: 6).validate(), throwsArgumentError);
    });

    test('Sri Lankan phone conversion', () {
      expect(SriLankaPhone.toLocal('+94771234567'), '077 123 4567');
      expect(SriLankaPhone.toE164('077 123 4567'), '+94771234567');
      expect(SriLankaPhone.toE164('94771234567'), '+94771234567');
      expect(SriLankaPhone.toE164('0771'), isNull);
    });
  });

  test('formatters', () {
    expect(Formatters.lkr(14500), 'LKR 14,500');
    expect(Formatters.lkr(1234567.4), 'LKR 1,234,567');
    expect(Formatters.time12('13:30'), '01:30 PM');
    expect(Formatters.time12('00:05', padHour: false), '12:05 AM');
    expect(
      Formatters.longDate(DateTime(2024, 11, 14)),
      'Thursday, 14 Nov 2024',
    );
    expect(Formatters.parseIsoDate('2024-11-16'), DateTime(2024, 11, 16));
    expect(Formatters.isoDate(DateTime(2024, 1, 5)), '2024-01-05');
  });
}
