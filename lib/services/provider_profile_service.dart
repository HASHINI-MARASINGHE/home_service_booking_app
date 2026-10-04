import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> save(ProviderProfile profile) async {
    final uid = _uid;
    if (profile.providerId != uid) {
      throw StateError('You can only edit your own profile.');
    }
    profile.validate();
    await _db.collection('providerProfiles').doc(uid).set({
      ...profile.editableFields(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
