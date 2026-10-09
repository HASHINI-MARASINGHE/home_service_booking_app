import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/quote_flow.dart';
import '../models/review.dart';

class ProviderBookingService {
  ProviderBookingService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  Stream<List<Booking>> watchBookings() {
    final uid = _uid;
    // A single equality query avoids composite indexes. Partition and sort
    // the provider's own records locally for this foundation.
    return _db
        .collection('bookings')
        .where('providerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          if (_auth.currentUser?.uid != uid) return <Booking>[];
          final bookings = snapshot.docs
              .map((doc) => Booking.fromMap(doc.id, doc.data()))
              .toList();
          bookings.sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );
          return bookings;
        });
  }

  /// The customer's review of one of this provider's jobs (null until
  /// reviewed). Rules only serve it to the customer and the provider.
  Stream<Review?> watchReview(String bookingId) => _db
      .collection('reviews')
      .doc(bookingId)
      .snapshots()
      .map((doc) => Review.fromMap(doc.id, doc.data()));

  Stream<List<Booking>> watchRequests() => watchBookings().map(
    (items) => items.where((b) => b.status == BookingStatus.pending).toList(),
  );
  Stream<List<Booking>> watchConfirmed() => watchBookings().map(
    (items) => items.where((b) => b.status == BookingStatus.confirmed).toList(),
  );
  Stream<List<Booking>> watchHistory() => watchBookings().map(
    (items) => items.where((b) => b.status.isHistory).toList(),
  );
  Stream<ProviderEarnings> watchEarnings() =>
      watchBookings().map((items) => ProviderEarnings(items, DateTime.now()));

  /// The provider confirms the customer paid for a finished cash job. Only
  /// paid jobs count towards earnings; the rules allow unpaid to paid only.
  Future<void> markPaid(String id) => _db.collection('bookings').doc(id).update({
    'paymentStatus': 'paid',
    'paidAt': FieldValue.serverTimestamp(),
  });

  Future<void> accept(String id) =>
      _transition(id, BookingStatus.confirmed, 'acceptedAt');
  Future<void> decline(String id) =>
      _transition(id, BookingStatus.declined, 'declinedAt');
  Future<void> complete(String id) =>
      _transition(id, BookingStatus.completed, 'completedAt');

  /// Sends the first (or a new) price for a request. The customer is told in
  /// the same commit, so a quote can never exist without its notification.
  Future<void> sendQuote(String id, double amount, {String? note}) =>
      _quote(id, amount, note: note);

  /// Changes the price of a confirmed job. The customer must approve it; the
  /// amount they already accepted stays valid until they do.
  Future<void> reviseQuote(
    String id,
    double amount, {
    required String reason,
    String? note,
  }) => _quote(id, amount, note: note, reason: reason);

  Future<void> _quote(
    String id,
    double amount, {
    String? note,
    String? reason,
  }) async {
    final uid = _uid;
    final ref = _db.collection('bookings').doc(id);
    await _db.runTransaction((transaction) async {
      if (_auth.currentUser?.uid != uid) {
        throw StateError('Please log in again.');
      }
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) throw StateError('This booking no longer exists.');
      final booking = Booking.fromMap(snapshot.id, data);
      final change = QuoteFlow.send(
        booking,
        uid: uid,
        amount: amount,
        note: note,
        reason: reason,
        now: DateTime.now(),
      );
      transaction.update(ref, {
        ...change.fields,
        'quoteUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        _db
            .collection('notifications')
            .doc(
              'quote_${booking.id}_${DateTime.now().millisecondsSinceEpoch}',
            ),
        {
          'recipientId': booking.customerId,
          'senderId': uid,
          'type': AppNotification.quoteType,
          'bookingId': booking.id,
          'title': change.title,
          'body': change.body,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  Future<void> _transition(
    String id,
    BookingStatus target,
    String timestamp,
  ) async {
    final uid = _uid;
    final ref = _db.collection('bookings').doc(id);
    await _db.runTransaction((transaction) async {
      if (_auth.currentUser?.uid != uid) {
        throw StateError('Please log in again.');
      }
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) throw StateError('This booking no longer exists.');
      final booking = Booking.fromMap(snapshot.id, data);
      if (booking.providerId != uid) {
        throw StateError('This job is not assigned to you.');
      }
      booking.validateTransition(target, DateTime.now());
      transaction.update(ref, {
        'status': target.name,
        timestamp: FieldValue.serverTimestamp(),
      });
    });
  }
}
