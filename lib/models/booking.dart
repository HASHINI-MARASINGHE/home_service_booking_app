import 'package:cloud_firestore/cloud_firestore.dart';

import 'quote.dart';

enum BookingStatus {
  pending,
  confirmed,
  // Set by the trusted dispatch backend while the professional travels/works.
  onTheWay,
  inProgress,
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
    onTheWay => 'On the way',
    inProgress => 'In progress',
    declined => 'Declined',
    completed => 'Completed',
    cancelled => 'Cancelled',
    unknown => 'Unknown status',
  };

  bool get isHistory =>
      this == completed || this == declined || this == cancelled;

  /// Customer "Upcoming" tab: everything still scheduled or underway.
  bool get isUpcoming =>
      this == pending ||
      this == confirmed ||
      this == onTheWay ||
      this == inProgress;
}

/// One priced row in a booking's payment summary.
class BookingLineItem {
  const BookingLineItem({
    required this.label,
    required this.amount,
    this.detail = '',
  });

  final String label, detail;
  final double amount;

  static List<BookingLineItem> listFrom(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map &&
            item['label'] is String &&
            item['amount'] is num &&
            (item['amount'] as num).isFinite)
          BookingLineItem(
            label: item['label'] as String,
            amount: (item['amount'] as num).toDouble(),
            detail: item['detail'] is String ? item['detail'] as String : '',
          ),
    ];
  }

  Map<String, dynamic> toMap() => {
    'label': label,
    'detail': detail,
    'amount': amount,
  };
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
    this.reference,
    this.providerName,
    this.serviceDetail,
    this.serviceTier,
    this.addressId,
    this.addressLabel,
    this.addressArea,
    this.accessNotes = '',
    this.contactPhone = '',
    this.jobNotes = '',
    this.photoUrls = const [],
    this.lineItems = const [],
    this.slotDate,
    this.startTime,
    this.endTime,
    this.endAt,
    this.slotLockId,
    this.cardLast4,
    this.cancelledAt,
    this.cancellationReason,
    this.cancellationFee,
    this.refundAmount,
    this.addressNeedsUpdate = false,
    this.updatedAt,
    this.quoteStatus,
    this.quotedAmount,
    this.quoteNote,
    this.acceptedAmount,
    this.quoteHistory = const [],
    this.quoteUpdatedAt,
  });

  final String id, customerId, providerId, serviceName, customerName, address;
  final String? serviceId, paymentMethod, paymentStatus, payoutNote;

  // Customer booking-management fields. All optional so provider-side
  // documents created before these screens still parse.
  final String? reference, providerName, serviceDetail, serviceTier;
  final String? addressId, addressLabel, addressArea;
  final String accessNotes, contactPhone, jobNotes;
  final List<String> photoUrls;
  final List<BookingLineItem> lineItems;

  /// Colombo wall-clock slot: `2024-11-14`, `10:00`, `11:30`.
  final String? slotDate, startTime, endTime, slotLockId;
  final DateTime? endAt, cancelledAt, updatedAt;
  final String? cardLast4, cancellationReason;
  final double? cancellationFee, refundAmount;
  final bool addressNeedsUpdate;

  /// Provider quote flow. `quoteStatus` is null for bookings made before
  /// quotes existed; those keep the price they were created with.
  final QuoteStatus? quoteStatus;
  final double? quotedAmount, acceptedAmount;
  final String? quoteNote;
  final List<QuoteEntry> quoteHistory;
  final DateTime? quoteUpdatedAt;
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
  static String? _optional(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;
  static Timestamp? _stamp(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);

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
    reference: _optional(data['reference']),
    providerName: _optional(data['providerName']),
    serviceDetail: _optional(data['serviceDetail']),
    serviceTier: _optional(data['serviceTier']),
    addressId: _optional(data['addressId']),
    addressLabel: _optional(data['addressLabel']),
    addressArea: _optional(data['addressArea']),
    accessNotes: _text(data['accessNotes'], ''),
    contactPhone: _text(data['contactPhone'], ''),
    jobNotes: _text(data['jobNotes'], ''),
    photoUrls: (data['photoUrls'] is List)
        ? (data['photoUrls'] as List).whereType<String>().toList()
        : const [],
    lineItems: BookingLineItem.listFrom(data['lineItems']),
    slotDate: _optional(data['slotDate']),
    startTime: _optional(data['startTime']),
    endTime: _optional(data['endTime']),
    endAt: _date(data['endAt']),
    slotLockId: _optional(data['slotLockId']),
    cardLast4: _optional(data['cardLast4']),
    cancelledAt: _date(data['cancelledAt']),
    cancellationReason: _optional(data['cancellationReason']),
    cancellationFee: _money(data['cancellationFee']),
    refundAmount: _money(data['refundAmount']),
    addressNeedsUpdate: data['addressNeedsUpdate'] == true,
    updatedAt: _date(data['updatedAt']),
    quoteStatus: QuoteStatus.parse(data['quoteStatus']),
    quotedAmount: _money(data['quotedAmount']),
    quoteNote: _optional(data['quoteNote']),
    acceptedAmount: _money(data['acceptedAmount']),
    quoteHistory: QuoteEntry.listFrom(data['quoteHistory']),
    quoteUpdatedAt: _date(data['quoteUpdatedAt']),
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
    'reference': reference,
    'providerName': providerName,
    'serviceDetail': serviceDetail,
    'serviceTier': serviceTier,
    'addressId': addressId,
    'addressLabel': addressLabel,
    'addressArea': addressArea,
    'accessNotes': accessNotes,
    'contactPhone': contactPhone,
    'jobNotes': jobNotes,
    'photoUrls': photoUrls,
    'lineItems': [for (final item in lineItems) item.toMap()],
    'slotDate': slotDate,
    'startTime': startTime,
    'endTime': endTime,
    'endAt': _stamp(endAt),
    'slotLockId': slotLockId,
    'cardLast4': cardLast4,
    'cancelledAt': _stamp(cancelledAt),
    'cancellationReason': cancellationReason,
    'cancellationFee': cancellationFee,
    'refundAmount': refundAmount,
    'addressNeedsUpdate': addressNeedsUpdate,
    'updatedAt': _stamp(updatedAt),
    if (quoteStatus != null) ...{
      'quoteStatus': quoteStatus!.name,
      'quoteCurrency': QuoteInput.currency,
      'quotedAmount': quotedAmount,
      'quoteNote': quoteNote,
      'acceptedAmount': acceptedAmount,
      'quoteHistory': [for (final entry in quoteHistory) entry.toMap()],
      'quoteUpdatedAt': _stamp(quoteUpdatedAt),
    },
  };

  /// `BK-78924`; falls back to a short form of the document ID.
  String get displayReference {
    final ref = reference;
    if (ref != null) return ref;
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'BK-${short.toUpperCase()}';
  }

  /// True once this booking uses the quote flow.
  bool get usesQuotes => quoteStatus != null;

  /// The price both sides agreed to, or null while there is none. Bookings
  /// made before quotes existed keep the price they were created with.
  double? get approvedAmount {
    if (acceptedAmount != null) return acceptedAmount;
    if (usesQuotes) return null;
    final legacy = totalAmount ?? estimatedPrice;
    return legacy != null && legacy > 0 ? legacy : null;
  }

  /// What the customer was or will be charged: the approved price, never an
  /// estimate. Zero until a quote is accepted.
  double get chargeTotal =>
      approvedAmount ?? (usesQuotes ? 0 : totalAmount ?? estimatedPrice ?? 0);

  /// A quote (or a revised quote) is waiting for the customer.
  bool get awaitingCustomer => quoteStatus == QuoteStatus.quoted;

  /// The waiting quote replaces an amount the customer already approved.
  bool get isRevision => awaitingCustomer && acceptedAmount != null;

  /// The customer said no to a revision; the earlier amount still stands.
  bool get revisionDeclined =>
      quoteStatus == QuoteStatus.declined && acceptedAmount != null;

  /// The provider may send (or re-send) a first quote.
  bool get canSendQuote =>
      status == BookingStatus.pending &&
      !awaitingCustomer &&
      quoteStatus != QuoteStatus.accepted;

  /// The provider may change the price of a confirmed job.
  bool get canReviseQuote =>
      status == BookingStatus.confirmed && !awaitingCustomer;

  /// Old requests (made before quotes) can still be accepted directly. New
  /// ones are confirmed when the customer accepts the quote.
  bool get canAcceptWithoutQuote =>
      status == BookingStatus.pending && !usesQuotes;

  /// The customer can answer the quote now.
  bool get canAnswerQuote =>
      awaitingCustomer &&
      (status == BookingStatus.pending || status == BookingStatus.confirmed);

  /// Why the job cannot be marked complete yet, or null when it can.
  String? get completionBlocker {
    if (awaitingCustomer) {
      return 'Wait for the customer to answer your quote before completing '
          'this job.';
    }
    if (approvedAmount == null) {
      return 'This job has no approved price yet. Send a quote and wait for '
          'the customer to accept it.';
    }
    return null;
  }

  /// Card/online payments are captured up front and held in escrow.
  bool get isPrepaid =>
      paymentStatus == 'escrow' ||
      paymentStatus == 'paid' ||
      paymentStatus == 'refund_pending' ||
      paymentStatus == 'refunded';

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
    if (target == BookingStatus.confirmed && usesQuotes) {
      throw StateError(
        'Send a quote. The job is confirmed when the customer accepts it.',
      );
    }
    if (target == BookingStatus.completed && completionBlocker != null) {
      throw StateError(completionBlocker!);
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
