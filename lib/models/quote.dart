import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a booking's price is in the quote flow.
///
/// `pending`: the provider has not sent a price yet.
/// `quoted`: a price (or a revised price) waits for the customer.
/// `accepted`: the customer approved it; the amount is locked.
/// `declined`: the customer said no. On a confirmed job this only means the
/// *revision* was declined, and the earlier accepted amount still stands.
enum QuoteStatus {
  pending,
  quoted,
  accepted,
  declined;

  /// `null` means the booking was made before quotes existed.
  static QuoteStatus? parse(Object? value) {
    if (value is! String) return null;
    return QuoteStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => QuoteStatus.pending,
    );
  }
}

/// One line of a booking's price history, so every revision can be audited.
class QuoteEntry {
  const QuoteEntry({
    required this.amount,
    required this.status,
    required this.createdAt,
    this.note,
    this.reason,
  });

  final double amount;
  final QuoteStatus status;
  final DateTime createdAt;

  /// What the price includes (sent by the provider).
  final String? note;

  /// Why a confirmed job's price changed (required for revisions).
  final String? reason;

  static List<QuoteEntry> listFrom(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map &&
            item['amount'] is num &&
            (item['amount'] as num).isFinite)
          QuoteEntry(
            amount: (item['amount'] as num).toDouble(),
            status: QuoteStatus.parse(item['status']) ?? QuoteStatus.pending,
            createdAt: item['createdAt'] is Timestamp
                ? (item['createdAt'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(0),
            note: item['note'] is String ? item['note'] as String : null,
            reason: item['reason'] is String ? item['reason'] as String : null,
          ),
    ];
  }

  /// Firestore does not allow server timestamps inside a list, so the time is
  /// the device clock. The booking's own `quoteUpdatedAt` is the trusted one.
  Map<String, dynamic> toMap() => {
    'amount': amount,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'note': note,
    'reason': reason,
  };
}

/// Rules for what a person may type as a price or a reason.
abstract final class QuoteInput {
  static const currency = 'LKR';
  static const maxAmount = 10000000.0;
  static const maxNote = 500;
  static const maxReason = 300;
  static const minReason = 3;

  /// The amount in whole rupees, or an error message for the form field.
  static ({double? amount, String? error}) parseAmount(String? text) {
    final raw = (text ?? '').replaceAll(',', '').trim();
    if (raw.isEmpty) return (amount: null, error: 'Enter your price in LKR.');
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite) {
      return (amount: null, error: 'Enter numbers only, like 3500.');
    }
    if (value <= 0) {
      return (amount: null, error: 'The price must be more than 0.');
    }
    if (value != value.roundToDouble()) {
      return (amount: null, error: 'Use whole rupees, like 3500.');
    }
    if (value > maxAmount) {
      return (amount: null, error: 'That price is too high. Check it again.');
    }
    return (amount: value, error: null);
  }

  static String? validateNote(String? text) =>
      (text ?? '').trim().length > maxNote
      ? 'Keep this under $maxNote characters.'
      : null;

  static String? validateReason(String? text) {
    final length = (text ?? '').trim().length;
    if (length < minReason) return 'Tell the customer why the price changed.';
    if (length > maxReason) return 'Keep this under $maxReason characters.';
    return null;
  }
}

/// Limits on a booking's price history.
abstract final class QuoteHistory {
  /// Quotes, revisions and answers together; keeps the document small.
  static const maxEntries = 40;
}
