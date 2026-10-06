import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking.dart';

/// Where a dispute is in its life: the customer files it (pending), the
/// safety desk looks at it (under review) and finally decides (resolved).
enum DisputeStatus {
  pending,
  underReview,
  resolved;

  /// The value stored in Firestore.
  String get value => switch (this) {
    pending => 'pending',
    underReview => 'under_review',
    resolved => 'resolved',
  };

  String get label => switch (this) {
    pending => 'Pending',
    underReview => 'Under Review',
    resolved => 'Resolved',
  };

  static DisputeStatus parse(Object? value) => DisputeStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => DisputeStatus.pending,
  );
}

/// One dispute per booking. Its document ID is the booking ID, so a second
/// dispute for the same booking is impossible (and easy to look up).
class Dispute {
  const Dispute({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.reason,
    required this.description,
    required this.status,
    this.tag,
    this.photoCount = 0,
    this.createdAt,
    this.respondDeadline,
    this.adminNote,
    this.decision,
    this.refundAmount,
    this.providerResponse,
  });

  final String id, bookingId, customerId, providerId;
  final String reason, description;
  final String? tag;
  final DisputeStatus status;
  final int photoCount;
  final DateTime? createdAt, respondDeadline;

  // Filled in later by the safety desk / the provider (not by the customer).
  final String? adminNote, decision, providerResponse;
  final double? refundAmount;

  /// Only a pending dispute can still be edited or withdrawn.
  bool get isPending => status == DisputeStatus.pending;

  static Dispute? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final reason = data['reason'];
    final description = data['description'];
    final customerId = data['customerId'];
    final providerId = data['providerId'];
    if (reason is! String ||
        description is! String ||
        customerId is! String ||
        providerId is! String) {
      return null;
    }
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;
    String? text(Object? v) => v is String && v.isNotEmpty ? v : null;
    final refund = data['refundAmount'];
    return Dispute(
      id: id,
      bookingId: data['bookingId'] is String ? data['bookingId'] as String : id,
      customerId: customerId,
      providerId: providerId,
      reason: reason,
      description: description,
      tag: text(data['tag']),
      status: DisputeStatus.parse(data['status']),
      photoCount: data['photoCount'] is num
          ? (data['photoCount'] as num).toInt()
          : 0,
      createdAt: date(data['createdAt']),
      respondDeadline: date(data['respondDeadline']),
      adminNote: text(data['adminNote']),
      decision: text(data['decision']),
      refundAmount: refund is num ? refund.toDouble() : null,
      providerResponse: text(data['providerResponse']),
    );
  }
}

/// One supporting photo. Photos are stored as Base64 text in the
/// `disputes/{id}/photos` subcollection (one document each, because a
/// Firestore document is limited to 1 MB), not in Firebase Storage.
class DisputePhoto {
  const DisputePhoto({
    required this.id,
    required this.base64,
    this.mimeType = 'image/jpeg',
  });

  final String id, base64, mimeType;

  Uint8List get bytes => base64Decode(base64);

  /// Size of the original picture in bytes.
  int get sizeBytes {
    final padding = base64.endsWith('==')
        ? 2
        : base64.endsWith('=')
        ? 1
        : 0;
    return base64.length * 3 ~/ 4 - padding;
  }

  static DisputePhoto? fromMap(String id, Map<String, dynamic> data) {
    final text = data['base64'];
    if (text is! String || text.isEmpty) return null;
    return DisputePhoto(
      id: id,
      base64: text,
      mimeType: data['mimeType'] is String
          ? data['mimeType'] as String
          : 'image/jpeg',
    );
  }

  static DisputePhoto fromBytes(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) => DisputePhoto(id: '', base64: base64Encode(bytes), mimeType: mimeType);
}

/// The reasons offered in the dispute form, plus the quick chips under it.
class DisputeReasons {
  static const all = [
    'Service not completed / Damage claim',
    'Poor work quality',
    'Overcharged / Billing issue',
    'Professional conduct',
    'Other',
  ];

  /// Quick tags shown as chips; tapping one adds it to the dispute.
  static const tags = ['Defective repair', 'Billing issue', 'Property damage'];
}

/// The 3-day warranty window after a job is completed. Disputes can only be
/// filed while it is open.
class DisputeWarranty {
  static const window = Duration(days: 3);

  /// The moment the warranty ends (null when the job has no completion time).
  static DateTime? endsAt(Booking booking) => booking.completedAt?.add(window);

  static bool isOpen(Booking booking, DateTime now) {
    final end = endsAt(booking);
    return booking.status == BookingStatus.completed &&
        end != null &&
        now.isBefore(end);
  }

  /// "Warranty: 2 days 5 hours left" while open, "Warranty period ended"
  /// afterwards.
  static String label(Booking booking, DateTime now) {
    final end = endsAt(booking);
    if (end == null || !now.isBefore(end)) return 'Warranty period ended';
    final left = end.difference(now);
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    String unit(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    final parts = days > 0
        ? '${unit(days, 'day')} ${unit(hours, 'hour')}'
        : hours > 0
        ? '${unit(hours, 'hour')} ${unit(minutes, 'minute')}'
        : unit(minutes < 1 ? 1 : minutes, 'minute');
    return 'Warranty: $parts left';
  }
}
