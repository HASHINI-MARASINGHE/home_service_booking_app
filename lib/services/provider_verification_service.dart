import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/provider_verification.dart';
import '../models/verification_draft.dart';
import 'document_picker.dart';
import 'image_upload_service.dart';

/// A provider's own verification: watching its status and submitting the
/// details and documents an admin reviews.
class ProviderVerificationService {
  ProviderVerificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ImageUploadService? imageUploads,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _uploads = imageUploads ?? ImageUploadService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final ImageUploadService _uploads;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in again.');
    return user.uid;
  }

  /// The provider's submission (null until they submit one).
  Stream<ProviderVerification?> watch() {
    final uid = _uid;
    return _db
        .collection('providerVerifications')
        .doc(uid)
        .snapshots()
        .map((doc) => ProviderVerification.fromMap(uid, doc.data()));
  }

  /// For a signed-in provider (rejected, or an account created before
  /// verification existed).
  Future<void> submit(VerificationDraft draft) => submitFor(_uid, draft);

  /// Uploads every document, saves the provider profile and finally writes the
  /// submission as `pending`. Used with the new account's uid while
  /// registering, so nothing is half saved when it fails.
  Future<void> submitFor(String uid, VerificationDraft draft) async {
    final problem = draft.firstProblem;
    if (problem != null) throw ArgumentError(problem);
    // Each upload already times out after 30 s; this caps the whole submit.
    return _submit(uid, draft).timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw StateError(_stuckMessage),
    );
  }

  static const _stuckMessage =
      'Uploading is taking too long. Check your connection and try again.';

  Future<void> _submit(String uid, VerificationDraft draft) async {
    final years = int.tryParse(draft.experienceYears.trim()) ?? 0;
    final profession = draft.profession.trim().isEmpty
        ? 'Service provider'
        : draft.profession.trim();

    Future<VerificationFile> upload(String slot, PickedDocument doc) async {
      if (doc.size > DocumentPicker.maxBytes) {
        throw ArgumentError('${doc.name} is larger than 10 MB.');
      }
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final url = await _uploads.uploadImage(
        doc.bytes,
        folder: UploadFolders.providerDocs(uid),
        fileName: '${slot}_$stamp',
      );
      return VerificationFile(name: doc.name, url: url);
    }

    Future<VerificationFile?> maybe(String slot, PickedDocument? doc) async =>
        doc == null ? null : upload(slot, doc);
    final idFront = await maybe('id_front', draft.idFront);
    final idBack = await maybe('id_back', draft.idBack);
    final selfie = await maybe('selfie', draft.selfie);
    final cv = await maybe('cv', draft.cv);
    final certificates = <VerificationFile>[];
    for (var i = 0; i < draft.certificates.length; i++) {
      certificates.add(await upload('certificate$i', draft.certificates[i]));
    }

    await _saveProfile(uid, draft, years, profession);
    await _db.collection('providerVerifications').doc(uid).set({
      'providerId': uid,
      'fullName': draft.fullName.trim(),
      'phone': draft.phone.trim(),
      'profession': profession,
      'experienceYears': years,
      'about': draft.about.trim(),
      'idType': draft.idType,
      'idNumber': draft.idNumber.trim().toUpperCase(),
      'idFront': ?idFront?.toMap(),
      'idBack': ?idBack?.toMap(),
      'selfie': ?selfie?.toMap(),
      'cv': ?cv?.toMap(),
      'certificates': [for (final c in certificates) c.toMap()],
      'experiences': [for (final e in draft.experiences) e.toMap()],
      'status': VerificationStatus.pending.name,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates the provider profile (or refreshes its basic details when one
  /// exists) from what was entered for verification.
  Future<void> _saveProfile(
    String uid,
    VerificationDraft draft,
    int years,
    String profession,
  ) async {
    final ref = _db.collection('providerProfiles').doc(uid);
    final existing = await ref.get();
    final basics = {
      'providerId': uid,
      'phone': draft.phone.trim(),
      'profession': profession,
      'experience': years,
      'about': draft.about.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (existing.exists) {
      await ref.update(basics);
    } else {
      await ref.set({
        ...basics,
        'services': [profession],
        'pricing': null,
        'availability': false,
      });
    }
  }
}
