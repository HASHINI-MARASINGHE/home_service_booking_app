import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/professional.dart';
import '../models/provider_verification.dart';
import '../models/rating_stats.dart';
import '../models/review.dart';

/// Admin-only actions: reviewing provider verification submissions.
/// Security rules only allow accounts with the `admin` role to do any of it.
class AdminService {
  AdminService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// First number of the public Provider ID range: HCP-1001, HCP-1002, ...
  static const providerCodeBase = 1000;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  /// Submissions with [status], newest first.
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
        (snap) => [
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
          for (final doc in snap.docs)
            ?Review.fromMap(doc.id, doc.data()),
        ];
        reviews.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return reviews;
      });
}
