import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundStatus {
  initiated,
  processing,
  refunded,
  failed;

  static RefundStatus parse(Object? value) => RefundStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => RefundStatus.initiated,
  );
}

/// Refund record at `refunds/{bookingId}`. The customer creates it in the
/// same transaction that cancels the booking (security rules check the
/// amount); only the payment backend advances [status].
class Refund {
  const Refund({
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.refundReference,
    this.cancellationFee = 0,
    this.percentage = 100,
    this.method = '',
    this.cardLast4,
    this.reason = '',
    this.gateway = '',
    this.bankName = '',
    this.createdAt,
    this.processingAt,
    this.refundedAt,
  });

  final String bookingId, refundReference, method, reason, gateway, bankName;
  final String? cardLast4;
  final double amount, cancellationFee;
  final int percentage;
  final RefundStatus status;
  final DateTime? createdAt, processingAt, refundedAt;

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
  static double _money(Object? value) =>
      value is num && value.isFinite && value >= 0 ? value.toDouble() : 0;
  static String _text(Object? value) => value is String ? value : '';

  factory Refund.fromMap(String bookingId, Map<String, dynamic> data) => Refund(
    bookingId: bookingId,
    amount: _money(data['amount']),
    cancellationFee: _money(data['cancellationFee']),
    percentage: (data['percentage'] as num?)?.round() ?? 100,
    status: RefundStatus.parse(data['status']),
    refundReference: _text(data['refundReference']),
    method: _text(data['method']),
    cardLast4: data['cardLast4'] is String ? data['cardLast4'] as String : null,
    reason: _text(data['reason']),
    gateway: _text(data['gateway']),
    bankName: _text(data['bankName']),
    createdAt: _date(data['createdAt']),
    processingAt: _date(data['processingAt']),
    refundedAt: _date(data['refundedAt']),
  );
}
