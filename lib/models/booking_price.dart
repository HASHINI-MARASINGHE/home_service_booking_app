import '../utils/formatters.dart';
import 'booking.dart';
import 'quote.dart';

/// The short price line each side sees on a booking. One place, so a price
/// never shows as "LKR 0" or "Not provided" anywhere.
abstract final class BookingPrice {
  /// For the customer: a status chip like "Quote pending".
  static String forCustomer(Booking b) {
    final approved = b.approvedAmount;
    if (b.awaitingCustomer) {
      return b.isRevision
          ? 'Revised quote: ${Formatters.lkr(b.quotedAmount)}'
          : 'Quote received: ${Formatters.lkr(b.quotedAmount)}';
    }
    if (approved != null) {
      return b.status == BookingStatus.completed
          ? 'Paid price: ${Formatters.lkr(approved)}'
          : 'Confirmed: ${Formatters.lkr(approved)}';
    }
    if (b.status.isHistory) return 'No price agreed';
    return 'Quote pending';
  }

  /// For the provider: what still needs doing, or the approved amount.
  static String forProvider(Booking b) {
    final approved = b.approvedAmount;
    if (b.awaitingCustomer) {
      return b.isRevision ? 'Revision awaiting customer' : 'Awaiting customer';
    }
    if (approved != null) return 'Approved: ${Formatters.lkr(approved)}';
    if (b.status.isHistory) return 'No price agreed';
    if (b.quoteStatus == QuoteStatus.declined) return 'Quote declined';
    return 'Quote not sent';
  }

  /// The big amount on a detail card, or [none] while nothing is agreed.
  static String amountOr(Booking b, String none) {
    final approved = b.approvedAmount;
    return approved == null ? none : Formatters.lkr(approved);
  }
}
