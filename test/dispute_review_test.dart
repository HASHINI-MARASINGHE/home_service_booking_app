import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/dispute.dart';
import 'package:home_service_bookin_app/screens/admin/admin_disputes_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_dispute_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_theme.dart';
import 'package:home_service_bookin_app/services/admin_service.dart';
import 'package:home_service_bookin_app/services/dispute_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

class _User extends Fake implements User {
  @override
  String get uid => 'pro';
}

class _Db extends Fake implements FirebaseFirestore {}

Dispute dispute({
  DisputeStatus status = DisputeStatus.pending,
  String? response,
  String? decision,
  double? refund,
  String? note,
  Duration deadlineIn = const Duration(hours: 20),
}) => Dispute(
  id: 'b1',
  bookingId: 'b1',
  customerId: 'customer',
  providerId: 'pro',
  reason: 'Poor work quality',
  tag: 'Defective repair',
  description: 'The breaker keeps tripping after the repair.',
  status: status,
  photoCount: 0,
  serviceName: 'AC Deep Clean & Servicing',
  customerName: 'Dilshan Perera',
  providerName: 'Nuwan Fernando',
  bookingRef: 'BK-B1',
  amount: 5500,
  createdAt: testNow,
  respondDeadline: testNow.add(deadlineIn),
  providerResponse: response,
  decision: decision,
  refundAmount: refund,
  adminNote: note,
);

class _FakeAdmin extends AdminService {
  _FakeAdmin(this.items) : super(auth: _Auth(), firestore: _Db());
  final List<Dispute> items;
  final started = <String>[];
  final resolved = <Map<String, Object?>>[];

  @override
  Stream<List<Dispute>> watchDisputes(DisputeStatus status) =>
      Stream.value(items.where((d) => d.status == status).toList());

  @override
  Stream<int> watchPendingDisputeCount() => Stream.value(
    items.where((d) => d.status == DisputeStatus.pending).length,
  );

  @override
  Stream<Dispute?> watchDispute(String id) =>
      Stream.value(items.where((d) => d.id == id).firstOrNull);

  @override
  Stream<List<DisputePhoto>> watchDisputePhotos(String id) =>
      Stream.value(const []);

  @override
  Future<void> startDisputeReview(Dispute dispute) async =>
      started.add(dispute.id);

  @override
  Future<void> resolveDispute({
    required Dispute dispute,
    required String decision,
    double? refundAmount,
    required String note,
  }) async => resolved.add({
    'decision': decision,
    'refund': refundAmount,
    'note': note,
  });
}

class _FakeProviderDisputes extends DisputeService {
  _FakeProviderDisputes(this.item)
    : super(auth: _Auth(), firestore: _Db(), clock: () => testNow);
  final Dispute? item;
  final responses = <String>[];

  @override
  Stream<Dispute?> watchDispute(String bookingId) => Stream.value(item);

  @override
  Stream<List<DisputePhoto>> watchPhotos(String bookingId) =>
      Stream.value(const []);

  @override
  Future<void> respond({
    required Dispute dispute,
    required String response,
  }) async => responses.add(response.trim());
}

void main() {
  group('admin: safety desk', () {
    Widget list(_FakeAdmin service) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: AdminDisputesScreen(service: service)),
    );

    Widget detail(_FakeAdmin service) => MaterialApp(
      theme: AppTheme.light,
      home: AdminDisputeScreen(service: service, disputeId: 'b1'),
    );

    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('the list shows each status and an empty message', (
      tester,
    ) async {
      tall(tester);
      final service = _FakeAdmin([
        dispute(),
        dispute(status: DisputeStatus.resolved, decision: 'Claim rejected'),
      ]);
      await tester.pumpWidget(list(service));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dispute-tile-b1')), findsOneWidget);
      expect(find.text('AC Deep Clean & Servicing'), findsOneWidget);
      expect(find.text('Poor work quality'), findsOneWidget);

      await tester.tap(find.text('Under Review'));
      await tester.pumpAndSettle();
      expect(find.text('No disputes are under review.'), findsOneWidget);

      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dispute-tile-b1')), findsOneWidget);
    });

    testWidgets('a pending dispute can be picked up for review after asking', (
      tester,
    ) async {
      tall(tester);
      final service = _FakeAdmin([dispute(response: 'It was already broken.')]);
      await tester.pumpWidget(detail(service));
      await tester.pumpAndSettle();
      expect(find.text('Dilshan Perera'), findsOneWidget);
      expect(find.text('Nuwan Fernando'), findsOneWidget);
      expect(find.text('LKR 5,500'), findsOneWidget);
      expect(find.text('Poor work quality · Defective repair'), findsOneWidget);
      expect(find.text('It was already broken.'), findsOneWidget);
      expect(find.byKey(const ValueKey('resolve-dispute')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('start-review')));
      await tester.pumpAndSettle();
      expect(find.text('Start the review?'), findsOneWidget);
      expect(service.started, isEmpty);

      await tester.tap(find.byKey(const ValueKey('confirm-dispute-action')));
      await tester.pumpAndSettle();
      expect(service.started, ['b1']);
    });

    testWidgets('a provider who never answered is called out', (tester) async {
      tall(tester);
      await tester.pumpWidget(
        detail(_FakeAdmin([dispute(deadlineIn: const Duration(hours: -1))])),
      );
      await tester.pumpAndSettle();
      // The screen compares with the real clock, so a long-gone deadline.
      expect(
        find.text('The provider did not respond in time.'),
        findsOneWidget,
      );
    });

    testWidgets('resolving needs a decision, a valid refund and a note', (
      tester,
    ) async {
      tall(tester);
      final service = _FakeAdmin([dispute(status: DisputeStatus.underReview)]);
      await tester.pumpWidget(detail(service));
      await tester.pumpAndSettle();

      FilledButton resolve() => tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const ValueKey('resolve-dispute')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(resolve().onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('decision-Partial refund approved')),
      );
      await tester.pump();
      expect(resolve().onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('refund-amount')),
        '9000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('decision-note')),
        'Part refund for the repeat visit.',
      );
      await tester.pump();
      expect(find.textContaining('cannot be more than'), findsOneWidget);
      expect(resolve().onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('refund-amount')),
        '2500',
      );
      await tester.pump();
      expect(resolve().onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('resolve-dispute')));
      await tester.pumpAndSettle();
      expect(service.resolved, isEmpty);
      await tester.tap(find.byKey(const ValueKey('confirm-dispute-action')));
      await tester.pumpAndSettle();
      expect(service.resolved, [
        {
          'decision': 'Partial refund approved',
          'refund': 2500.0,
          'note': 'Part refund for the repeat visit.',
        },
      ]);
    });

    testWidgets('a full refund fills in the job total, a rejection has none', (
      tester,
    ) async {
      tall(tester);
      final service = _FakeAdmin([dispute(status: DisputeStatus.underReview)]);
      await tester.pumpWidget(detail(service));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('decision-Full refund approved')),
      );
      await tester.pump();
      expect(find.text('5500'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('decision-Claim rejected')));
      await tester.pump();
      expect(find.byKey(const ValueKey('refund-amount')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('decision-note')),
        'Not covered by the warranty.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('resolve-dispute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-dispute-action')));
      await tester.pumpAndSettle();
      expect(service.resolved.single['decision'], 'Claim rejected');
      expect(service.resolved.single['refund'], isNull);
    });

    testWidgets('a resolved dispute shows the decision and nothing to do', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        detail(
          _FakeAdmin([
            dispute(
              status: DisputeStatus.resolved,
              decision: 'Partial refund approved',
              refund: 2500,
              note: 'Part refund.',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Partial refund approved'), findsOneWidget);
      expect(find.text('Refund: LKR 2,500'), findsOneWidget);
      expect(find.byKey(const ValueKey('start-review')), findsNothing);
      expect(find.byKey(const ValueKey('resolve-dispute')), findsNothing);
    });
  });

  group('provider: dispute about their job', () {
    Widget screen(_FakeProviderDisputes service) => MaterialApp(
      theme: ProviderTheme.data,
      home: ProviderDisputeScreen(bookingId: 'b1', service: service),
    );

    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('shows what was reported, the time left and sends an answer', (
      tester,
    ) async {
      tall(tester);
      final service = _FakeProviderDisputes(dispute());
      await tester.pumpWidget(screen(service));
      await tester.pumpAndSettle();
      expect(find.text('AC Deep Clean & Servicing'), findsOneWidget);
      expect(find.text('Poor work quality · Defective repair'), findsOneWidget);
      expect(
        find.text('The breaker keeps tripping after the repair.'),
        findsOneWidget,
      );
      expect(find.text('Respond within 20 hours 0 minutes'), findsOneWidget);

      FilledButton send() => tester.widget<FilledButton>(
        find.byKey(const ValueKey('send-response')),
      );
      expect(send().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('provider-response-field')),
        'short',
      );
      await tester.pump();
      expect(send().onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('provider-response-field')),
        'The breaker was already faulty before our visit.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-response')));
      await tester.pumpAndSettle();
      expect(service.responses, [
        'The breaker was already faulty before our visit.',
      ]);
      expect(find.text('Your response was sent.'), findsOneWidget);
    });

    testWidgets('an earlier answer is prefilled and can be updated', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        screen(_FakeProviderDisputes(dispute(response: 'First answer here.'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('First answer here.'), findsOneWidget);
      expect(find.text('Update response'), findsOneWidget);
    });

    testWidgets('after the 24-hour deadline the answer is read only', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        screen(
          _FakeProviderDisputes(dispute(deadlineIn: const Duration(hours: -1))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Response window closed'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-response')), findsNothing);
      expect(
        find.text('You did not respond before the deadline.'),
        findsOneWidget,
      );
    });

    testWidgets('a decided dispute shows the outcome and no answer form', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        screen(
          _FakeProviderDisputes(
            dispute(
              status: DisputeStatus.resolved,
              response: 'Already faulty.',
              decision: 'Claim rejected',
              note: 'Not covered.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Claim rejected'), findsOneWidget);
      expect(find.text('Not covered.'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-response')), findsNothing);
      expect(find.text('Already faulty.'), findsOneWidget);
    });

    testWidgets('a withdrawn dispute says it is gone', (tester) async {
      tall(tester);
      await tester.pumpWidget(screen(_FakeProviderDisputes(null)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dispute-gone')), findsOneWidget);
    });
  });
}
