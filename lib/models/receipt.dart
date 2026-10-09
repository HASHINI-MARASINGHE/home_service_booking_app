import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking.dart';

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
    this.paymentStatus = '',
    this.paymentNote = '',
    this.verificationCode = '',
  });

  final String bookingId, receiptNumber, bookingReference;
  final List<BookingLineItem> lineItems;
  final double totalAmount;
  final DateTime? issuedAt, signedOffAt, serviceDate;
  final String startTime, endTime, providerName, providerTitle;
  final String? providerPhotoUrl, cardLast4;
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
      paymentStatus: _text(data['paymentStatus']),
      paymentNote: _text(data['paymentNote']),
      verificationCode: _text(data['verificationCode']),
    );
  }

  /// Text encoded in the receipt's verification QR code.
  String get verificationPayload => verificationCode.isNotEmpty
      ? verificationCode
      : 'HOMECARE|$receiptNumber|$bookingReference|${totalAmount.round()}';
}
