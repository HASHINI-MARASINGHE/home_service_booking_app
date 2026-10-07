import 'package:image_picker/image_picker.dart';

import '../models/dispute.dart';
import 'dispute_service.dart';

/// How the dispute form gets a photo. Swappable so tests (which cannot open a
/// gallery) can supply their own pictures.
abstract class DisputePhotoPicker {
  static DisputePhotoPicker instance = SystemDisputePhotoPicker();

  /// Lets the customer pick one picture (null when they cancel).
  Future<DisputePhoto?> pick();
}

class SystemDisputePhotoPicker implements DisputePhotoPicker {
  @override
  Future<DisputePhoto?> pick() async {
    // Shrink the picture first: it is saved as text inside a Firestore
    // document, which can hold at most 1 MB.
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 60,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > DisputeService.maxPhotoBytes) {
      throw const DisputeException(
        'That photo is too large. Pick a smaller picture.',
      );
    }
    final name = file.name.toLowerCase();
    return DisputePhoto.fromBytes(
      bytes,
      mimeType: name.endsWith('.png') ? 'image/png' : 'image/jpeg',
    );
  }
}
