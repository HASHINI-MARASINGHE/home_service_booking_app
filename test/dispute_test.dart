// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/dispute.dart';
import 'package:home_service_bookin_app/screens/customer/disputes/dispute_screen.dart';
import 'package:home_service_bookin_app/services/dispute_photo_picker.dart';
import 'package:home_service_bookin_app/services/dispute_service.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

/// A 1x1 PNG, so `Image.memory` has something real to decode.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _Picker implements DisputePhotoPicker {
  int picked = 0;

  @override
  Future<DisputePhoto?> pick() async {
    picked++;
    return DisputePhoto.fromBytes(_png, mimeType: 'image/png');
  }
}

/// Keeps disputes in memory so the screen can be driven end to end.
class _FakeDisputes extends DisputeService {
  _FakeDisputes({Dispute? dispute, List<DisputePhoto> photos = const []})
    : _dispute = dispute,
      _photos = photos,
      super(auth: _Auth(), firestore: _Db(), clock: () => testNow);

  Dispute? _dispute;
  List<DisputePhoto> _photos;
  final _changes = StreamController<void>.broadcast();
  final submitted = <Map<String, Object?>>[];
  final updated = <Map<String, Object?>>[];
  final withdrawn = <String>[];

  @override
  Stream<Dispute?> watchDispute(String bookingId) async* {
    yield _dispute;
    yield* _changes.stream.map((_) => _dispute);
  }

  @override
  Stream<List<DisputePhoto>> watchPhotos(String bookingId) async* {
    yield _photos;
    yield* _changes.stream.map((_) => _photos);
  }

  @override
  Future<void> submit({
    required Booking booking,
    required String reason,
    String? tag,
    required String description,
    required List<DisputePhoto> photos,
  }) async {
    DisputeService.validate(
      reason: reason,
      description: description,
      photos: photos,
    );
    submitted.add({
      'reason': reason,
      'tag': tag,
      'description': description.trim(),
      'photos': photos.length,
    });
    _dispute = _make(
      booking.id,
      reason,
      tag,
      description.trim(),
      photos.length,
    );
    _photos = [
      for (var i = 0; i < photos.length; i++)
        DisputePhoto(id: 'p$i', base64: photos[i].base64),
    ];
    _changes.add(null);
  }

  @override
  Future<void> update({
    required Dispute dispute,
    required String reason,
    String? tag,
    required String description,
    required List<DisputePhoto> photos,
  }) async {
    DisputeService.validate(
      reason: reason,
      description: description,
      photos: photos,
    );
    updated.add({
      'reason': reason,
      'tag': tag,
      'description': description.trim(),
      'photos': photos.length,
    });
    _dispute = _make(
      dispute.id,
      reason,
      tag,
      description.trim(),
      photos.length,
    );
    _photos = [
      for (var i = 0; i < photos.length; i++)
        DisputePhoto(id: 'p$i', base64: photos[i].base64),
    ];
    _changes.add(null);
  }

  @override
  Future<void> withdraw(Dispute dispute) async {
    withdrawn.add(dispute.id);
    _dispute = null;
    _photos = const [];
    _changes.add(null);
  }
}

Dispute _make(
  String bookingId,
  String reason,
  String? tag,
  String description,
  int photos, {
  DisputeStatus status = DisputeStatus.pending,
  String? decision,
  double? refund,
  String? note,
}) => Dispute(
  id: bookingId,
  bookingId: bookingId,
  customerId: testUser.uid,
  providerId: 'pro',
  reason: reason,
  tag: tag,
  description: description,
  status: status,
  photoCount: photos,
  createdAt: testNow,
  respondDeadline: testNow.add(const Duration(hours: 24)),
  decision: decision,
  refundAmount: refund,
  adminNote: note,
);

/// A completed job whose warranty has [remaining] left (negative = ended).
Booking completed(Duration remaining) {
  final base = booking(status: BookingStatus.completed, paymentStatus: 'paid');
  final completedAt = testNow.add(remaining).subtract(DisputeWarranty.window);
  return Booking.fromMap(base.id, {
    ...base.toMap(),
    'completedAt': Timestamp.fromDate(completedAt),
  });
}

const _reason = 'Poor work quality';
const _text = 'The technician left the breaker tripping.';

void main() {
  late _Picker picker;
  setUp(() {
    picker = _Picker();
    DisputePhotoPicker.instance = picker;
  });
  tearDown(() => DisputePhotoPicker.instance = SystemDisputePhotoPicker());

  Future<void> open(WidgetTester tester, Booking job, _FakeDisputes service) =>
      pumpCustomer(
        tester,
        DisputeScreen(bookingId: job.id, service: service),
        size: const Size(390, 2200),
        bookings: FakeBookingService(bookings: [job]),
      );

  Future<void> pickReason(
    WidgetTester tester, [
    String reason = _reason,
  ]) async {
    await tester.tap(find.byKey(const ValueKey('dispute-reason')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(reason).last);
    await tester.pumpAndSettle();
  }

  Future<void> describe(WidgetTester tester, [String text = _text]) async {
    await tester.enterText(
      find.byKey(const ValueKey('dispute-description')),
      text,
    );
    await tester.pump();
  }

  FilledButton submitButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const ValueKey('submit-dispute')),
      matching: find.byType(FilledButton),
    ),
  );

  group('3-day warranty', () {
    test('counts down in days and hours, then ends', () {
      final job = completed(const Duration(days: 2, hours: 5, minutes: 10));
      expect(DisputeWarranty.isOpen(job, testNow), isTrue);
      expect(
        DisputeWarranty.label(job, testNow),
        'Warranty: 2 days 5 hours left',
      );
      expect(
        DisputeWarranty.label(completed(const Duration(hours: 5)), testNow),
        'Warranty: 5 hours 0 minutes left',
      );
      expect(
        DisputeWarranty.label(completed(const Duration(minutes: 20)), testNow),
        'Warranty: 20 minutes left',
      );
      final ended = completed(const Duration(minutes: -1));
      expect(DisputeWarranty.isOpen(ended, testNow), isFalse);
      expect(DisputeWarranty.label(ended, testNow), 'Warranty period ended');
    });

    test('exactly three days after completion is already too late', () {
      expect(
        DisputeWarranty.isOpen(completed(Duration.zero), testNow),
        isFalse,
      );
    });

    test('a job that is not completed has no warranty', () {
      final job = booking(); // confirmed, no completedAt
      expect(DisputeWarranty.isOpen(job, testNow), isFalse);
    });
  });

  group('validation', () {
    final photo = DisputePhoto.fromBytes(_png);

    test('needs a reason and at least 10 characters', () {
      expect(
        () => DisputeService.validate(
          reason: '',
          description: _text,
          photos: const [],
        ),
        throwsA(isA<DisputeException>()),
      );
      expect(
        () => DisputeService.validate(
          reason: _reason,
          description: 'too short',
          photos: const [],
        ),
        throwsA(isA<DisputeException>()),
      );
      DisputeService.validate(
        reason: _reason,
        description: _text,
        photos: [photo],
      );
    });

    test('allows at most 5 photos, each small enough for one document', () {
      expect(
        () => DisputeService.validate(
          reason: _reason,
          description: _text,
          photos: List.filled(6, photo),
        ),
        throwsA(isA<DisputeException>()),
      );
      final big = DisputePhoto(
        id: '',
        base64: 'A' * (DisputeService.maxPhotoBytes * 4 ~/ 3 + 100),
      );
      expect(
        () => DisputeService.validate(
          reason: _reason,
          description: _text,
          photos: [big],
        ),
        throwsA(isA<DisputeException>()),
      );
    });

    test('a photo survives the Base64 round trip', () {
      final back = DisputePhoto.fromBytes(_png);
      expect(back.bytes, _png);
      expect(back.sizeBytes, _png.length);
    });
  });

  group('create', () {
    testWidgets('submit stays locked until a reason and a description exist', (
      tester,
    ) async {
      final service = _FakeDisputes();
      await open(tester, completed(const Duration(days: 2)), service);
      expect(find.text('Reason for Dispute *'), findsOneWidget);
      expect(find.text('0 / 1000'), findsOneWidget);
      expect(submitButton(tester).onPressed, isNull);

      await pickReason(tester);
      expect(submitButton(tester).onPressed, isNull);
      await describe(tester, 'too short');
      expect(submitButton(tester).onPressed, isNull);
      await describe(tester);
      expect(find.text('${_text.length} / 1000'), findsOneWidget);
      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('shows the warranty countdown while it is open', (
      tester,
    ) async {
      await open(
        tester,
        completed(const Duration(days: 2, hours: 5, minutes: 10)),
        _FakeDisputes(),
      );
      expect(find.text('Warranty: 2 days 5 hours left'), findsOneWidget);
      expect(find.text('Submit Dispute Claim'), findsOneWidget);
    });

    testWidgets('after 3 days the button is disabled and says so', (
      tester,
    ) async {
      await open(tester, completed(const Duration(hours: -2)), _FakeDisputes());
      expect(find.text('Warranty period ended'), findsNWidgets(2));
      await pickReason(tester);
      await describe(tester);
      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('a job that is not completed cannot be disputed', (
      tester,
    ) async {
      await open(tester, booking(), _FakeDisputes());
      expect(find.byKey(const ValueKey('dispute-description')), findsNothing);
      expect(find.textContaining('once the job has been completed'), findsOne);
    });

    testWidgets('submitting saves reason, quick tag, text and photos, then '
        'shows the Pending tracker', (tester) async {
      final service = _FakeDisputes();
      await open(tester, completed(const Duration(days: 2)), service);
      await pickReason(tester);
      await tester.tap(find.text('Defective repair'));
      await describe(tester);
      await tester.tap(find.byKey(const ValueKey('add-dispute-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-dispute-photo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dispute-photo-1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('submit-dispute')));
      await tester.pumpAndSettle();

      expect(service.submitted, [
        {
          'reason': _reason,
          'tag': 'Defective repair',
          'description': _text,
          'photos': 2,
        },
      ]);
      expect(find.text('Your Dispute'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byKey(const ValueKey('dispute-photo-1')), findsOneWidget);
    });

    testWidgets('photos can be removed and are capped at five', (tester) async {
      await open(tester, completed(const Duration(days: 2)), _FakeDisputes());
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('add-dispute-photo')));
        await tester.pumpAndSettle();
      }
      expect(picker.picked, 5);
      expect(find.byKey(const ValueKey('add-dispute-photo')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('remove-photo-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dispute-photo-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('dispute-photo-4')), findsNothing);
      expect(find.byKey(const ValueKey('add-dispute-photo')), findsOneWidget);
    });

    testWidgets('Clear empties the description', (tester) async {
      await open(tester, completed(const Duration(days: 2)), _FakeDisputes());
      await describe(tester);
      await tester.tap(find.byKey(const ValueKey('clear-description')));
      await tester.pump();
      expect(find.text('0 / 1000'), findsOneWidget);
    });
  });

  group('read, update and delete', () {
    final job = completed(const Duration(days: 2));

    testWidgets('an existing dispute opens its tracker, never a second form', (
      tester,
    ) async {
      final service = _FakeDisputes(
        dispute: _make('b1', _reason, 'Billing issue', _text, 1),
        photos: [DisputePhoto(id: 'p0', base64: base64Encode(_png))],
      );
      await open(tester, job, service);
      expect(find.byKey(const ValueKey('dispute-description')), findsNothing);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.textContaining('We will respond by'), findsOneWidget);
      expect(find.text('$_reason · Billing issue'), findsOneWidget);
      expect(find.text(_text), findsOneWidget);
      expect(find.byKey(const ValueKey('dispute-photo-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-dispute')), findsOneWidget);
      expect(find.byKey(const ValueKey('withdraw-dispute')), findsOneWidget);
    });

    testWidgets('a pending dispute can be edited', (tester) async {
      final service = _FakeDisputes(
        dispute: _make('b1', _reason, null, _text, 0),
      );
      await open(tester, job, service);
      await tester.tap(find.byKey(const ValueKey('edit-dispute')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Dispute'), findsOneWidget);
      expect(find.text(_text), findsOneWidget); // prefilled
      expect(find.text('Save Changes'), findsOneWidget);

      await describe(tester, 'The breaker still trips every time.');
      await tester.tap(find.byKey(const ValueKey('submit-dispute')));
      await tester.pumpAndSettle();

      expect(
        service.updated.single['description'],
        'The breaker still trips every time.',
      );
      expect(find.text('Your Dispute'), findsOneWidget);
      expect(find.text('The breaker still trips every time.'), findsOneWidget);
    });

    testWidgets('withdrawing asks first, then removes the dispute', (
      tester,
    ) async {
      final service = _FakeDisputes(
        dispute: _make('b1', _reason, null, _text, 0),
      );
      await open(tester, job, service);
      await tester.tap(find.byKey(const ValueKey('withdraw-dispute')));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw dispute?'), findsOneWidget);

      await tester.tap(find.text('Keep dispute'));
      await tester.pumpAndSettle();
      expect(service.withdrawn, isEmpty);

      await tester.tap(find.byKey(const ValueKey('withdraw-dispute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-withdraw')));
      await tester.pumpAndSettle();
      expect(service.withdrawn, ['b1']);
    });

    testWidgets('a dispute under review can no longer be edited or withdrawn', (
      tester,
    ) async {
      final service = _FakeDisputes(
        dispute: _make(
          'b1',
          _reason,
          null,
          _text,
          0,
          status: DisputeStatus.underReview,
        ),
      );
      await open(tester, job, service);
      expect(find.textContaining('is reviewing your claim'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-dispute')), findsNothing);
      expect(find.byKey(const ValueKey('withdraw-dispute')), findsNothing);
    });

    testWidgets('a resolved dispute shows the decision and refund', (
      tester,
    ) async {
      final service = _FakeDisputes(
        dispute: _make(
          'b1',
          _reason,
          null,
          _text,
          0,
          status: DisputeStatus.resolved,
          decision: 'Refund approved',
          refund: 2500,
          note: 'Part refund for the repeat visit.',
        ),
      );
      await open(tester, job, service);
      expect(find.text('Refund approved'), findsOneWidget);
      expect(find.text('Refund: LKR 2,500'), findsOneWidget);
      expect(find.text('Part refund for the repeat visit.'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-dispute')), findsNothing);
      expect(find.byKey(const ValueKey('withdraw-dispute')), findsNothing);
    });
  });
}
