import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/address.dart';
import '../models/booking.dart';
import '../models/booking_policy.dart';
import '../models/professional.dart';
import '../models/receipt.dart';
import '../models/refund.dart';
import '../utils/formatters.dart';
import 'app_error.dart';

/// Customer-editable booking fields from the Edit Booking Details screen.
class BookingEdit {
  const BookingEdit({
    required this.address,
    required this.accessNotes,
    required this.contactPhone,
    required this.jobNotes,
    required this.keptPhotoUrls,
    this.addressId,
    this.addressLabel,
    this.addressArea,
    this.newPhotos = const [],
  });

  final String? addressId, addressLabel, addressArea;
  final String address, accessNotes, contactPhone, jobNotes;
  final List<String> keptPhotoUrls;
  final List<Uint8List> newPhotos;

  void validate() {
    final phone = contactPhone.replaceAll(RegExp(r'[\s-]'), '');
    if (address.trim().isEmpty) {
      throw ArgumentError('Choose a service address.');
    }
    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(phone)) {
      throw ArgumentError('Enter a valid contact phone number.');
    }
    if (accessNotes.length > BookingPolicy.maxAccessNotes ||
        jobNotes.length > BookingPolicy.maxJobNotes) {
      throw ArgumentError('Your notes are too long.');
    }
    if (keptPhotoUrls.length + newPhotos.length > BookingPolicy.maxPhotos) {
      throw ArgumentError(
        'You can attach up to ${BookingPolicy.maxPhotos} photos.',
      );
    }
  }
}

/// A new booking from the Book Service screen.
class BookingRequest {
  const BookingRequest({
    required this.professional,
    required this.serviceName,
    required this.slot,
    required this.address,
    required this.customerName,
  });

  final Professional professional;
  final String serviceName, customerName;
  final TimeSlot slot;
  final Address address;
}

class CancellationResult {
  const CancellationResult({
    required this.fee,
    required this.refundAmount,
    required this.refundReference,
  });

  final double fee, refundAmount;
  final String? refundReference;
}

/// Customer booking operations. Each state change runs in a Firestore
/// transaction and is re-validated by `firestore.rules`, so a modified client
/// cannot change prices, double-book a slot or skip status rules.
class CustomerBookingService {
  CustomerBookingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    DateTime Function()? clock,
  }) : _authOverride = auth,
       _dbOverride = firestore,
       _storageOverride = storage,
       _clock = clock ?? DateTime.now;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _dbOverride;
  final FirebaseStorage? _storageOverride;
  final DateTime Function() _clock;
  final _professionals = <String, Professional>{};

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  DateTime now() => _clock();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _booking(String id) =>
      _db.collection('bookings').doc(id);
  DocumentReference<Map<String, dynamic>> _lock(String id) =>
      _db.collection('slotLocks').doc(id);

  Stream<List<Booking>> watchBookings() {
    final uid = _uid;
    // Single equality filter: no composite index, sorted locally.
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Booking.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort(
                  (a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(
                    b.scheduledAt ?? DateTime(9999),
                  ),
                ),
        );
  }

  Stream<Booking?> watchBooking(String id) {
    final uid = _uid;
    return _booking(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final booking = Booking.fromMap(doc.id, data);
      return booking.customerId == uid ? booking : null;
    });
  }

  Future<Professional?> getProfessional(
    String providerId, {
    bool refresh = false,
  }) async {
    if (providerId.isEmpty) return null;
    if (!refresh && _professionals.containsKey(providerId)) {
      return _professionals[providerId];
    }
    final doc = await _db.collection('professionals').doc(providerId).get();
    final data = doc.data();
    if (data == null) return null;
    return _professionals[providerId] = Professional.fromMap(doc.id, data);
  }

  /// One provider's public listing, live; null once it no longer exists.
  Stream<Professional?> watchProfessional(String id) =>
      _db.collection('professionals').doc(id).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return _professionals[id] = Professional.fromMap(doc.id, data);
      });

  /// Public provider directory: verified first, then by rating and name.
  Stream<List<Professional>> watchProfessionals({int limit = 50}) =>
      _db.collection('professionals').limit(limit).snapshots().map((snapshot) {
        final list =
            snapshot.docs
                .map((doc) => Professional.fromMap(doc.id, doc.data()))
                .toList()
              ..sort((a, b) {
                if (a.verified != b.verified) return a.verified ? -1 : 1;
                final byRating = (b.rating ?? -1).compareTo(a.rating ?? -1);
                return byRating != 0 ? byRating : a.name.compareTo(b.name);
              });
        for (final pro in list) {
          _professionals[pro.id] = pro;
        }
        return list;
      });

  Stream<Refund?> watchRefund(String bookingId) =>
      _db.collection('refunds').doc(bookingId).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : Refund.fromMap(doc.id, data);
      });

  Future<Receipt?> getReceipt(String bookingId) async {
    final doc = await _db.collection('receipts').doc(bookingId).get();
    final data = doc.data();
    return data == null ? null : Receipt.fromMap(doc.id, data);
  }

  // ---------------------------------------------------------------------
  // Rescheduling
  // ---------------------------------------------------------------------

  /// Slots for [date]. Lock documents use deterministic IDs, so availability
  /// is a handful of direct reads rather than a query over other customers'
  /// bookings.
  Future<List<TimeSlot>> availableSlots({
    required Booking booking,
    required Professional professional,
    required DateTime date,
  }) async {
    final iso = Formatters.isoDate(date);
    final docs = await Future.wait([
      for (final (start, _) in professional.workingSlots)
        _lock(BookingPolicy.slotLockId(booking.providerId, iso, start)).get(),
    ]);
    final locks = <String, String>{
      for (final doc in docs)
        if (doc.exists &&
            doc.data()?['startTime'] is String &&
            doc.data()?['bookingId'] is String)
          doc.data()!['startTime'] as String:
              doc.data()!['bookingId'] as String,
    };
    return BookingPolicy.buildSlots(
      professional: professional,
      date: date,
      locks: locks,
      bookingId: booking.id,
      now: now(),
    );
  }

  /// Bookable slots for [professional] on [date] (new bookings).
  Future<List<TimeSlot>> openSlots({
    required Professional professional,
    required DateTime date,
  }) async {
    final iso = Formatters.isoDate(date);
    final docs = await Future.wait([
      for (final (start, _) in professional.workingSlots)
        _lock(BookingPolicy.slotLockId(professional.id, iso, start)).get(),
    ]);
    final locks = <String, String>{
      for (final doc in docs)
        if (doc.exists &&
            doc.data()?['startTime'] is String &&
            doc.data()?['bookingId'] is String)
          doc.data()!['startTime'] as String:
              doc.data()!['bookingId'] as String,
    };
    return BookingPolicy.buildSlots(
      professional: professional,
      date: date,
      locks: locks,
      bookingId: '',
      now: now(),
    );
  }

  /// Creates a pending booking and its slot lock in one transaction, so two
  /// customers can never take the same slot. Returns the new booking ID.
  Future<String> createBooking(BookingRequest request) async {
    final uid = _uid;
    final pro = request.professional;
    final slot = request.slot;
    if (pro.id == uid) throw ArgumentError('You cannot book yourself.');
    if (!slot.startsAt.isAfter(now().add(BookingPolicy.freeChangeWindow))) {
      throw const BookingChangedException(
        'Choose a slot at least 2 hours from now.',
      );
    }
    final bookingRef = _db.collection('bookings').doc();
    final lockId = BookingPolicy.slotLockId(pro.id, slot.isoDate, slot.start);
    final a = request.address;
    await _db.runTransaction((tx) async {
      final lock = await tx.get(_lock(lockId));
      if (lock.exists) throw const SlotTakenException();
      tx.set(bookingRef, {
        'reference': 'BK-${10000 + Random.secure().nextInt(90000)}',
        'customerId': uid,
        'customerName': request.customerName,
        'providerId': pro.id,
        'providerName': pro.name,
        'serviceName': request.serviceName,
        'status': BookingStatus.pending.name,
        'slotDate': slot.isoDate,
        'startTime': slot.start,
        'endTime': slot.end,
        'scheduledAt': Timestamp.fromDate(slot.startsAt),
        'endAt': Timestamp.fromDate(
          BookingPolicy.colomboInstant(slot.date, slot.end),
        ),
        'slotLockId': lockId,
        'addressId': a.id,
        'address': a.line,
        'addressLabel': a.label,
        'addressArea': a.province,
        'accessNotes': a.accessNotes,
        'contactPhone': '',
        'jobNotes': '',
        'photoUrls': <String>[],
        // The provider's published starting price; null = priced on site.
        'estimatedPrice': pro.pricing,
        'totalAmount': pro.pricing,
        'laborCharge': pro.pricing,
        'serviceFee': 0,
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(_lock(lockId), {
        'providerId': pro.id,
        'date': slot.isoDate,
        'startTime': slot.start,
        'endTime': slot.end,
        'bookingId': bookingRef.id,
      });
    });
    return bookingRef.id;
  }

  Future<void> reschedule(Booking booking, TimeSlot slot) async {
    final uid = _uid;
    final newLockId = BookingPolicy.slotLockId(
      booking.providerId,
      slot.isoDate,
      slot.start,
    );
    final endsAt = BookingPolicy.colomboInstant(slot.date, slot.end);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(_booking(booking.id));
      final data = snapshot.data();
      if (data == null) throw StateError('This booking no longer exists.');
      final current = Booking.fromMap(snapshot.id, data);
      if (current.customerId != uid) {
        throw StateError('You can only change your own bookings.');
      }
      if (!BookingPolicy.canReschedule(current, now())) {
        throw const BookingChangedException(
          'This booking can no longer be rescheduled online. '
          'Changes close 2 hours before the start time.',
        );
      }
      if (!slot.startsAt.isAfter(now().add(BookingPolicy.freeChangeWindow))) {
        throw const BookingChangedException(
          'Choose a slot at least 2 hours from now.',
        );
      }
      if (current.slotLockId == newLockId) return;
      final lock = await tx.get(_lock(newLockId));
      if (lock.exists) throw const SlotTakenException();
      tx.set(_lock(newLockId), {
        'providerId': current.providerId,
        'date': slot.isoDate,
        'startTime': slot.start,
        'endTime': slot.end,
        'bookingId': current.id,
      });
      final oldLock = current.slotLockId;
      if (oldLock != null) tx.delete(_lock(oldLock));
      tx.update(snapshot.reference, {
        'slotDate': slot.isoDate,
        'startTime': slot.start,
        'endTime': slot.end,
        'scheduledAt': Timestamp.fromDate(slot.startsAt),
        'endAt': Timestamp.fromDate(endsAt),
        'slotLockId': newLockId,
        'rescheduledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------
  // Cancellation and refund
  // ---------------------------------------------------------------------

  Future<CancellationResult> cancel(Booking booking, String reason) async {
    if (!BookingPolicy.cancellationReasons.contains(reason)) {
      throw ArgumentError('Choose a cancellation reason.');
    }
    final uid = _uid;
    return _db.runTransaction((tx) async {
      final snapshot = await tx.get(_booking(booking.id));
      final data = snapshot.data();
      if (data == null) throw StateError('This booking no longer exists.');
      final current = Booking.fromMap(snapshot.id, data);
      if (current.customerId != uid) {
        throw StateError('You can only cancel your own bookings.');
      }
      if (!BookingPolicy.canCancel(current)) {
        throw BookingChangedException(
          'This booking is ${current.status.label.toLowerCase()} and can no '
          'longer be cancelled in the app. Please contact support.',
        );
      }
      final at = now();
      final fee = BookingPolicy.cancellationFee(current, at);
      final captured = BookingPolicy.hasCapturedPayment(current);
      final refund = BookingPolicy.refundAmount(current, at);
      final reference = captured ? BookingPolicy.newRefundReference() : null;

      tx.update(snapshot.reference, {
        'status': BookingStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'cancellationFee': fee,
        'refundAmount': refund,
        'paymentStatus': captured ? 'refund_pending' : current.paymentStatus,
        'slotLockId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final lock = current.slotLockId;
      if (lock != null) tx.delete(_lock(lock));
      if (captured) {
        tx.set(_db.collection('refunds').doc(current.id), {
          'bookingId': current.id,
          'customerId': uid,
          'amount': refund,
          'cancellationFee': fee,
          'percentage': BookingPolicy.refundPercentage(
            refund,
            current.chargeTotal,
          ),
          'method': current.paymentMethod ?? 'card',
          'cardLast4': current.cardLast4,
          'refundReference': reference,
          'reason': reason,
          'status': RefundStatus.initiated.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return CancellationResult(
        fee: fee,
        refundAmount: refund,
        refundReference: reference,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Editing details
  // ---------------------------------------------------------------------

  Future<void> updateDetails(Booking booking, BookingEdit edit) async {
    edit.validate();
    final uid = _uid;
    if (booking.customerId != uid) {
      throw StateError('You can only change your own bookings.');
    }
    final uploaded = <Reference>[];
    try {
      for (final (index, bytes) in edit.newPhotos.indexed) {
        final ref = _storage.ref(
          'bookings/${booking.id}/photos/'
          '${now().millisecondsSinceEpoch}_$index.jpg',
        );
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        uploaded.add(ref);
      }
      final photoUrls = [
        ...edit.keptPhotoUrls,
        for (final ref in uploaded) await ref.getDownloadURL(),
      ];
      await _db.runTransaction((tx) async {
        final snapshot = await tx.get(_booking(booking.id));
        final data = snapshot.data();
        if (data == null) throw StateError('This booking no longer exists.');
        final current = Booking.fromMap(snapshot.id, data);
        if (current.customerId != uid) {
          throw StateError('You can only change your own bookings.');
        }
        if (!BookingPolicy.canEdit(current)) {
          throw const BookingChangedException(
            'Your professional is already on the job, so details are locked.',
          );
        }
        tx.update(snapshot.reference, {
          'addressId': edit.addressId,
          'address': edit.address.trim(),
          'addressLabel': edit.addressLabel,
          'addressArea': edit.addressArea,
          'addressNeedsUpdate':
              edit.addressId == null && current.addressNeedsUpdate,
          'accessNotes': edit.accessNotes.trim(),
          'contactPhone': edit.contactPhone.trim(),
          'jobNotes': edit.jobNotes.trim(),
          'photoUrls': photoUrls,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {
      // Don't leave orphaned uploads behind when the save fails.
      for (final ref in uploaded) {
        try {
          await ref.delete();
        } catch (_) {}
      }
      rethrow;
    }
    // Best-effort cleanup of photos the customer removed.
    for (final url in booking.photoUrls) {
      if (edit.keptPhotoUrls.contains(url)) continue;
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------
  // Reviews and disputes
  // ---------------------------------------------------------------------

  Future<bool> hasReview(String bookingId) async =>
      (await _db.collection('reviews').doc(bookingId).get()).exists;

  Future<void> submitReview({
    required Booking booking,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) throw ArgumentError('Choose 1 to 5 stars.');
    if (comment.length > 500) throw ArgumentError('Keep reviews under 500.');
    await _db.collection('reviews').doc(booking.id).set({
      'bookingId': booking.id,
      'customerId': _uid,
      'providerId': booking.providerId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static const disputeCategories = [
    'Work quality',
    'Overcharged',
    'Damage to property',
    'Professional conduct',
    'Other',
  ];

  Future<String> reportProblem({
    required Booking booking,
    required String category,
    required String description,
  }) async {
    if (!disputeCategories.contains(category)) {
      throw ArgumentError('Choose what went wrong.');
    }
    final text = description.trim();
    if (text.length < 10 || text.length > 1000) {
      throw ArgumentError('Describe the problem in 10–1000 characters.');
    }
    final ref = _db.collection('disputes').doc();
    await ref.set({
      'bookingId': booking.id,
      'customerId': _uid,
      'providerId': booking.providerId,
      'category': category,
      'description': text,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
