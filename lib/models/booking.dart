import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  declined,
  completed,
  cancelled,
  unknown;

  static BookingStatus parse(Object? value) => BookingStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BookingStatus.unknown,
  );

  String get label => switch (this) {
    pending => 'New request',
    confirmed => 'Confirmed',
    declined => 'Declined',
    completed => 'Completed',
    cancelled => 'Cancelled',
    unknown => 'Unknown status',
  };

  bool get isHistory =>
      this == completed || this == declined || this == cancelled;
}

class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceName,
    required this.customerName,
    required this.address,
    required this.status,
    this.serviceId,
    this.scheduledAt,
    this.estimatedPrice,
    this.laborCharge,
    this.serviceFee,
    this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.createdAt,
    this.acceptedAt,
    this.declinedAt,
    this.completedAt,
    this.expiresAt,
    this.payoutNote,
  });

  final String id, customerId, providerId, serviceName, customerName, address;
  final String? serviceId, paymentMethod, paymentStatus, payoutNote;
  final BookingStatus status;
  final DateTime? scheduledAt,
      createdAt,
      acceptedAt,
      declinedAt,
      completedAt,
      expiresAt;
  final double? estimatedPrice, laborCharge, serviceFee, totalAmount;

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
  static double? _money(Object? value) =>
      value is num && value.isFinite && value >= 0 ? value.toDouble() : null;
  static String _text(Object? value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value : fallback;

  factory Booking.fromMap(String id, Map<String, dynamic> data) => Booking(
    id: id,
    customerId: _text(data['customerId'], ''),
    providerId: _text(data['providerId'], ''),
    serviceId: data['serviceId'] as String?,
    serviceName: _text(data['serviceName'], 'Service not specified'),
    customerName: _text(data['customerName'], 'Customer'),
    address: _text(data['address'], 'Location not provided'),
    status: BookingStatus.parse(data['status']),
    scheduledAt: _date(data['scheduledAt']),
    estimatedPrice: _money(data['estimatedPrice']),
    laborCharge: _money(data['laborCharge']),
    serviceFee: _money(data['serviceFee']),
    totalAmount: _money(data['totalAmount']),
    paymentMethod: data['paymentMethod'] as String?,
    paymentStatus: data['paymentStatus'] as String?,
    createdAt: _date(data['createdAt']),
    acceptedAt: _date(data['acceptedAt']),
    declinedAt: _date(data['declinedAt']),
    completedAt: _date(data['completedAt']),
    expiresAt: _date(data['expiresAt']),
    payoutNote: data['payoutNote'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'providerId': providerId,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'customerName': customerName,
    'address': address,
    'status': status.name,
    'scheduledAt': scheduledAt == null
        ? null
        : Timestamp.fromDate(scheduledAt!),
    'estimatedPrice': estimatedPrice,
    'laborCharge': laborCharge,
    'serviceFee': serviceFee,
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'acceptedAt': acceptedAt == null ? null : Timestamp.fromDate(acceptedAt!),
    'declinedAt': declinedAt == null ? null : Timestamp.fromDate(declinedAt!),
    'completedAt': completedAt == null
        ? null
        : Timestamp.fromDate(completedAt!),
    'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    'payoutNote': payoutNote,
  };

  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);

  // Phase 1 contract: labor is the provider's net payout; serviceFee is the
  // platform fee. Never count an estimate as settled earnings.
  double? get providerPayout {
    if (laborCharge != null) return laborCharge;
    if (totalAmount != null &&
        serviceFee != null &&
        totalAmount! >= serviceFee!) {
      return totalAmount! - serviceFee!;
    }
    return null;
  }

  bool get earnsRevenue =>
      status == BookingStatus.completed &&
      paymentStatus == 'paid' &&
      completedAt != null &&
      providerPayout != null;

  void validateTransition(BookingStatus target, DateTime now) {
    final valid =
        (status == BookingStatus.pending &&
            (target == BookingStatus.confirmed ||
                target == BookingStatus.declined)) ||
        (status == BookingStatus.confirmed &&
            target == BookingStatus.completed);
    if (!valid) {
      throw StateError('This job has changed. Refresh and try again.');
    }
    if (status == BookingStatus.pending &&
        target == BookingStatus.confirmed &&
        isExpired(now)) {
      throw StateError('This request has expired and cannot be accepted.');
    }
  }
}

class ProviderEarnings {
  ProviderEarnings(Iterable<Booking> bookings, DateTime now)
    : completedCount = bookings
          .where((b) => b.status == BookingStatus.completed)
          .length,
      entries = bookings.where((b) => b.earnsRevenue).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!)),
      month = DateTime(now.year, now.month);

  final List<Booking> entries;
  final int completedCount;
  final DateTime month;

  double get monthlyTotal => entries
      .where((b) {
        final date = b.completedAt!.toLocal();
        return date.year == month.year && date.month == month.month;
      })
      .fold(0.0, (total, b) => total + b.providerPayout!);

  double get total =>
      entries.fold(0.0, (total, b) => total + b.providerPayout!);
}
