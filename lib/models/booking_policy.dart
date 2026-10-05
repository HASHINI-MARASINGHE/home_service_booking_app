import 'dart:math';

import '../utils/formatters.dart';
import 'booking.dart';
import 'professional.dart';

enum SlotState { available, booked, current, unavailable }

/// One bookable window on a professional's calendar.
class TimeSlot {
  const TimeSlot({
    required this.date,
    required this.start,
    required this.end,
    required this.state,
    required this.startsAt,
  });

  final DateTime date;
  final String start, end;
  final SlotState state;

  /// Absolute instant of [start] in Colombo time.
  final DateTime startsAt;

  bool get selectable => state == SlotState.available;
  String get isoDate => Formatters.isoDate(date);
}

/// Business rules for customer booking changes. `firestore.rules` enforces
/// the same rules server-side; keep the two in sync.
abstract final class BookingPolicy {
  /// Sri Lanka is UTC+05:30 all year (no daylight saving).
  static const colomboOffset = Duration(hours: 5, minutes: 30);

  /// Free reschedule/cancel window before the slot starts.
  static const freeChangeWindow = Duration(hours: 2);

  /// Late cancellations keep 20% of the total as a fee.
  static const lateFeeDivisor = 5;

  static const maxPhotos = 5;
  static const maxAccessNotes = 200;
  static const maxJobNotes = 1000;
  static const visibleDays = 14;

  static const cancellationReasons = [
    'Changed my plans',
    'Booked by mistake',
    'Found another provider',
    'Other',
  ];

  static DateTime colomboInstant(DateTime date, String hhmm) {
    final parts = hhmm.split(':').map(int.parse).toList();
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      parts[0],
      parts[1],
    ).subtract(colomboOffset);
  }

  static DateTime colomboToday(DateTime now) {
    final local = now.toUtc().add(colomboOffset);
    return DateTime(local.year, local.month, local.day);
  }

  static String slotLockId(String providerId, String isoDate, String start) =>
      '${providerId}_${isoDate}_${start.replaceAll(':', '')}';

  static bool _open(Booking b) =>
      b.status == BookingStatus.pending || b.status == BookingStatus.confirmed;

  static bool _outsideWindow(Booking b, DateTime now) =>
      b.scheduledAt != null &&
      b.scheduledAt!.isAfter(now.add(freeChangeWindow));

  /// Address, notes, phone and photos may change until the pro is dispatched.
  static bool canEdit(Booking b) => _open(b);

  static bool canReschedule(Booking b, DateTime now) =>
      _open(b) &&
      b.slotDate != null &&
      b.startTime != null &&
      b.endTime != null &&
      _outsideWindow(b, now);

  static bool canCancel(Booking b) => _open(b);

  static bool isFreeCancellation(Booking b, DateTime now) =>
      _outsideWindow(b, now);

  static double cancellationFee(Booking b, DateTime now) =>
      isFreeCancellation(b, now)
      ? 0
      : (b.chargeTotal / lateFeeDivisor).floorToDouble();

  /// Only money already captured (escrow or paid) is refundable.
  static bool hasCapturedPayment(Booking b) =>
      b.paymentStatus == 'escrow' || b.paymentStatus == 'paid';

  static double refundAmount(Booking b, DateTime now) => hasCapturedPayment(b)
      ? max(0, b.chargeTotal - cancellationFee(b, now))
      : 0;

  static int refundPercentage(double refund, double total) =>
      total <= 0 ? 0 : (refund * 100 / total).round();

  static String newRefundReference([Random? random]) {
    final r = random ?? Random.secure();
    return 'REF-${(100000 + r.nextInt(900000))}';
  }

  /// Calendar strip for the reschedule screen: today plus [visibleDays].
  static List<DateTime> calendarDays(DateTime now) {
    final today = colomboToday(now);
    return [
      for (var i = 0; i < visibleDays; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
  }

  /// Builds the day's slots from the professional's template.
  /// [locks] maps a slot start time to the booking holding it.
  static List<TimeSlot> buildSlots({
    required Professional professional,
    required DateTime date,
    required Map<String, String> locks,
    required String bookingId,
    required DateTime now,
  }) {
    final worksToday = professional.workingDays.contains(date.weekday);
    return [
      for (final (start, end) in professional.workingSlots)
        () {
          final startsAt = colomboInstant(date, start);
          final holder = locks[start];
          final state = holder == bookingId
              ? SlotState.current
              : holder != null
              ? SlotState.booked
              : !worksToday || !startsAt.isAfter(now.add(freeChangeWindow))
              ? SlotState.unavailable
              : SlotState.available;
          return TimeSlot(
            date: date,
            start: start,
            end: end,
            state: state,
            startsAt: startsAt,
          );
        }(),
    ];
  }
}
