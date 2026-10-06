import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// A file the provider chose, held in memory until it is uploaded.
class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;

  int get size => bytes.length;
  bool get isImage => contentType.startsWith('image/');

  /// "2.4 MB" / "310 KB".
  String get sizeLabel => size >= 1024 * 1024
      ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(size / 1024).ceil()} KB';

  static String contentTypeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}

/// How the verification screens get files. Swappable so tests (which cannot
/// drive native file dialogs or a camera) can supply their own files.
abstract class DocumentPicker {
  static DocumentPicker instance = SystemDocumentPicker();

  /// Largest file accepted (also enforced by Storage security rules).
  static const maxBytes = 10 * 1024 * 1024;

  /// A photo of an ID document (image files only).
  Future<PickedDocument?> pickImage();

  /// A live selfie from the front camera (a photo picker where there is none).
  Future<PickedDocument?> takeSelfie();

  /// A photo of a CV or certificate (photos only, no PDF or Word files).
  Future<PickedDocument?> pickDocument();
}

class SystemDocumentPicker implements DocumentPicker {
  Future<PickedDocument?> _pick(List<String> extensions) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    return PickedDocument(
      name: file.name,
      bytes: await file.readAsBytes(),
      contentType: PickedDocument.contentTypeFor(file.name),
    );
  }

  @override
  Future<PickedDocument?> pickImage() => _pick(['jpg', 'jpeg', 'png', 'webp']);

  @override
  Future<PickedDocument?> pickDocument() => pickImage();

  @override
  Future<PickedDocument?> takeSelfie() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (photo == null) return null;
    final name = photo.name.isEmpty ? 'selfie.jpg' : photo.name;
    return PickedDocument(
      name: name,
      bytes: await photo.readAsBytes(),
      contentType: PickedDocument.contentTypeFor(name),
    );
  }
}
