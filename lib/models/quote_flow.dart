import '../services/app_error.dart';
import '../utils/formatters.dart';
import 'booking.dart';
import 'quote.dart';

/// What one quote action writes to the booking, and the notice that goes
/// with it. Server timestamps (`quoteUpdatedAt`, `updatedAt`, and `acceptedAt`
/// when [confirmsJob]) are added by the service that commits it.
class QuoteChange {
  const QuoteChange({
    required this.fields,
    required this.entry,
    required this.title,
    required this.body,
    this.confirmsJob = false,
  });

  final Map<String, Object?> fields;
  final QuoteEntry entry;

  /// The customer's accept turns a request into a confirmed job.
  final bool confirmsJob;

  /// The in-app notification for the other person.
  final String title, body;
}

/// Every state change of the quote flow, as pure functions of the booking.
/// `ProviderBookingService` and `CustomerBookingService` run these inside
/// their Firestore transactions, and `firestore.rules` enforces the same
/// rules on the server, so a changed app cannot skip a step.
abstract final class QuoteFlow {
  /// The provider sends a first quote ([reason] null) or revises a confirmed
  /// job's price ([reason] given). The customer must answer either one.
  static QuoteChange send(
    Booking b, {
    required String uid,
    required double amount,
    String? note,
    String? reason,
    required DateTime now,
  }) {
    final revision = reason != null;
    final amountError = QuoteInput.parseAmount(amount.toStringAsFixed(0));
    if (amountError.error != null || amount != amount.roundToDouble()) {
      throw ArgumentError(amountError.error ?? 'Use whole rupees.');
    }
    final noteError = QuoteInput.validateNote(note);
    if (noteError != null) throw ArgumentError(noteError);
    if (revision) {
      final reasonError = QuoteInput.validateReason(reason);
      if (reasonError != null) throw ArgumentError(reasonError);
    }
    if (b.providerId != uid) {
      throw StateError('This job is not assigned to you.');
    }
    if (b.awaitingCustomer) {
      throw StateError(
        'Your quote is waiting for the customer. You can send a new one '
        'after they answer.',
      );
    }
    if (revision ? !b.canReviseQuote : !b.canSendQuote) {
      throw StateError(
        revision
            ? 'Only a confirmed job can have its price revised.'
            : 'This request has changed. Refresh and try again.',
      );
    }
    if (!revision && b.isExpired(now)) {
      throw StateError('This request has expired and can no longer be quoted.');
    }
    if (revision && amount == b.approvedAmount) {
      throw ArgumentError('Enter a price different from the current one.');
    }
    _checkHistory(b);
    final cleanNote = (note ?? '').trim();
    final entry = QuoteEntry(
      amount: amount,
      status: QuoteStatus.quoted,
      createdAt: now,
      note: cleanNote.isEmpty ? null : cleanNote,
      reason: reason?.trim(),
    );
    final who = b.providerName ?? 'Your provider';
    return QuoteChange(
      entry: entry,
      fields: {
        'quoteStatus': QuoteStatus.quoted.name,
        'quotedAmount': amount,
        'quoteNote': entry.note,
        'quoteHistory': _history(b, entry),
      },
      title: revision ? 'Revised quote received' : 'New quote received',
      body: revision
          ? '$who changed the price of ${b.serviceName} to '
                '${Formatters.lkr(amount)}. Please review it.'
          : 'New quote from $who: ${Formatters.lkr(amount)} for '
                '${b.serviceName}.',
    );
  }

  /// The customer accepts or declines the quote they were shown.
  /// [shownAmount] is the price on their screen: if the provider changed it
  /// since, the answer is refused rather than applied to a price they have
  /// not seen.
  static QuoteChange answer(
    Booking b, {
    required String uid,
    required double shownAmount,
    required bool accept,
    required DateTime now,
  }) {
    if (b.customerId != uid) {
      throw StateError('You can only answer quotes on your own bookings.');
    }
    if (!b.canAnswerQuote) {
      throw BookingChangedException(
        b.status == BookingStatus.cancelled
            ? 'This booking was cancelled, so the quote is closed.'
            : 'This quote was already answered or withdrawn. Refresh to see '
                  'the latest.',
      );
    }
    if (b.quotedAmount != shownAmount) {
      throw const BookingChangedException(
        'The provider updated this quote. Please review the new price before '
        'answering.',
      );
    }
    final confirms = accept && b.status == BookingStatus.pending;
    if (confirms && !(b.scheduledAt?.isAfter(now) ?? false)) {
      throw const BookingChangedException(
        'The booked time has passed. Please book a new time.',
      );
    }
    _checkHistory(b);
    final revision = b.isRevision;
    final entry = QuoteEntry(
      amount: shownAmount,
      status: accept ? QuoteStatus.accepted : QuoteStatus.declined,
      createdAt: now,
    );
    final who = b.customerName;
    final amount = Formatters.lkr(shownAmount);
    return QuoteChange(
      entry: entry,
      confirmsJob: confirms,
      fields: {
        'quoteStatus': entry.status.name,
        if (accept) ...{
          'acceptedAmount': shownAmount,
          // The approved price is what refunds, fees and receipts use.
          'totalAmount': shownAmount,
          'laborCharge': shownAmount,
          if (confirms) 'status': BookingStatus.confirmed.name,
        },
        'quoteHistory': _history(b, entry),
      },
      title: accept
          ? (revision
                ? 'Revised quote accepted'
                : 'Customer accepted your quote')
          : (revision
                ? 'Revised quote declined'
                : 'Customer declined your quote'),
      body: accept
          ? '$who accepted $amount for ${b.serviceName}.'
                '${revision ? '' : ' The job is confirmed.'}'
          : '$who declined $amount for ${b.serviceName}.'
                '${revision ? ' The earlier price still applies.' : ' You can send a new quote.'}',
    );
  }

  static void _checkHistory(Booking b) {
    if (b.quoteHistory.length >= QuoteHistory.maxEntries) {
      throw StateError('This job has too many price changes. Contact support.');
    }
  }

  static List<Map<String, dynamic>> _history(Booking b, QuoteEntry next) => [
    for (final e in b.quoteHistory) e.toMap(),
    next.toMap(),
  ];

  /// What [change] looks like once applied, for showing the result at once
  /// and for tests. The services never use it to write.
  static Booking apply(Booking b, QuoteChange change, DateTime now) {
    final f = change.fields;
    final status = f['status'] == BookingStatus.confirmed.name
        ? BookingStatus.confirmed
        : b.status;
    return Booking(
      id: b.id,
      customerId: b.customerId,
      providerId: b.providerId,
      serviceName: b.serviceName,
      customerName: b.customerName,
      providerName: b.providerName,
      address: b.address,
      status: status,
      scheduledAt: b.scheduledAt,
      expiresAt: b.expiresAt,
      estimatedPrice: b.estimatedPrice,
      laborCharge: (f['laborCharge'] as double?) ?? b.laborCharge,
      serviceFee: b.serviceFee,
      totalAmount: (f['totalAmount'] as double?) ?? b.totalAmount,
      acceptedAt: change.confirmsJob ? now : b.acceptedAt,
      quoteStatus: QuoteStatus.parse(f['quoteStatus']),
      quotedAmount: f.containsKey('quotedAmount')
          ? f['quotedAmount'] as double?
          : b.quotedAmount,
      quoteNote: f.containsKey('quoteNote')
          ? f['quoteNote'] as String?
          : b.quoteNote,
      acceptedAmount: (f['acceptedAmount'] as double?) ?? b.acceptedAmount,
      quoteHistory: [...b.quoteHistory, change.entry],
      quoteUpdatedAt: now,
    );
  }
}
