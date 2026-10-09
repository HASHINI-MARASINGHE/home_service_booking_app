import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/booking_price.dart';
import 'package:home_service_bookin_app/models/quote.dart';
import 'package:home_service_bookin_app/models/quote_flow.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_details_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_quote_section.dart';
import 'package:home_service_bookin_app/screens/provider/provider_theme.dart';
import 'package:home_service_bookin_app/services/app_error.dart';
import 'package:home_service_bookin_app/services/provider_booking_service.dart';
import 'package:home_service_bookin_app/widgets/booking/quote_card.dart';

import 'support/customer_fakes.dart';

const _customer = 'customer';
const _provider = 'pro';
final _now = DateTime.utc(2025, 11, 10, 3, 30);

/// A request made with the quote flow: waiting for the provider's price.
/// (The base price in totalAmount is only the provider's estimate.)
Booking _request({
  BookingStatus status = BookingStatus.pending,
  QuoteStatus quoteStatus = QuoteStatus.pending,
  double? quoted,
  double? accepted,
  List<QuoteEntry> history = const [],
  DateTime? expiresAt,
}) => Booking(
  id: 'b1',
  customerId: _customer,
  providerId: _provider,
  providerName: 'Nuwan',
  serviceName: 'AC repair',
  customerName: 'Dilshan',
  address: 'No. 42 Galle Road',
  status: status,
  scheduledAt: _now.add(const Duration(days: 3)),
  expiresAt: expiresAt,
  estimatedPrice: 4500,
  totalAmount: accepted ?? 4500,
  laborCharge: accepted ?? 4500,
  serviceFee: 0,
  quoteStatus: quoteStatus,
  quotedAmount: quoted,
  acceptedAmount: accepted,
  quoteHistory: history,
);

Booking _send(Booking b, double amount, {String? note, String? reason}) =>
    QuoteFlow.apply(
      b,
      QuoteFlow.send(
        b,
        uid: _provider,
        amount: amount,
        note: note,
        reason: reason,
        now: _now,
      ),
      _now,
    );

Booking _answer(Booking b, double shown, {required bool accept}) =>
    QuoteFlow.apply(
      b,
      QuoteFlow.answer(
        b,
        uid: _customer,
        shownAmount: shown,
        accept: accept,
        now: _now,
      ),
      _now,
    );

void main() {
  group('QuoteInput.parseAmount', () {
    test('accepts whole rupees, with or without commas', () {
      expect(QuoteInput.parseAmount('3500').amount, 3500);
      expect(QuoteInput.parseAmount(' 3,500 ').amount, 3500);
    });

    test('rejects empty, zero, negative, cents, words and huge numbers', () {
      for (final bad in ['', '  ', '0', '-5', '12.5', 'abc', '99999999']) {
        final result = QuoteInput.parseAmount(bad);
        expect(result.amount, isNull, reason: bad);
        expect(result.error, isNotNull, reason: bad);
      }
    });

    test('a reason must say something; a note is optional', () {
      expect(QuoteInput.validateReason(''), isNotNull);
      expect(QuoteInput.validateReason('x'), isNotNull);
      expect(QuoteInput.validateReason('Extra pipework'), isNull);
      expect(QuoteInput.validateNote(null), isNull);
      expect(QuoteInput.validateNote('x' * 501), isNotNull);
    });
  });

  group('bookings made before quotes existed', () {
    test('keep their price and still parse', () {
      final b = Booking.fromMap('old', {
        'customerId': 'c',
        'providerId': 'p',
        'status': 'confirmed',
        'totalAmount': 3000,
      });
      expect(b.usesQuotes, isFalse);
      expect(b.quoteStatus, isNull);
      expect(b.approvedAmount, 3000);
      expect(b.chargeTotal, 3000);
      expect(b.completionBlocker, isNull);
      expect(b.quoteHistory, isEmpty);
    });

    test('with no price at all do not crash and never show LKR 0', () {
      final b = Booking.fromMap('old', {
        'customerId': 'c',
        'providerId': 'p',
        'status': 'pending',
      });
      expect(b.approvedAmount, isNull);
      expect(BookingPrice.forCustomer(b), 'Quote pending');
      expect(BookingPrice.forProvider(b), 'Quote not sent');
    });

    test('a request can still be accepted directly', () {
      final b = Booking.fromMap('old', {
        'customerId': 'c',
        'providerId': 'p',
        'status': 'pending',
        'totalAmount': 3000,
      });
      expect(b.canAcceptWithoutQuote, isTrue);
      expect(
        () => b.validateTransition(BookingStatus.confirmed, _now),
        returnsNormally,
      );
    });
  });

  group('a new request', () {
    test('has no price: the estimate is never the charge', () {
      final b = _request();
      expect(b.usesQuotes, isTrue);
      expect(b.approvedAmount, isNull);
      expect(b.chargeTotal, 0);
      expect(BookingPrice.forCustomer(b), 'Quote pending');
      expect(BookingPrice.forProvider(b), 'Quote not sent');
      expect(b.canSendQuote, isTrue);
      expect(b.canAnswerQuote, isFalse);
      expect(b.canAcceptWithoutQuote, isFalse);
    });

    test('cannot be confirmed by the provider without a quote', () {
      expect(
        () => _request().validateTransition(BookingStatus.confirmed, _now),
        throwsA(isA<StateError>()),
      );
    });

    test('survives the round trip through Firestore data', () {
      final sent = _send(_request(), 3500, note: 'Parts included');
      final copy = Booking.fromMap('b1', {
        'customerId': _customer,
        'providerId': _provider,
        'status': 'pending',
        'quoteStatus': 'quoted',
        'quotedAmount': 3500,
        'quoteNote': 'Parts included',
        'quoteHistory': [for (final e in sent.quoteHistory) e.toMap()],
        'quoteUpdatedAt': Timestamp.fromDate(_now),
      });
      expect(copy.quoteStatus, QuoteStatus.quoted);
      expect(copy.quotedAmount, 3500);
      expect(copy.quoteNote, 'Parts included');
      expect(copy.quoteHistory.single.amount, 3500);
      expect(copy.quoteHistory.single.status, QuoteStatus.quoted);
    });
  });

  group('sending the first quote', () {
    test('moves it to quoted and waits for the customer', () {
      final sent = _send(_request(), 3500, note: ' Parts and labour ');
      expect(sent.quoteStatus, QuoteStatus.quoted);
      expect(sent.quotedAmount, 3500);
      expect(sent.quoteNote, 'Parts and labour');
      expect(sent.awaitingCustomer, isTrue);
      expect(sent.isRevision, isFalse);
      expect(sent.approvedAmount, isNull);
      expect(sent.status, BookingStatus.pending);
      expect(BookingPrice.forCustomer(sent), 'Quote received: LKR 3,500');
      expect(BookingPrice.forProvider(sent), 'Awaiting customer');
    });

    test('the customer is told what and how much', () {
      final change = QuoteFlow.send(
        _request(),
        uid: _provider,
        amount: 3500,
        now: _now,
      );
      expect(change.title, 'New quote received');
      expect(change.body, contains('LKR 3,500'));
      expect(change.body, contains('AC repair'));
    });

    test('cannot be sent twice while the customer has not answered', () {
      final sent = _send(_request(), 3500);
      expect(sent.canSendQuote, isFalse);
      expect(
        () => QuoteFlow.send(sent, uid: _provider, amount: 4000, now: _now),
        throwsA(isA<StateError>()),
      );
    });

    test('is checked: amount, note, owner, expiry and status', () {
      Matcher bad() => anyOf(isA<ArgumentError>(), isA<StateError>());
      for (final amount in [0.0, -1.0, 12.5]) {
        expect(
          () => QuoteFlow.send(
            _request(),
            uid: _provider,
            amount: amount,
            now: _now,
          ),
          throwsA(bad()),
          reason: '$amount',
        );
      }
      expect(
        () => QuoteFlow.send(
          _request(),
          uid: 'someone-else',
          amount: 3500,
          now: _now,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => QuoteFlow.send(
          _request(),
          uid: _provider,
          amount: 3500,
          note: 'x' * 501,
          now: _now,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => QuoteFlow.send(
          _request(expiresAt: _now.subtract(const Duration(minutes: 1))),
          uid: _provider,
          amount: 3500,
          now: _now,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => QuoteFlow.send(
          _request(status: BookingStatus.cancelled),
          uid: _provider,
          amount: 3500,
          now: _now,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('the customer answers', () {
    final quoted = _send(_request(), 3500);

    test('accept confirms the job and locks the price', () {
      final change = QuoteFlow.answer(
        quoted,
        uid: _customer,
        shownAmount: 3500,
        accept: true,
        now: _now,
      );
      expect(change.confirmsJob, isTrue);
      expect(change.fields['status'], 'confirmed');
      expect(change.fields['acceptedAmount'], 3500);
      // Refunds, fees and receipts read these two.
      expect(change.fields['totalAmount'], 3500);
      expect(change.fields['laborCharge'], 3500);
      expect(change.title, 'Customer accepted your quote');

      final done = QuoteFlow.apply(quoted, change, _now);
      expect(done.status, BookingStatus.confirmed);
      expect(done.quoteStatus, QuoteStatus.accepted);
      expect(done.approvedAmount, 3500);
      expect(done.chargeTotal, 3500);
      expect(done.acceptedAt, _now);
      expect(done.awaitingCustomer, isFalse);
      expect(BookingPrice.forCustomer(done), 'Confirmed: LKR 3,500');
      expect(BookingPrice.forProvider(done), 'Approved: LKR 3,500');
      expect(done.quoteHistory.map((e) => e.status), [
        QuoteStatus.quoted,
        QuoteStatus.accepted,
      ]);
    });

    test('decline keeps the request open and lets the provider re-quote', () {
      final declined = _answer(quoted, 3500, accept: false);
      expect(declined.quoteStatus, QuoteStatus.declined);
      expect(declined.status, BookingStatus.pending);
      expect(declined.approvedAmount, isNull);
      expect(declined.canSendQuote, isTrue);
      expect(BookingPrice.forProvider(declined), 'Quote declined');

      final again = _send(declined, 3000);
      expect(again.quotedAmount, 3000);
      expect(again.awaitingCustomer, isTrue);
      expect(again.quoteHistory.map((e) => e.status), [
        QuoteStatus.quoted,
        QuoteStatus.declined,
        QuoteStatus.quoted,
      ]);
    });

    test('an outdated quote cannot be accepted', () {
      // The customer is looking at 3,500 but the provider just changed it.
      final revised = _send(_answer(quoted, 3500, accept: false), 3000);
      expect(
        () => QuoteFlow.answer(
          revised,
          uid: _customer,
          shownAmount: 3500,
          accept: true,
          now: _now,
        ),
        throwsA(
          isA<BookingChangedException>().having(
            (e) => e.message,
            'message',
            contains('updated this quote'),
          ),
        ),
      );
    });

    test(
      'cannot answer twice, on someone else\'s booking or when cancelled',
      () {
        final accepted = _answer(quoted, 3500, accept: true);
        expect(
          () => QuoteFlow.answer(
            accepted,
            uid: _customer,
            shownAmount: 3500,
            accept: true,
            now: _now,
          ),
          throwsA(isA<BookingChangedException>()),
        );
        expect(
          () => QuoteFlow.answer(
            quoted,
            uid: 'stranger',
            shownAmount: 3500,
            accept: true,
            now: _now,
          ),
          throwsA(isA<StateError>()),
        );
        final cancelled = _request(
          status: BookingStatus.cancelled,
          quoteStatus: QuoteStatus.quoted,
          quoted: 3500,
        );
        expect(
          () => QuoteFlow.answer(
            cancelled,
            uid: _customer,
            shownAmount: 3500,
            accept: true,
            now: _now,
          ),
          throwsA(
            isA<BookingChangedException>().having(
              (e) => e.message,
              'message',
              contains('cancelled'),
            ),
          ),
        );
      },
    );

    test('a booking whose time has passed cannot be confirmed', () {
      final stale = QuoteFlow.apply(
        quoted,
        QuoteFlow.send(_request(), uid: _provider, amount: 3500, now: _now),
        _now,
      );
      expect(
        () => QuoteFlow.answer(
          stale,
          uid: _customer,
          shownAmount: 3500,
          accept: true,
          now: _now.add(const Duration(days: 4)),
        ),
        throwsA(isA<BookingChangedException>()),
      );
    });

    test('the price history grows by one entry per step and is capped', () {
      final full = _request(
        quoteStatus: QuoteStatus.declined,
        quoted: 100,
        history: [
          for (var i = 0; i < QuoteHistory.maxEntries; i++)
            QuoteEntry(
              amount: 100,
              status: QuoteStatus.quoted,
              createdAt: _now,
            ),
        ],
      );
      expect(
        () => QuoteFlow.send(full, uid: _provider, amount: 200, now: _now),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('revising a confirmed job', () {
    final confirmed = _answer(_send(_request(), 3500), 3500, accept: true);

    test('needs a reason and a different price', () {
      expect(
        () => QuoteFlow.send(
          confirmed,
          uid: _provider,
          amount: 5000,
          reason: '',
          now: _now,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => QuoteFlow.send(
          confirmed,
          uid: _provider,
          amount: 3500,
          reason: 'Same price',
          now: _now,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('keeps the accepted price until the customer approves', () {
      final revised = _send(confirmed, 5000, reason: 'Extra pipework found');
      expect(revised.status, BookingStatus.confirmed);
      expect(revised.quoteStatus, QuoteStatus.quoted);
      expect(revised.isRevision, isTrue);
      expect(revised.quotedAmount, 5000);
      expect(revised.acceptedAmount, 3500);
      expect(revised.approvedAmount, 3500);
      expect(revised.chargeTotal, 3500);
      expect(BookingPrice.forCustomer(revised), 'Revised quote: LKR 5,000');
      expect(BookingPrice.forProvider(revised), 'Revision awaiting customer');
      expect(revised.quoteHistory.last.reason, 'Extra pipework found');
    });

    test('a declined revision leaves the original price valid', () {
      final revised = _send(confirmed, 5000, reason: 'Extra pipework found');
      final declined = _answer(revised, 5000, accept: false);
      expect(declined.quoteStatus, QuoteStatus.declined);
      expect(declined.revisionDeclined, isTrue);
      expect(declined.acceptedAmount, 3500);
      expect(declined.approvedAmount, 3500);
      expect(declined.status, BookingStatus.confirmed);
      expect(declined.canReviseQuote, isTrue);
      expect(declined.completionBlocker, isNull);
    });

    test('an accepted revision replaces the price without re-confirming', () {
      final revised = _send(confirmed, 5000, reason: 'Extra pipework found');
      final change = QuoteFlow.answer(
        revised,
        uid: _customer,
        shownAmount: 5000,
        accept: true,
        now: _now,
      );
      expect(change.confirmsJob, isFalse);
      expect(change.fields.containsKey('status'), isFalse);
      expect(change.title, 'Revised quote accepted');
      final done = QuoteFlow.apply(revised, change, _now);
      expect(done.acceptedAmount, 5000);
      expect(done.totalAmount, 5000);
      expect(done.status, BookingStatus.confirmed);
      expect(done.awaitingCustomer, isFalse);
    });

    test('is only for a confirmed job that is not already waiting', () {
      expect(
        () => QuoteFlow.send(
          _request(),
          uid: _provider,
          amount: 5000,
          reason: 'Why',
          now: _now,
        ),
        throwsA(isA<StateError>()),
      );
      final revised = _send(confirmed, 5000, reason: 'Extra pipework found');
      expect(
        () => QuoteFlow.send(
          revised,
          uid: _provider,
          amount: 6000,
          reason: 'Even more',
          now: _now,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('completing a job', () {
    test('needs an accepted price', () {
      final unpriced = _request(
        status: BookingStatus.confirmed,
        quoteStatus: QuoteStatus.accepted,
      );
      expect(unpriced.approvedAmount, isNull);
      expect(unpriced.completionBlocker, contains('no approved price'));
      expect(
        () => unpriced.validateTransition(BookingStatus.completed, _now),
        throwsA(isA<StateError>()),
      );
    });

    test('is allowed once the customer accepted', () {
      final accepted = _answer(_send(_request(), 3500), 3500, accept: true);
      expect(accepted.completionBlocker, isNull);
      expect(
        () => accepted.validateTransition(BookingStatus.completed, _now),
        returnsNormally,
      );
    });

    test('waits while a revision is unanswered', () {
      final accepted = _answer(_send(_request(), 3500), 3500, accept: true);
      final revised = _send(accepted, 5000, reason: 'Extra pipework found');
      expect(revised.completionBlocker, contains('Wait for the customer'));
      expect(
        () => revised.validateTransition(BookingStatus.completed, _now),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('price labels never show LKR 0 or Not provided', () {
    final states = <String, Booking>{
      'new': _request(),
      'quoted': _send(_request(), 3500),
      'declined': _answer(_send(_request(), 3500), 3500, accept: false),
      'accepted': _answer(_send(_request(), 3500), 3500, accept: true),
      'cancelled': _request(status: BookingStatus.cancelled),
      'declined request': _request(status: BookingStatus.declined),
    };
    states.forEach((name, b) {
      test(name, () {
        for (final label in [
          BookingPrice.forCustomer(b),
          BookingPrice.forProvider(b),
          BookingPrice.amountOr(b, 'Quote pending'),
        ]) {
          expect(label, isNot(contains('LKR 0')), reason: label);
          expect(label, isNot(contains('Not provided')), reason: label);
          expect(label, isNotEmpty);
        }
      });
    });
  });

  group('provider quote form', () {
    final sent = <(double, String?, String?)>[];

    Future<void> pump(
      WidgetTester tester,
      Booking booking, {
      _FakeProviderService? service,
    }) async {
      sent.clear();
      // Tall enough to show the whole form without scrolling.
      await tester.binding.setSurfaceSize(const Size(390, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ProviderTheme.data,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProviderQuoteSection(
                booking: booking,
                service: service ?? _FakeProviderService(sent),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('a new request shows the form, not the old price', (
      tester,
    ) async {
      await pump(tester, _request());
      expect(find.text('Enter your quote'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-quote')), findsOneWidget);
      expect(find.textContaining('LKR 0'), findsNothing);
    });

    testWidgets('empty, zero and cents are refused before anything is sent', (
      tester,
    ) async {
      await pump(tester, _request());
      Future<void> trySend(String text) async {
        await tester.enterText(
          find.byKey(const ValueKey('quote-amount')),
          text,
        );
        await tester.tap(find.byKey(const ValueKey('send-quote')));
        await tester.pump();
      }

      await trySend('');
      expect(find.text('Enter your price in LKR.'), findsOneWidget);
      await trySend('0');
      expect(find.text('The price must be more than 0.'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('sends the amount and note once, even if tapped twice', (
      tester,
    ) async {
      await pump(tester, _request());
      await tester.enterText(
        find.byKey(const ValueKey('quote-amount')),
        '3500',
      );
      await tester.enterText(
        find.byKey(const ValueKey('quote-note')),
        'Parts included',
      );
      final button = find.byKey(const ValueKey('send-quote'));
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(sent, [(3500.0, 'Parts included', null)]);
      expect(
        find.text('Quote sent. The customer will review it.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a retry when the network fails', (tester) async {
      final failing = _FakeProviderService(sent)
        ..error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      await pump(tester, _request(), service: failing);
      await tester.enterText(
        find.byKey(const ValueKey('quote-amount')),
        '3500',
      );
      await tester.tap(find.byKey(const ValueKey('send-quote')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quote-error')), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      failing.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(sent, [(3500.0, null, null)]);
    });

    testWidgets('after sending: awaiting approval, no form, no re-sending', (
      tester,
    ) async {
      await pump(tester, _send(_request(), 3500, note: 'Parts included'));
      expect(find.text('Awaiting customer approval'), findsOneWidget);
      expect(find.text('LKR 3,500'), findsOneWidget);
      expect(find.text('Parts included'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-quote')), findsNothing);
      expect(find.byKey(const ValueKey('quote-amount')), findsNothing);
    });

    testWidgets('an expired request cannot be quoted', (tester) async {
      await pump(
        tester,
        _request(expiresAt: DateTime.now().subtract(const Duration(hours: 1))),
      );
      expect(find.text('This request has expired'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-quote')), findsNothing);
    });

    testWidgets('a confirmed job offers Revise quote and needs a reason', (
      tester,
    ) async {
      final confirmed = _answer(_send(_request(), 3500), 3500, accept: true);
      await pump(tester, confirmed);
      expect(find.text('Approved price'), findsOneWidget);
      expect(find.text('LKR 3,500'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('revise-quote')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('quote-amount')),
        '5000',
      );
      await tester.tap(find.byKey(const ValueKey('send-quote')));
      await tester.pump();
      expect(
        find.text('Tell the customer why the price changed.'),
        findsOneWidget,
      );
      expect(sent, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('quote-reason')),
        'Extra pipework found',
      );
      await tester.tap(find.byKey(const ValueKey('send-quote')));
      await tester.pumpAndSettle();
      expect(sent, [(5000.0, null, 'Extra pipework found')]);
    });

    testWidgets('a revision in progress shows both prices', (tester) async {
      final confirmed = _answer(_send(_request(), 3500), 3500, accept: true);
      await pump(
        tester,
        _send(confirmed, 5000, reason: 'Extra pipework found'),
      );
      expect(find.text('Revision awaiting customer approval'), findsOneWidget);
      expect(find.text('LKR 5,000'), findsOneWidget);
      expect(find.textContaining('LKR 3,500'), findsWidgets);
      expect(find.byKey(const ValueKey('revise-quote')), findsNothing);
    });
  });

  group('customer quote card', () {
    Future<FakeBookingService> pump(
      WidgetTester tester,
      Booking booking, {
      FakeBookingService? service,
    }) async {
      final fake = service ?? FakeBookingService(bookings: [booking]);
      await pumpCustomer(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: QuoteCard(booking: booking)),
        ),
        bookings: fake,
        size: const Size(390, 1600),
      );
      return fake;
    }

    testWidgets('waiting for a quote: says so and never shows LKR 0', (
      tester,
    ) async {
      await pump(tester, _request());
      expect(find.text('Quote pending'), findsOneWidget);
      expect(find.byKey(const ValueKey('accept-quote')), findsNothing);
      expect(find.textContaining('LKR 0'), findsNothing);
    });

    testWidgets('a quote shows the amount and note with Accept and Decline', (
      tester,
    ) async {
      await pump(tester, _send(_request(), 3500, note: 'Parts included'));
      expect(find.text('Quote received'), findsOneWidget);
      expect(find.text('LKR 3,500'), findsOneWidget);
      expect(find.text('Parts included'), findsOneWidget);
      expect(find.byKey(const ValueKey('accept-quote')), findsOneWidget);
      expect(find.byKey(const ValueKey('decline-quote')), findsOneWidget);
    });

    testWidgets('Accept sends the amount on screen', (tester) async {
      final quoted = _send(_request(), 3500);
      final service = await pump(tester, quoted);
      await tester.tap(find.byKey(const ValueKey('accept-quote')));
      await tester.pumpAndSettle();
      expect(service.quoteAnswers, {'b1': true});
      expect(
        find.text('Quote accepted. Your booking is confirmed.'),
        findsOneWidget,
      );
    });

    testWidgets('Decline asks first, then declines', (tester) async {
      final quoted = _send(_request(), 3500);
      final service = await pump(tester, quoted);
      await tester.tap(find.byKey(const ValueKey('decline-quote')));
      await tester.pumpAndSettle();
      expect(find.text('Decline this quote?'), findsOneWidget);
      await tester.tap(find.text('Keep quote'));
      await tester.pumpAndSettle();
      expect(service.quoteAnswers, isEmpty);

      await tester.tap(find.byKey(const ValueKey('decline-quote')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Decline quote'),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.quoteAnswers, {'b1': false});
    });

    testWidgets('a stale quote shows a clear message and can be retried', (
      tester,
    ) async {
      final quoted = _send(_request(), 3500);
      final service = FakeBookingService(bookings: [quoted])
        ..quoteError = const BookingChangedException(
          'The provider updated this quote. Please review the new price '
          'before answering.',
        );
      await pump(tester, quoted, service: service);
      await tester.tap(find.byKey(const ValueKey('accept-quote')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quote-error')), findsOneWidget);
      expect(find.textContaining('updated this quote'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(service.quoteAnswers, {'b1': true});
    });

    testWidgets('a revision explains what stays valid until accepted', (
      tester,
    ) async {
      final confirmed = _answer(_send(_request(), 3500), 3500, accept: true);
      await pump(
        tester,
        _send(confirmed, 5000, reason: 'Extra pipework found'),
      );
      expect(find.text('Revised quote'), findsOneWidget);
      expect(find.text('LKR 5,000'), findsOneWidget);
      expect(
        find.textContaining('approved price is LKR 3,500'),
        findsOneWidget,
      );
      expect(find.text('Reason: Extra pipework found'), findsOneWidget);
    });

    testWidgets('an accepted price is shown as locked', (tester) async {
      await pump(tester, _answer(_send(_request(), 3500), 3500, accept: true));
      expect(find.byKey(const ValueKey('quote-locked')), findsOneWidget);
      expect(find.text('Price confirmed'), findsOneWidget);
      expect(find.text('LKR 3,500'), findsOneWidget);
      expect(find.byKey(const ValueKey('accept-quote')), findsNothing);
    });

    testWidgets('an old booking with a price shows it as confirmed', (
      tester,
    ) async {
      await pump(tester, booking());
      expect(find.text('Price confirmed'), findsOneWidget);
      expect(find.text('LKR 5,500'), findsOneWidget);
    });
  });

  group('booking details and history (customer)', () {
    testWidgets('a new request shows Quote pending, never LKR 0', (
      tester,
    ) async {
      final b = booking(
        status: BookingStatus.pending,
        quoteStatus: QuoteStatus.pending,
        noPrice: true,
      );
      await pumpCustomer(
        tester,
        const BookingDetailsScreen(bookingId: 'b1'),
        bookings: FakeBookingService(bookings: [b]),
        size: const Size(390, 3200),
      );
      expect(find.text('Quote pending'), findsWidgets);
      expect(find.textContaining('LKR 0'), findsNothing);
      expect(find.textContaining('Not provided'), findsNothing);
    });
  });
}

/// Records what the provider form sends instead of calling Firestore.
class _FakeProviderService extends ProviderBookingService {
  _FakeProviderService(this.sent) : super(auth: _Auth(), firestore: _Db());

  final List<(double, String?, String?)> sent;
  Object? error;

  @override
  Future<void> sendQuote(String id, double amount, {String? note}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    sent.add((amount, note?.trim().isEmpty ?? true ? null : note, null));
  }

  @override
  Future<void> reviseQuote(
    String id,
    double amount, {
    required String reason,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    sent.add((amount, note?.trim().isEmpty ?? true ? null : note, reason));
  }
}

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}
