/// THE way to upload images in this app.
///
/// * Always call [ImageUploadService.uploadImage] with a folder from
///   [UploadFolders] and store the returned `https://res.cloudinary.com/...`
///   URL in Firestore.
/// * Never use Firebase Storage: it has been removed from the project and
///   `test/no_firebase_storage_test.dart` fails if it comes back.
/// * Never add a Cloudinary API key or API secret. Uploads use the unsigned
///   preset in [CloudinaryConfig], so every uploaded image is a public URL;
///   only upload test data or images that are fine to be public.
/// * Unsigned uploads can't be deleted from the app. To "remove" an image,
///   stop referencing its URL.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

export '../config/cloudinary_config.dart' show UploadFolders;

/// A user-friendly upload failure. [message] is safe to show on screen.
class ImageUploadException implements Exception {
  const ImageUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ImageUploadService {
  ImageUploadService({this._client, Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 30);

  final http.Client? _client;
  final Duration _timeout;

  static const maxBytes = 10 * 1024 * 1024;

  static const failedMessage =
      'Photo upload failed. Check your connection and try again.';
  static const timeoutMessage =
      'Photo upload is taking too long. Check your connection and try again.';
  static const tooLargeMessage = 'This image is larger than 10 MB.';
  static const notImageMessage =
      'Only image files (JPG, PNG, WEBP, GIF or HEIC) can be uploaded.';

  /// Uploads [bytes] into [folder] (use [UploadFolders]) and returns the
  /// image's `secure_url`. [fileName] becomes the Cloudinary public ID
  /// (without extension); Cloudinary picks a random one when it is omitted.
  Future<String> uploadImage(
    Uint8List bytes, {
    required String folder,
    String? fileName,
  }) async {
    if (bytes.isEmpty || !isImage(bytes)) {
      throw const ImageUploadException(notImageMessage);
    }
    if (bytes.length > maxBytes) {
      throw const ImageUploadException(tooLargeMessage);
    }
    final name = fileName == null ? null : _safeName(fileName);
    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUrl)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder;
    if (name != null) request.fields['public_id'] = name;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: '${name ?? 'image'}.jpg'),
    );

    final client = _client ?? http.Client();
    final http.Response response;
    try {
      final streamed = await client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ImageUploadException(timeoutMessage);
    } catch (_) {
      throw const ImageUploadException(failedMessage);
    } finally {
      if (_client == null) client.close();
    }
    if (response.statusCode != 200) {
      throw const ImageUploadException(failedMessage);
    }
    Object? url;
    try {
      url = (jsonDecode(response.body) as Map<String, dynamic>)['secure_url'];
    } catch (_) {
      url = null;
    }
    if (url is! String || !url.startsWith('https://')) {
      throw const ImageUploadException(failedMessage);
    }
    return url;
  }

  /// Recognises common image formats from their first bytes, so a renamed
  /// PDF or document is rejected even if its name ends in `.jpg`.
  static bool isImage(Uint8List b) {
    bool starts(List<int> sig, [int offset = 0]) {
      if (b.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    return starts([0xFF, 0xD8, 0xFF]) || // JPEG
        starts([0x89, 0x50, 0x4E, 0x47]) || // PNG
        starts([0x47, 0x49, 0x46, 0x38]) || // GIF
        (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) || // WEBP
        starts([0x42, 0x4D]) || // BMP
        (starts([0x66, 0x74, 0x79, 0x70], 4) && // ftyp: HEIC/HEIF/AVIF
            ['heic', 'heix', 'hevc', 'mif1', 'msf1', 'avif'].any(
              (brand) => starts(ascii.encode(brand), 8),
            ));
  }

  static String _safeName(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return safe.isEmpty ? 'image' : safe;
  }
}
