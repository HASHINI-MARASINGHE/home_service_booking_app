import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/provider_profile.dart';

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

  /// Saves the private profile and, in the same batch, publishes the public
  /// listing at `professionals/{uid}` that customers see on their home page.
  Future<void> save(ProviderProfile profile, {required AppUser user}) async {
    final uid = _uid;
    if (profile.providerId != uid || user.uid != uid) {
      throw StateError('You can only edit your own profile.');
    }
    profile.validate();
    final batch = _db.batch()
      ..set(_db.collection('providerProfiles').doc(uid), {
        ...profile.editableFields(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
      ..set(_db.collection('professionals').doc(uid), {
        'name': user.name,
        // Omitted when unset so a backend-provided photo is kept.
        if (user.photoUrl != null) 'photoUrl': user.photoUrl,
        'specialty': profile.profession.trim(),
        'phone': profile.phone,
        'about': profile.about,
        'experience': profile.experience,
        'services': profile.services,
        'pricing': profile.pricing,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    await batch.commit();
  }
}
