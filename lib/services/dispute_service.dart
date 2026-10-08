import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking.dart';
import '../models/dispute.dart';

/// Thrown for problems the customer can understand and fix. The message is
/// safe to show on screen.
class DisputeException implements Exception {
  const DisputeException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Everything about disputes (CRUD):
/// * Create  - [submit]
/// * Read    - [watchDispute], [watchPhotos]
/// * Update  - [update] (pending disputes only)
/// * Delete  - [withdraw] (pending disputes only)
///
/// A dispute is a warranty claim, not a payment hold: the customer already
/// paid, and any refund is decided later by the safety desk and written into
/// `decision` / `refundAmount`. So a dispute never changes the booking.
class DisputeService {
  DisputeService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) : _authOverride = auth,
       _dbOverride = firestore,
       _clock = clock ?? DateTime.now;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _dbOverride;
  final DateTime Function() _clock;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  DateTime now() => _clock();

  static const maxPhotos = 5;
  static const minDescription = 10;
  static const maxDescription = 1000;
  static const minResponse = 10;

  /// A photo is stored as Base64 text inside one Firestore document, which
  /// can hold at most 1 MB. Base64 adds a third, so keep the picture under
  /// 700 KB (the pickers already shrink it to ~800 px wide).
  static const maxPhotoBytes = 700 * 1024;

  /// The safety desk replies within this time.
  static const respondWindow = Duration(hours: 24);

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw const DisputeException('Please log in again.');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _dispute(String bookingId) =>
      _db.collection('disputes').doc(bookingId);

  CollectionReference<Map<String, dynamic>> _photos(String bookingId) =>
      _dispute(bookingId).collection('photos');

  /// Photo documents use fixed slot names (p0..p4), which also caps the
  /// number of photos at [maxPhotos] in the security rules.
  static String _slot(int index) => 'p$index';

  // ------------------------------------------------------------------ read
  /// The booking's dispute, live (null when there is none).
  Stream<Dispute?> watchDispute(String bookingId) =>
      _dispute(bookingId)
          .snapshots()
          .map((doc) => Dispute.fromMap(doc.id, doc.data()));

  /// The dispute's photos, in the order they were added.
  Stream<List<DisputePhoto>> watchPhotos(String bookingId) =>
      _photos(bookingId).snapshots().map((snapshot) {
        final photos = [
          for (final doc in snapshot.docs)
            ?DisputePhoto.fromMap(doc.id, doc.data()),
        ]..sort((a, b) => a.id.compareTo(b.id));
        return photos;
      });

  // ---------------------------------------------------------------- checks
  /// Throws a [DisputeException] with a plain message when the form is not
  /// valid yet. Used by the screen and again before saving.
  // Input validation - enforces allowed reasons, 10-1000 character description,
  // max 5 photos, and 700 KB size limit per photo (Base64 Firestore document limit).
  static void validate({
    required String reason,
    required String description,
    required List<DisputePhoto> photos,
  }) {
    if (!DisputeReasons.all.contains(reason)) {
      throw const DisputeException('Choose a reason for the dispute.');
    }
    final text = description.trim();
    if (text.length < minDescription) {
      throw const DisputeException(
        'Describe the issue in at least $minDescription characters.',
      );
    }
    if (text.length > maxDescription) {
      throw const DisputeException(
        'The description can be at most $maxDescription characters.',
      );
    }
    if (photos.length > maxPhotos) {
      throw const DisputeException('You can attach up to $maxPhotos photos.');
    }
    for (final photo in photos) {
      if (photo.sizeBytes > maxPhotoBytes) {
        throw const DisputeException(
          'One of the photos is too large. Pick a smaller picture.',
        );
      }
    }
  }

  // ---------------------------------------------------------------- create
  /// Files a new dispute (with its photos) and tells the provider, in one
  /// transaction. Allowed only for the customer's own completed booking,
  /// inside the 3-day warranty, and only once per booking.
  // Dispute creation - checks 3-day warranty period and customer authorization.
  // Executes transaction to create dispute, save photo docs, and set a 24-hour provider response deadline.
  Future<void> submit({
    required Booking booking,
    required String reason,
    String? tag,
    required String description,
    required List<DisputePhoto> photos,
  }) async {
    final uid = _uid;
    validate(reason: reason, description: description, photos: photos);
    if (booking.customerId != uid) {
      throw const DisputeException('You can only report your own bookings.');
    }
    if (!DisputeWarranty.isOpen(booking, now())) {
      throw const DisputeException(
        'The 3-day warranty period for this job has ended.',
      );
    }
    final ref = _dispute(booking.id);
    final deadline = now().add(respondWindow);
    try {
      await _db.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) {
          throw const DisputeException(
            'You have already reported a problem for this booking.',
          );
        }
        tx.set(ref, {
          'bookingId': booking.id,
          'customerId': uid,
          'providerId': booking.providerId,
          'reason': reason,
          'tag': ?tag,
          'description': description.trim(),
          'status': DisputeStatus.pending.value,
          'photoCount': photos.length,
          'serviceName': booking.serviceName,
          'customerName': booking.customerName,
          'providerName': booking.providerName ?? '',
          'bookingRef': booking.displayReference,
          'amount': booking.chargeTotal,
          'createdAt': FieldValue.serverTimestamp(),
          'respondDeadline': Timestamp.fromDate(deadline),
          'adminNote': null,
          'decision': null,
          'refundAmount': null,
          'providerResponse': null,
        });
        for (var i = 0; i < photos.length; i++) {
          tx.set(_photos(booking.id).doc(_slot(i)), _photoData(photos[i]));
        }
        tx.set(_db.collection('notifications').doc('dispute_${booking.id}'), {
          'recipientId': booking.providerId,
          'senderId': uid,
          'type': 'dispute',
          'bookingId': booking.id,
          'title': 'Problem reported on ${booking.serviceName}',
          'body':
              '${booking.customerName} reported a problem with booking '
              '#${booking.displayReference}. Please respond within 24 hours.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _friendly(error);
    }
  }

  // ---------------------------------------------------------------- update
  /// Changes a pending dispute. [photos] is the complete list that should be
  /// kept afterwards (old and new ones); removed photos are deleted.
  // Dispute update - only allowed while status is 'pending' (before review starts).
  // Uses Firestore WriteBatch to atomically update dispute info and replace photo slots.
  Future<void> update({
    required Dispute dispute,
    required String reason,
    String? tag,
    required String description,
    required List<DisputePhoto> photos,
  }) async {
    validate(reason: reason, description: description, photos: photos);
    if (dispute.customerId != _uid) {
      throw const DisputeException('You can only change your own dispute.');
    }
    try {
      final current = await _dispute(dispute.id).get();
      final status = DisputeStatus.parse(current.data()?['status']);
      if (!current.exists || status != DisputeStatus.pending) {
        throw const DisputeException(
          'This dispute is already being reviewed, so it can no longer be '
          'changed.',
        );
      }
      final batch = _db.batch();
      batch.update(_dispute(dispute.id), {
        'reason': reason,
        'tag': tag,
        'description': description.trim(),
        'photoCount': photos.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (var i = 0; i < photos.length; i++) {
        batch.set(_photos(dispute.id).doc(_slot(i)), _photoData(photos[i]));
      }
      for (var i = photos.length; i < maxPhotos; i++) {
        batch.delete(_photos(dispute.id).doc(_slot(i)));
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      throw _friendly(error);
    }
  }

  // ---------------------------------------------------------------- delete
  /// Withdraws a pending dispute: removes it, its photos and the notice the
  /// provider received. The booking itself was never touched.
  // Customer withdrawal - allows customer to cancel dispute only while 'pending'.
  // Atomically deletes photos, provider notification, and dispute record via WriteBatch.
  Future<void> withdraw(Dispute dispute) async {
    if (dispute.customerId != _uid) {
      throw const DisputeException('You can only withdraw your own dispute.');
    }
    try {
      final current = await _dispute(dispute.id).get();
      if (!current.exists) return;
      if (DisputeStatus.parse(current.data()?['status']) !=
          DisputeStatus.pending) {
        throw const DisputeException(
          'This dispute is already being reviewed, so it cannot be '
          'withdrawn.',
        );
      }
      final batch = _db.batch();
      for (var i = 0; i < maxPhotos; i++) {
        batch.delete(_photos(dispute.id).doc(_slot(i)));
      }
      batch.delete(
        _db.collection('notifications').doc('dispute_${dispute.id}'),
      );
      batch.delete(_dispute(dispute.id));
      await batch.commit();
    } on FirebaseException catch (error) {
      throw _friendly(error);
    }
  }

  // --------------------------------------------------------------- respond
  /// The provider's answer to a dispute, allowed until the 24-hour deadline
  /// and while the dispute is not yet decided. It can be edited until then.
  // Provider response - saves provider's side of the story within the 24h window.
  Future<void> respond({
    required Dispute dispute,
    required String response,
  }) async {
    final text = response.trim();
    if (text.length < minResponse || text.length > maxDescription) {
      throw const DisputeException(
        'Write your response in $minResponse to $maxDescription characters.',
      );
    }
    if (dispute.providerId != _uid) {
      throw const DisputeException('This dispute is not about your job.');
    }
    if (!dispute.canProviderRespond(now())) {
      throw const DisputeException(
        'The response window for this dispute has closed.',
      );
    }
    try {
      await _dispute(dispute.id).update({
        'providerResponse': text,
        'providerRespondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw _friendly(error);
    }
  }

  // --------------------------------------------------------------- helpers
  Map<String, dynamic> _photoData(DisputePhoto photo) => {
    'base64': photo.base64,
    'mimeType': photo.mimeType,
    'sizeBytes': photo.sizeBytes,
    'createdAt': FieldValue.serverTimestamp(),
  };

  DisputeException _friendly(FirebaseException error) =>
      DisputeException(switch (error.code) {
        'permission-denied' =>
          'This dispute could not be saved. The warranty may have ended or the '
              'dispute may already be under review.',
        'unavailable' ||
        'network-request-failed' => 'Check your connection and try again.',
        _ => 'Something went wrong. Please try again.',
      });
}
