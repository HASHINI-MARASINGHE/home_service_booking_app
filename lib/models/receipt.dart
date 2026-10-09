import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking.dart';
import 'professional.dart';

/// Invoice issued by the backend when a job is signed off, stored at
/// `receipts/{bookingId}`. Read-only for customers.
class Receipt {
  const Receipt({
    required this.bookingId,
    required this.receiptNumber,
    required this.bookingReference,
    required this.lineItems,
    required this.totalAmount,
    this.issuedAt,
    this.signedOffAt,
    this.serviceDate,
    this.startTime = '',
    this.endTime = '',
    this.providerName = '',
    this.providerTitle = '',
    this.providerPhotoUrl,
    this.licenseNumber = '',
    this.customerName = '',
    this.serviceAddress = '',
    this.paymentMethod = '',
    this.cardLast4,
    this.cardBrand,
    this.cardIsDefault = false,
    this.paymentStatus = '',
    this.paymentNote = '',
    this.verificationCode = '',
  });

  final String bookingId, receiptNumber, bookingReference;
  final List<BookingLineItem> lineItems;
  final double totalAmount;
  final DateTime? issuedAt, signedOffAt, serviceDate;
  final String startTime, endTime, providerName, providerTitle;
  final String? providerPhotoUrl, cardLast4, cardBrand;

  /// The card is the customer's default saved card, not one recorded on the
  /// booking itself.
  final bool cardIsDefault;
  final String licenseNumber, customerName, serviceAddress;
  final String paymentMethod, paymentStatus, paymentNote, verificationCode;

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
  static String _text(Object? value) => value is String ? value : '';

  factory Receipt.fromMap(String bookingId, Map<String, dynamic> data) {
    final items = BookingLineItem.listFrom(data['lineItems']);
    final total = data['totalAmount'];
    final photo = data['providerPhotoUrl'];
    final card = data['cardLast4'];
    return Receipt(
      bookingId: bookingId,
      receiptNumber: _text(data['receiptNumber']),
      bookingReference: _text(data['bookingReference']),
      lineItems: items,
      totalAmount: total is num && total.isFinite
          ? total.toDouble()
          : items.fold(0, (running, item) => running + item.amount),
      issuedAt: _date(data['issuedAt']),
      signedOffAt: _date(data['signedOffAt']),
      serviceDate: _date(data['serviceDate']),
      startTime: _text(data['startTime']),
      endTime: _text(data['endTime']),
      providerName: _text(data['providerName']),
      providerTitle: _text(data['providerTitle']),
      providerPhotoUrl: photo is String && photo.isNotEmpty ? photo : null,
      licenseNumber: _text(data['licenseNumber']),
      customerName: _text(data['customerName']),
      serviceAddress: _text(data['serviceAddress']),
      paymentMethod: _text(data['paymentMethod']),
      cardLast4: card is String && card.isNotEmpty ? card : null,
      cardBrand:
          data['cardBrand'] is String &&
              (data['cardBrand'] as String).isNotEmpty
          ? data['cardBrand'] as String
          : null,
      paymentStatus: _text(data['paymentStatus']),
      paymentNote: _text(data['paymentNote']),
      verificationCode: _text(data['verificationCode']),
    );
  }

  /// Receipt for a completed booking whose `receipts` document has not been
  /// issued yet. Every value comes from the booking and its own [professional].
  /// The amount is the price the customer approved (accepted quote), split into
  /// the service line (with the provider's quote note) and any platform fee.
  /// The number uses the backend worker's `INV-{year}-{id tail}` scheme.
  ///
  /// A booking made through the app records no card, so [fallbackCardBrand] /
  /// [fallbackCardLast4] (the customer's default saved card) are used for the
  /// payment section when the booking has none.
  factory Receipt.fromBooking(
    Booking booking,
    Professional? professional, {
    String? fallbackCardBrand,
    String? fallbackCardLast4,
  }) {
    final signedOff = booking.completedAt;
    final fee = booking.serviceFee ?? 0;
    final total = booking.chargeTotal;
    final itemSum = booking.lineItems.fold<double>(
      0,
      (running, item) => running + item.amount,
    );
    final detail = booking.quoteNote ?? booking.serviceDetail ?? '';
    // Stored lines are kept only when they add up to what was approved.
    final items = booking.lineItems.isNotEmpty && (itemSum - total).abs() < 0.5
        ? booking.lineItems
        : [
            BookingLineItem(
              label: booking.serviceName,
              detail: detail,
              amount: total >= fee ? total - fee : total,
            ),
            if (fee > 0 && total >= fee)
              BookingLineItem(label: 'Platform service fee', amount: fee),
          ];
    final id = booking.id;
    final tail = (id.length > 4 ? id.substring(id.length - 4) : id)
        .toUpperCase();
    final ownCard = booking.cardLast4 != null;
    final useFallback = !ownCard && fallbackCardLast4 != null;
    return Receipt(
      bookingId: id,
      receiptNumber:
          'INV-${(signedOff ?? booking.scheduledAt ?? DateTime.now()).year}-$tail',
      bookingReference: booking.displayReference,
      lineItems: items,
      totalAmount: total,
      signedOffAt: signedOff,
      serviceDate: booking.scheduledAt,
      startTime: booking.startTime ?? '',
      endTime: booking.endTime ?? '',
      providerName: professional?.name ?? booking.providerName ?? '',
      providerTitle: professional?.specialty ?? '',
      providerPhotoUrl: professional?.photoUrl,
      licenseNumber: professional?.licenseNumber ?? '',
      customerName: booking.customerName,
      serviceAddress: booking.address,
      paymentMethod: useFallback ? 'card' : booking.paymentMethod ?? '',
      cardLast4: ownCard ? booking.cardLast4 : fallbackCardLast4,
      cardBrand: useFallback ? fallbackCardBrand : null,
      cardIsDefault: useFallback,
      paymentStatus: booking.paymentStatus ?? '',
    );
  }

  /// Text encoded in the receipt's verification QR code.
  String get verificationPayload => verificationCode.isNotEmpty
      ? verificationCode
      : 'HOMECARE|$receiptNumber|$bookingReference|${totalAmount.round()}';
}
