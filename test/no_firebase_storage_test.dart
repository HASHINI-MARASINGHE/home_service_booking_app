// This test ensures nobody brings Firebase Storage back into the project.
// All image uploads go through ImageUploadService → Cloudinary.
// See lib/services/image_upload_service.dart for the shared upload service.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('No file in lib/ imports firebase_storage', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ must exist');

    final violations = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (content.contains('package:firebase_storage')) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Firebase Storage has been removed from this project.\n'
          'Use ImageUploadService (lib/services/image_upload_service.dart) '
          'with a folder from UploadFolders instead.\n'
          'Violations found in:\n${violations.join('\n')}',
    );
  });

  test('No file in lib/ calls Firebase Storage APIs', () {
    final libDir = Directory('lib');
    final storageApis = RegExp(
      r'\b(FirebaseStorage|putData|putFile|getDownloadURL|refFromURL|useStorageEmulator|SettableMetadata)\b',
    );

    final violations = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Skip the one file that legitimately mentions Storage in a doc comment.
      if (entity.path.contains('image_upload_service.dart')) continue;
      final content = entity.readAsStringSync();
      if (storageApis.hasMatch(content)) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Firebase Storage APIs must not appear in lib/.\n'
          'Use ImageUploadService instead.\n'
          'Violations found in:\n${violations.join('\n')}',
    );
  });
}
