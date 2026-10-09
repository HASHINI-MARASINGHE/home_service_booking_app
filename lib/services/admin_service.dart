import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/dispute.dart';
import '../models/professional.dart';
import '../models/provider_verification.dart';
import '../models/rating_stats.dart';
import '../models/review.dart';
import 'dispute_service.dart';

/// Admin-only actions: reviewing provider verification submissions.
/// Security rules only allow accounts with the `admin` role to do any of it.
class AdminService {
  AdminService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  // -------------------------------------------------------------- monitoring
  /// Every customer account, live, A to Z.
  Stream<List<AppUser>> watchCustomers() => _db
      .collection('users')
      .where('role', isEqualTo: AppUser.customerRole)
      .snapshots()
      .map((snapshot) {
        final users = <AppUser>[];
        for (final doc in snapshot.docs) {
          try {
            users.add(AppUser.fromMap(doc.id, doc.data()));
          } on FormatException {
            // Skip malformed profiles.
          }
        }
        return users..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });

  /// The most recent bookings on the platform, live, newest first.
  Stream<List<Booking>> watchAllBookings({int limit = 500}) => _db
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => [
        for (final doc in snapshot.docs) Booking.fromMap(doc.id, doc.data()),
      ]);

  /// First number of the public Provider ID range: HCP-1001, HCP-1002, ...
  static const providerCodeBase = 1000;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  /// Submissions with [status], newest first.
  // Real-time stream of provider submissions filtered by verification status (pending, verified, rejected).
  Stream<List<ProviderVerification>> watchByStatus(VerificationStatus status) =>
      _db
          .collection('providerVerifications')
          .where('status', isEqualTo: status.name)
          .snapshots()
          .map((snapshot) {
            final items = [
              for (final doc in snapshot.docs)
                ?ProviderVerification.fromMap(doc.id, doc.data()),
            ];
            items.sort(
              (a, b) => (b.submittedAt ?? DateTime.now()).compareTo(
                a.submittedAt ?? DateTime.now(),
              ),
            );
            return items;
          });

  Stream<int> watchPendingCount() =>
      watchByStatus(VerificationStatus.pending).map((items) => items.length);

  /// Verifies a provider: generates their Provider ID, publishes the public
  /// profile customers see and notifies them, all in one transaction.
  /// Returns the new Provider ID.
  // Atomic Firestore Transaction - guarantees all 4 steps succeed or fail together:
  // 1. Validates status is still 'pending' (avoids double review)
  // 2. Increments atomic counter to assign sequential ID (e.g. HCP-1001)
  // 3. Publishes provider to public 'professionals' collection
  // 4. Sends in-app push notification to the provider
  Future<String> verify(ProviderVerification submission) async {
    final adminId = _uid;
    final verificationRef = _db
        .collection('providerVerifications')
        .doc(submission.uid);
    final counterRef = _db.collection('counters').doc('providerIds');
    final publicRef = _db.collection('professionals').doc(submission.uid);
    final noteRef = _db.collection('notifications').doc();
    return _db.runTransaction((tx) async {
      final current = await tx.get(verificationRef);
      if (current.data()?['status'] != VerificationStatus.pending.name) {
        throw StateError('This provider has already been reviewed.');
      }
      final last =
          ((await tx.get(counterRef)).data()?['last'] as num?)?.toInt() ?? 0;
      final next = last + 1;
      final code = 'HCP-${providerCodeBase + next}';
      tx.set(counterRef, {'last': next});
      tx.update(verificationRef, {
        'status': VerificationStatus.verified.name,
        'providerCode': code,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'rejectionReason': FieldValue.delete(),
      });
      tx.set(publicRef, {
        'name': submission.fullName,
        'specialty': submission.profession.isEmpty
            ? 'Service provider'
            : submission.profession,
        'phone': submission.phone,
        'about': submission.about,
        'experience': submission.experienceYears,
        'services': [
          submission.profession.isEmpty
              ? 'Service provider'
              : submission.profession,
        ],
        'verified': true,
        'providerCode': code,
        'completedJobs': 0,
        'area': '',
      }, SetOptions(merge: true));
      tx.set(
        noteRef,
        _note(
          adminId: adminId,
          recipientId: submission.uid,
          title: 'You are verified!',
          body: 'Your Provider ID is $code. You can now accept jobs.',
        ),
      );
      return code;
    });
  }

  /// Sends the submission back with a reason; the provider can fix and resubmit.
  // Admin rejection flow - validates reason length, marks status as 'rejected',
  // saves the feedback message, and notifies the provider so they can re-upload corrections.
  Future<void> reject(ProviderVerification submission, String reason) async {
    final adminId = _uid;
    final text = reason.trim();
    if (text.length < 5 || text.length > 300) {
      throw ArgumentError('Give a reason of 5 to 300 characters.');
    }
    final verificationRef = _db
        .collection('providerVerifications')
        .doc(submission.uid);
    final noteRef = _db.collection('notifications').doc();
    await _db.runTransaction((tx) async {
      final current = await tx.get(verificationRef);
      if (current.data()?['status'] != VerificationStatus.pending.name) {
        throw StateError('This provider has already been reviewed.');
      }
      tx.update(verificationRef, {
        'status': VerificationStatus.rejected.name,
        'rejectionReason': text,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });
      tx.set(
        noteRef,
        _note(
          adminId: adminId,
          recipientId: submission.uid,
          title: 'Verification needs changes',
          body: text,
        ),
      );
    });
  }

  Map<String, dynamic> _note({
    required String adminId,
    required String recipientId,
    required String title,
    required String body,
  }) => {
    'recipientId': recipientId,
    'senderId': adminId,
    'type': 'verification',
    'bookingId': '',
    'title': title,
    'body': body,
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  };

  // ─────────────────────────── Ratings monitoring ──────────────────────────

  /// All verified professionals from the public `professionals` collection.
  Stream<List<Professional>> watchAllProfessionals() => _db
      .collection('professionals')
      .where('verified', isEqualTo: true)
      .snapshots()
      .map(
        (snap) =>
            [
              for (final doc in snap.docs)
                Professional.fromMap(doc.id, doc.data()),
            ]..sort((a, b) {
              // Sort: highest rating first, unrated at the end.
              final ra = a.rating ?? -1;
              final rb = b.rating ?? -1;
              return rb.compareTo(ra);
            }),
      );

  /// Live rating stats for one provider.
  Stream<RatingStats?> watchRatingStats(String providerId) => _db
      .collection('ratingStats')
      .doc(providerId)
      .snapshots()
      .map((doc) => RatingStats.fromMap(doc.data()));

  /// All reviews written for one provider, newest first.
  Stream<List<Review>> watchProviderReviews(String providerId) => _db
      .collection('reviews')
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .map((snap) {
        final reviews = [
          for (final doc in snap.docs) ?Review.fromMap(doc.id, doc.data()),
        ];
        reviews.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return reviews;
      });

  // ───────────────────────────── Disputes (safety desk) ─────────────────────

  /// Disputes in [status], newest first.
  Stream<List<Dispute>> watchDisputes(DisputeStatus status) => _db
      .collection('disputes')
      .where('status', isEqualTo: status.value)
      .snapshots()
      .map((snapshot) {
        final items = [
          for (final doc in snapshot.docs) ?Dispute.fromMap(doc.id, doc.data()),
        ];
        items.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return items;
      });

  /// How many disputes are waiting for the safety desk to pick them up.
  Stream<int> watchPendingDisputeCount() =>
      watchDisputes(DisputeStatus.pending).map((items) => items.length);

  /// One dispute, live, so the detail screen follows the admin's own actions.
  Stream<Dispute?> watchDispute(String id) => _db
      .collection('disputes')
      .doc(id)
      .snapshots()
      .map((doc) => Dispute.fromMap(doc.id, doc.data()));

  /// The photos the customer attached (Base64, one document each).
  Stream<List<DisputePhoto>> watchDisputePhotos(String id) => _db
      .collection('disputes')
      .doc(id)
      .collection('photos')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            ?DisputePhoto.fromMap(doc.id, doc.data()),
        ]..sort((a, b) => a.id.compareTo(b.id)),
      );

  /// Pending -> Under Review, and tells the provider and customer.
  // Dispute state transition - changes status from 'pending' to 'underReview'.
  // Notifies the provider and customer that safety desk has initiated an official investigation.
  Future<void> startDisputeReview(Dispute dispute) async {
    final adminId = _uid;
    final ref = _db.collection('disputes').doc(dispute.id);
    Dispute? currentDispute;
    await _db.runTransaction((tx) async {
      final current = Dispute.fromMap(dispute.id, (await tx.get(ref)).data());
      if (current == null) {
        throw const DisputeException('This dispute no longer exists.');
      }
      if (current.status != DisputeStatus.pending) {
        throw const DisputeException('This dispute is already being reviewed.');
      }
      tx.update(ref, {
        'status': DisputeStatus.underReview.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        _db.collection('notifications').doc('dispute_${dispute.id}_review'),
        _disputeNote(
          adminId: adminId,
          recipientId: current.providerId,
          dispute: current,
          title: 'Dispute under review',
          body:
              'The safety desk is reviewing the problem reported on '
              '${current.serviceName.isEmpty ? 'a job' : current.serviceName} '
              '(#${current.bookingRef}).',
        ),
      );
      currentDispute = current;
    });

    // Notify customer separately so undeployed remote rules never block review.
    if (currentDispute != null) {
      try {
        await _db
            .collection('notifications')
            .doc('dispute_${dispute.id}_customer_review')
            .set(
              _disputeNote(
                adminId: adminId,
                recipientId: currentDispute!.customerId,
                dispute: currentDispute!,
                title: 'Dispute under review',
                body:
                    'The safety desk is reviewing your dispute for '
                    '${currentDispute!.serviceName.isEmpty ? 'your job' : currentDispute!.serviceName} '
                    '(#${currentDispute!.bookingRef}).',
              ),
            );
      } catch (_) {
        // Ignored if remote Firestore rules have not yet been deployed.
      }
    }
  }

  /// Under Review -> Resolved with the decision (and refund), and tells the
  /// provider and customer. The refund itself is paid outside the app for now;
  /// the amount is recorded here and shown to the customer.
  // Dispute resolution - validates refund bounds against job total,
  // updates status to 'resolved', attaches admin verdict/notes, and notifies provider and customer.
  Future<void> resolveDispute({
    required Dispute dispute,
    required String decision,
    double? refundAmount,
    required String note,
  }) async {
    final adminId = _uid;
    final text = note.trim();
    if (!DisputeDecisions.all.contains(decision)) {
      throw const DisputeException('Choose a decision.');
    }
    if (text.length < 5 || text.length > 500) {
      throw const DisputeException(
        'Write a note for the customer (5 to 500 characters).',
      );
    }
    final rejected = decision == DisputeDecisions.rejected;
    final total = dispute.amount;
    if (!rejected) {
      if (refundAmount == null || refundAmount <= 0) {
        throw const DisputeException('Enter the refund amount.');
      }
      if (total != null && refundAmount > total) {
        throw const DisputeException(
          'The refund cannot be more than the job total.',
        );
      }
      if (decision == DisputeDecisions.fullRefund &&
          total != null &&
          refundAmount != total) {
        throw const DisputeException('A full refund must equal the job total.');
      }
    }
    final ref = _db.collection('disputes').doc(dispute.id);
    Dispute? currentDispute;
    await _db.runTransaction((tx) async {
      final current = Dispute.fromMap(dispute.id, (await tx.get(ref)).data());
      if (current == null) {
        throw const DisputeException('This dispute no longer exists.');
      }
      if (current.status != DisputeStatus.underReview) {
        throw const DisputeException(
          'Start the review before resolving this dispute.',
        );
      }
      tx.update(ref, {
        'status': DisputeStatus.resolved.value,
        'decision': decision,
        'refundAmount': rejected ? null : refundAmount,
        'adminNote': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        _db.collection('notifications').doc('dispute_${dispute.id}_resolved'),
        _disputeNote(
          adminId: adminId,
          recipientId: current.providerId,
          dispute: current,
          title: 'Dispute resolved: $decision',
          body:
              'The safety desk decided the problem reported on '
              '${current.serviceName.isEmpty ? 'a job' : current.serviceName} '
              '(#${current.bookingRef}).',
        ),
      );
      currentDispute = current;
    });

    // Notify customer separately so undeployed remote rules never block resolution.
    if (currentDispute != null) {
      try {
        await _db
            .collection('notifications')
            .doc('dispute_${dispute.id}_customer_resolved')
            .set(
              _disputeNote(
                adminId: adminId,
                recipientId: currentDispute!.customerId,
                dispute: currentDispute!,
                title: 'Dispute resolved: $decision',
                body:
                    'The safety desk decided your dispute for '
                    '${currentDispute!.serviceName.isEmpty ? 'your job' : currentDispute!.serviceName} '
                    '(#${currentDispute!.bookingRef}): $decision.',
              ),
            );
      } catch (_) {
        // Ignored if remote Firestore rules have not yet been deployed.
      }
    }
  }

  Map<String, dynamic> _disputeNote({
    required String adminId,
    required String recipientId,
    required Dispute dispute,
    required String title,
    required String body,
  }) => {
    'recipientId': recipientId,
    'senderId': adminId,
    'type': 'dispute',
    'bookingId': dispute.bookingId,
    'title': title,
    'body': body,
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
