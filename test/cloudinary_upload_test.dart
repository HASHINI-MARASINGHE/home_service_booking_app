// Test-only Firestore fakes implement classes FlutterFire marks @sealed.
// ignore_for_file: subtype_of_sealed_class
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Image, Scrollable;
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_details_screen.dart';
import 'package:home_service_bookin_app/services/customer_booking_service.dart';
import 'package:home_service_bookin_app/services/image_upload_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/customer_fakes.dart';

class _User extends Fake implements User {
  @override
  String get uid => testUser.uid;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

/// Records what `updateDetails` writes inside its transaction.
class _Db extends Fake implements FirebaseFirestore {
  _Db(this.data);
  final Map<String, dynamic> data;
  Map<String, dynamic>? written;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection();

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async => handler(_Tx(this));
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Doc();
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this._data);
  final Map<String, dynamic> _data;
  @override
  String get id => 'b1';
  @override
  Map<String, dynamic>? data() => _data;
  @override
  DocumentReference<Map<String, dynamic>> get reference => _Doc();
}

class _Tx extends Fake implements Transaction {
  _Tx(this.db);
  final _Db db;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async => _Snapshot(db.data) as DocumentSnapshot<T>;

  @override
  Transaction update(
    DocumentReference<Object?> documentReference,
    Map<Object, Object?> data,
  ) {
    db.written = data.cast<String, dynamic>();
    return this;
  }
}



void main() {
  const kept =
      'https://res.cloudinary.com/dclo5pyll/image/upload/v1/bookings/kept.jpg';
  const legacy =
      'https://res.cloudinary.com/dclo5pyll/image/upload/v1/bookings/legacy.jpg';
  final original = booking();

  BookingEdit edit({List<String> keep = const [kept], int newPhotos = 1}) =>
      BookingEdit(
        address: original.address,
        accessNotes: '',
        contactPhone: '+94771234567',
        jobNotes: 'Rattling noise',
        keptPhotoUrls: keep,
        newPhotos: [
          for (var i = 0; i < newPhotos; i++)
            Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, i, 2, 3]),
        ],
      );

  test('uploads new photos unsigned and stores secure_url', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'secure_url': 'https://res.cloudinary.com/dclo5pyll/image/upload/v2/bookings/new.jpg',
        }),
        200,
      );
    });
    final db = _Db(original.toMap());
    final service = CustomerBookingService(
      auth: _Auth(),
      firestore: db,
      imageUploads: ImageUploadService(client: client),
      clock: () => testNow,
    );
    final withLegacy = Booking.fromMap(original.id, {
      ...original.toMap(),
      'photoUrls': [kept, legacy, 'https://images.unsplash.com/x.jpg'],
    });

    await service.updateDetails(withLegacy, edit());

    expect(requests, hasLength(1));
    final request = requests.single;
    expect(
      request.url.toString(),
      'https://api.cloudinary.com/v1_1/dclo5pyll/image/upload',
    );
    final body = latin1.decode(request.bodyBytes);
    expect(body, contains('name="upload_preset"\r\n\r\nhomecare_unsigned'));
    expect(body, contains('name="folder"\r\n\r\nbookings/b1'));
    expect(
      body,
      contains(
        'filename="${original.id}_${testNow.millisecondsSinceEpoch}_0.jpg"',
      ),
    );
    expect(body.toLowerCase(), isNot(contains('api_key')));
    expect(body.toLowerCase(), isNot(contains('signature')));
    expect(db.written?['photoUrls'], [
      kept,
      'https://res.cloudinary.com/dclo5pyll/image/upload/v2/bookings/new.jpg',
    ]);
  });

  test('a failed upload throws a friendly error and writes nothing', () async {
    final db = _Db(original.toMap());
    final service = CustomerBookingService(
      auth: _Auth(),
      firestore: db,
      imageUploads: ImageUploadService(
        client: MockClient((_) async => http.Response('bad preset', 400)),
      ),
      clock: () => testNow,
    );

    await expectLater(
      service.updateDetails(original, edit()),
      throwsA(
        isA<ImageUploadException>().having(
          (e) => e.message,
          'message',
          ImageUploadService.failedMessage,
        ),
      ),
    );
    expect(db.written, isNull);
  });

  test('network errors map to the same upload message', () async {
    final service = CustomerBookingService(
      auth: _Auth(),
      firestore: _Db(original.toMap()),
      imageUploads: ImageUploadService(
        client: MockClient(
          (_) async => throw http.ClientException('offline'),
        ),
      ),
      clock: () => testNow,
    );
    await expectLater(
      service.updateDetails(original, edit()),
      throwsA(isA<ImageUploadException>()),
    );
  });

  test('saving without new photos makes no upload request', () async {
    var calls = 0;
    final db = _Db(original.toMap());
    final service = CustomerBookingService(
      auth: _Auth(),
      firestore: db,
      imageUploads: ImageUploadService(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      ),
      clock: () => testNow,
    );
    await service.updateDetails(original, edit(newPhotos: 0));
    expect(calls, 0);
    expect(db.written?['photoUrls'], [kept]);
  });

  testWidgets('Booking Details shows Cloudinary issue photos', (tester) async {
    final withPhoto = Booking.fromMap(original.id, {
      ...original.toMap(),
      'photoUrls': [kept],
    });
    await pumpCustomer(
      tester,
      BookingDetailsScreen(bookingId: original.id),
      bookings: FakeBookingService(bookings: [withPhoto]),
    );
    await tester.scrollUntilVisible(
      find.text('Issue Photos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final image = tester.widget<Image>(
      find.byWidgetPredicate(
        (w) => w is Image && w.semanticLabel == 'Issue photo 1',
      ),
    );
    expect((image.image as dynamic).url, kept);
  });
}
