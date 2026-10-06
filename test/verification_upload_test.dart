import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/services/document_picker.dart';
import 'package:home_service_bookin_app/services/provider_verification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

void main() {
  final photo = PickedDocument(
    name: 'nic front.jpg',
    bytes: Uint8List.fromList(List.filled(64, 1)),
    contentType: 'image/jpeg',
  );

  ProviderVerificationService service(http.Client client) =>
      ProviderVerificationService(
        auth: _Auth(),
        firestore: _Db(),
        httpClient: client,
      );

  test('uploads a verification photo to the providerDocs folder', () async {
    late http.BaseRequest sent;
    final client = MockClient.streaming((request, body) async {
      sent = request;
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(jsonEncode({'secure_url': 'https://res.x/a.jpg'})),
        ),
        200,
      );
    });
    final url = await service(client)
        .uploadPhotoForTest(photo, 'id_front', 'u1');
    expect(url, 'https://res.x/a.jpg');
    expect(sent.url, ProviderVerificationService.cloudinaryUploadUri);
    final fields = (sent as http.MultipartRequest).fields;
    expect(fields['upload_preset'], 'homecare_unsigned');
    expect(fields['folder'], 'providerDocs/u1');
  });

  test('a failed upload gives a clear photo message', () async {
    final client = MockClient((_) async => http.Response('nope', 400));
    expect(
      service(client).uploadPhotoForTest(photo, 'id_front', 'u1'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('photo could not be uploaded'),
        ),
      ),
    );
  });
}
