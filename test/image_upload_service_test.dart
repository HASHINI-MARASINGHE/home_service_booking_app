import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/config/cloudinary_config.dart';
import 'package:home_service_bookin_app/services/image_upload_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final sampleJpeg = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  ]);

  group('ImageUploadService', () {
    test('success: uploads bytes with unsigned preset and folder, returns secure_url', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'secure_url': 'https://res.cloudinary.com/dclo5pyll/image/upload/v123/test.jpg',
            'public_id': 'test_id',
          }),
          200,
        );
      });

      final service = ImageUploadService(client: client);
      final url = await service.uploadImage(
        sampleJpeg,
        folder: UploadFolders.booking('b_123'),
        fileName: 'issue_1.jpg',
      );

      expect(url, 'https://res.cloudinary.com/dclo5pyll/image/upload/v123/test.jpg');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url, CloudinaryConfig.uploadUrl);
      final body = latin1.decode(capturedRequest!.bodyBytes);
      expect(body, contains('name="upload_preset"\r\n\r\nhomecare_unsigned'));
      expect(body, contains('name="folder"\r\n\r\nbookings/b_123'));
      expect(body, contains('name="public_id"\r\n\r\nissue_1'));
      expect(body.toLowerCase(), isNot(contains('api_key')));
      expect(body.toLowerCase(), isNot(contains('api_secret')));
    });

    test('HTTP error: non-200 throws ImageUploadException with failedMessage', () async {
      final client = MockClient((_) async {
        return http.Response('{"error":{"message":"Invalid preset"}}', 400);
      });

      final service = ImageUploadService(client: client);
      expect(
        () => service.uploadImage(sampleJpeg, folder: UploadFolders.misc),
        throwsA(
          isA<ImageUploadException>().having(
            (e) => e.message,
            'message',
            ImageUploadService.failedMessage,
          ),
        ),
      );
    });

    test('timeout: request taking longer than duration throws timeoutMessage', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{"secure_url":"https://res.cloudinary.com/x.jpg"}', 200);
      });

      final service = ImageUploadService(
        client: client,
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        () => service.uploadImage(sampleJpeg, folder: UploadFolders.misc),
        throwsA(
          isA<ImageUploadException>().having(
            (e) => e.message,
            'message',
            ImageUploadService.timeoutMessage,
          ),
        ),
      );
    });

    test('missing secure_url: 200 response missing secure_url throws failedMessage', () async {
      final client = MockClient((_) async {
        return http.Response('{"status":"ok"}', 200);
      });

      final service = ImageUploadService(client: client);
      expect(
        () => service.uploadImage(sampleJpeg, folder: UploadFolders.misc),
        throwsA(
          isA<ImageUploadException>().having(
            (e) => e.message,
            'message',
            ImageUploadService.failedMessage,
          ),
        ),
      );
    });

    test('file validation: files larger than 10 MB are rejected before upload', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      final service = ImageUploadService(client: client);
      // Construct > 10MB buffer starting with JPEG header
      final hugeBytes = Uint8List(10 * 1024 * 1024 + 1);
      hugeBytes[0] = 0xFF;
      hugeBytes[1] = 0xD8;
      hugeBytes[2] = 0xFF;

      expect(
        () => service.uploadImage(hugeBytes, folder: UploadFolders.misc),
        throwsA(
          isA<ImageUploadException>().having(
            (e) => e.message,
            'message',
            ImageUploadService.tooLargeMessage,
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('file validation: non-image bytes are rejected before upload', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      final service = ImageUploadService(client: client);
      final notAnImage = Uint8List.fromList([1, 2, 3, 4, 5]);

      expect(
        () => service.uploadImage(notAnImage, folder: UploadFolders.misc),
        throwsA(
          isA<ImageUploadException>().having(
            (e) => e.message,
            'message',
            ImageUploadService.notImageMessage,
          ),
        ),
      );
      expect(called, isFalse);
    });
  });
}
