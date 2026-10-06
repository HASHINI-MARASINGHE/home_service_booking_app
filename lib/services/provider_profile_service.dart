import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/provider_profile.dart';
import '../models/rating_stats.dart';

class ProviderProfileService {
  ProviderProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  Stream<ProviderProfile> watchProfile() {
    final uid = _uid;
    return _db.collection('providerProfiles').doc(uid).snapshots().map((doc) {
      if (_auth.currentUser?.uid != uid) {
        throw StateError('Please log in again.');
      }
      return ProviderProfile.fromMap(uid, doc.data() ?? {});
    });
  }

  /// The provider's overall rating: the live average of all customer
  /// reviews (null until the first review).
  Stream<RatingStats?> watchRatingStats() => _db
      .collection('ratingStats')
      .doc(_uid)
      .snapshots()
      .map((doc) => RatingStats.fromMap(doc.data()));

  Future<void> save(ProviderProfile profile, {AppUser? user}) async {
    final uid = _uid;
    if (profile.providerId != uid || (user != null && user.uid != uid)) {
      throw StateError('You can only edit your own profile.');
    }
    profile.validate();
    final batch = _db.batch()
      ..set(_db.collection('providerProfiles').doc(uid), {
        ...profile.editableFields(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    // Also publish the public listing customers see (name, trade, about,
    // experience, services, starting price). Verification, Provider ID and
    // rating stay with the admin; the rules forbid a provider setting them.
    if (user != null) {
      batch.set(_db.collection('professionals').doc(uid), {
        'name': user.name,
        // Omitted when unset so an existing photo is kept.
        if (user.photoUrl != null) 'photoUrl': user.photoUrl,
        'specialty': profile.profession.trim(),
        'phone': profile.phone,
        'about': profile.about,
        'experience': profile.experience,
        'services': profile.services,
        'pricing': profile.pricing,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
