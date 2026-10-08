import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/app_notification.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/models/provider_profile.dart';
import 'package:home_service_bookin_app/models/rating_stats.dart';
import 'package:home_service_bookin_app/models/review.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/booking_details_screen.dart';
import 'package:home_service_bookin_app/screens/customer/bookings/review_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_job_details_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_profile_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/services/provider_profile_service.dart';
import 'package:home_service_bookin_app/widgets/booking/booking_widgets.dart';
import 'package:home_service_bookin_app/screens/provider/provider_notifications_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_theme.dart';
import 'package:home_service_bookin_app/services/provider_booking_service.dart';
import 'package:home_service_bookin_app/services/provider_notification_service.dart';

import 'package:home_service_bookin_app/theme/app_theme.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _ProviderService extends ProviderBookingService {
  _ProviderService(this.review) : super(auth: _Auth(), firestore: _Firestore());
  final Review? review;

  @override
  Stream<Review?> watchReview(String bookingId) => Stream.value(review);
}

class _Notifications extends ProviderNotificationService {
  _Notifications(this.items) : super(auth: _Auth(), firestore: _Firestore());
  final List<AppNotification> items;
  final read = <String>[];

  @override
  Stream<List<AppNotification>> watchNotifications() => Stream.value(items);

  @override
  Future<void> markRead(String id) async => read.add(id);
}

class _ProfileService extends ProviderProfileService {
  _ProfileService({this.stats, this.baseline})
    : super(auth: _Auth(), firestore: _Firestore());
  final RatingStats? stats;
  final double? baseline;

  @override
  Stream<ProviderProfile> watchProfile() => Stream.value(
    ProviderProfile(providerId: 'pro', profession: 'AC', rating: baseline),
  );

  @override
  Stream<RatingStats?> watchRatingStats() => Stream.value(stats);
}

Review sampleReview({int rating = 5}) => Review(
  bookingId: 'b1',
  customerId: 'customer',
  providerId: 'pro',
  customerName: 'Dilshan Perera',
  serviceName: 'AC Deep Clean & Servicing',
  rating: rating,
  tags: const ['On Time', 'Clean Work'],
  comment: 'Arrived on time and left the place spotless.',
  recommend: true,
);

void main() {
  group('customer Rate & Review screen', () {
    testWidgets('submit is locked until a star rating is chosen', (
      tester,
    ) async {
      await pumpCustomer(
        tester,
        const ReviewScreen(bookingId: 'b1'),
        size: const Size(390, 1700),
        bookings: FakeBookingService(
          bookings: [booking(status: BookingStatus.completed)],
        ),
      );
      expect(find.text('How was your experience?'), findsOneWidget);
      expect(find.text('Tap a star to rate'), findsOneWidget);
      final submit = find.widgetWithText(FilledButton, 'Submit Review');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.tap(find.byTooltip('4 stars'));
      await tester.pump();
      expect(find.text('4.0 · Very Good'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    });

    testWidgets('submitting stores rating, highlights and recommendation, '
        'then shows the saved review', (tester) async {
      final service = FakeBookingService(
        bookings: [booking(status: BookingStatus.completed)],
      );
      await pumpCustomer(
        tester,
        const ReviewScreen(bookingId: 'b1'),
        size: const Size(390, 1700),
        bookings: service,
      );
      await tester.tap(find.byTooltip('5 stars'));
      await tester.pump();
      // Tapped out of design order on purpose.
      await tester.tap(find.text('Clean Work'));
      await tester.tap(find.text('On Time'));
      await tester.enterText(find.byType(TextField), '  Great job!  ');
      await tester.ensureVisible(find.text('Yes, definitely'));
      await tester.tap(find.text('Yes, definitely'));
      await tester.pump();
      await tester.ensureVisible(find.text('Submit Review'));
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      final saved = service.reviews['b1']!;
      expect(saved.rating, 5);
      expect(saved.tags, ['On Time', 'Clean Work']);
      expect(saved.comment, 'Great job!');
      expect(saved.recommend, isTrue);
      // The same route now shows the customer's own review, not the form.
      expect(find.text('You reviewed this job'), findsOneWidget);
      expect(find.text('Submit Review'), findsNothing);
      expect(find.text('"Great job!"'), findsOneWidget);
    });

    testWidgets('an already reviewed job opens straight to "Your review"', (
      tester,
    ) async {
      final service = FakeBookingService(
        bookings: [booking(status: BookingStatus.completed)],
      )..reviews['b1'] = sampleReview(rating: 4);
      await pumpCustomer(
        tester,
        const ReviewScreen(bookingId: 'b1'),
        size: const Size(390, 1700),
        bookings: service,
      );
      expect(find.text('Your Review'), findsOneWidget);
      expect(find.text('4.0 · Very Good'), findsOneWidget);
      expect(find.text('Submit Review'), findsNothing);
    });

    testWidgets('jobs that are not completed cannot be reviewed', (
      tester,
    ) async {
      await pumpCustomer(
        tester,
        const ReviewScreen(bookingId: 'b1'),
        size: const Size(390, 1700),
        bookings: FakeBookingService(bookings: [booking()]),
      );
      expect(find.text('Submit Review'), findsNothing);
      expect(find.textContaining('once it has been completed'), findsOneWidget);
    });

    testWidgets('booking details shows the review the customer gave', (
      tester,
    ) async {
      final service = FakeBookingService(
        bookings: [booking(status: BookingStatus.completed)],
      )..reviews['b1'] = sampleReview();
      await pumpCustomer(
        tester,
        const BookingDetailsScreen(bookingId: 'b1'),
        // Tall enough to build the whole page, including the price card.
        size: const Size(390, 3200),
        bookings: service,
      );
      await tester.scrollUntilVisible(
        find.text('YOUR REVIEW'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('YOUR REVIEW'), findsOneWidget);
      expect(
        find.text('"Arrived on time and left the place spotless."'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('View Your Review'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('View Your Review'), findsOneWidget);
    });
  });

  group('customer edits and deletes their review', () {
    FakeBookingService reviewed({int rating = 4}) =>
        FakeBookingService(bookings: [booking(status: BookingStatus.completed)])
          ..reviews['b1'] = sampleReview(rating: rating);

    Future<void> open(WidgetTester tester, FakeBookingService service) =>
        pumpCustomer(
          tester,
          const ReviewScreen(bookingId: 'b1'),
          size: const Size(390, 1700),
          bookings: service,
        );

    testWidgets('a saved review offers Edit and Delete', (tester) async {
      await open(tester, reviewed());
      expect(find.text('Edit Review'), findsOneWidget);
      expect(find.text('Delete Review'), findsOneWidget);
    });

    testWidgets('edit opens the form pre-filled and saves the changes', (
      tester,
    ) async {
      final service = reviewed(rating: 4);
      await open(tester, service);
      await tester.tap(find.text('Edit Review'));
      await tester.pumpAndSettle();
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('4.0 · Very Good'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Arrived on time and left the place spotless.',
      );

      await tester.tap(find.byTooltip('2 stars'));
      await tester.tap(find.text('Fair Price'));
      await tester.enterText(find.byType(TextField), 'Not as good as hoped');
      await tester.pump();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final saved = service.reviews['b1']!;
      expect(saved.rating, 2);
      expect(saved.tags, containsAll(['On Time', 'Clean Work', 'Fair Price']));
      expect(saved.comment, 'Not as good as hoped');
      expect(saved.updatedAt, isNotNull);
      // Back to the read-only view, now marked as edited.
      expect(find.text('You reviewed this job'), findsOneWidget);
      expect(find.text('2.0 · Fair'), findsOneWidget);
      expect(find.textContaining('Edited on'), findsOneWidget);
    });

    testWidgets('cancel leaves the review untouched', (tester) async {
      final service = reviewed(rating: 4);
      await open(tester, service);
      await tester.tap(find.text('Edit Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('1 star'));
      await tester.pump();
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.reviews['b1']!.rating, 4);
      expect(find.text('Edit Review'), findsOneWidget);
    });

    testWidgets('delete asks first, then removes the review', (tester) async {
      final service = reviewed();
      await open(tester, service);
      await tester.tap(find.text('Delete Review'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your review?'), findsOneWidget);

      // Keeping it changes nothing.
      await tester.tap(find.text('Cancel & Keep Review'));
      await tester.pumpAndSettle();
      expect(service.reviews['b1'], isNotNull);

      await tester.tap(find.text('Delete Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Delete Review'));
      await tester.pumpAndSettle();
      expect(service.reviews['b1'], isNull);
      // With the review gone the job can be reviewed again.
      expect(find.text('Submit Review'), findsOneWidget);
    });
  });

  group('provider side', () {
    Widget host(Widget child) => MaterialApp(
      theme: ProviderTheme.data,
      home: Scaffold(body: child),
    );

    AppNotification note({bool read = false}) => AppNotification(
      id: 'review_b1',
      recipientId: 'pro',
      type: AppNotification.reviewType,
      bookingId: 'b1',
      title: 'New review from Dilshan Perera',
      body: '5 stars for AC Deep Clean & Servicing',
      rating: 5,
      read: read,
      createdAt: DateTime(2025, 11, 10, 9),
    );

    testWidgets('notification list marks read and opens the reviewed job', (
      tester,
    ) async {
      final service = _Notifications([note()]);
      AppNotification? opened;
      await tester.pumpWidget(
        host(
          ProviderNotificationsScreen(
            service: service,
            onOpen: (item) => opened = item,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('New review from Dilshan Perera'), findsOneWidget);
      expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);

      await tester.tap(find.text('New review from Dilshan Perera'));
      await tester.pump();
      expect(service.read, ['review_b1']);
      expect(opened?.bookingId, 'b1');
    });

    testWidgets('already-read notifications are not marked again', (
      tester,
    ) async {
      final service = _Notifications([note(read: true)]);
      await tester.pumpWidget(
        host(ProviderNotificationsScreen(service: service, onOpen: (_) {})),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
      await tester.tap(find.text('New review from Dilshan Perera'));
      await tester.pump();
      expect(service.read, isEmpty);
    });

    testWidgets('empty notification list explains itself', (tester) async {
      await tester.pumpWidget(
        host(
          ProviderNotificationsScreen(
            service: _Notifications(const []),
            onOpen: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('completed job details lead with the customer review', (
      tester,
    ) async {
      const done = Booking(
        id: 'b1',
        customerId: 'customer',
        providerId: 'pro',
        serviceName: 'AC Deep Clean & Servicing',
        customerName: 'Dilshan Perera',
        address: 'No. 42 Galle Road',
        status: BookingStatus.completed,
        estimatedPrice: 5500,
      );
      await tester.pumpWidget(
        host(
          ProviderJobDetailsScreen(
            booking: done,
            service: _ProviderService(sampleReview()),
            onChanged: (_) {},
            onPayment: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('customer-review')), findsOneWidget);
      expect(find.text('Review from Dilshan Perera'), findsOneWidget);
      expect(find.text('5.0 · Excellent'), findsOneWidget);
      expect(find.text('Clean Work'), findsOneWidget);
      // Read-only for the provider: no way to edit or delete the review.
      expect(find.text('Edit Review'), findsNothing);
      expect(find.text('Delete Review'), findsNothing);
    });

    testWidgets('no review card until the customer has reviewed', (
      tester,
    ) async {
      const done = Booking(
        id: 'b1',
        customerId: 'customer',
        providerId: 'pro',
        serviceName: 'AC Deep Clean & Servicing',
        customerName: 'Dilshan Perera',
        address: 'No. 42 Galle Road',
        status: BookingStatus.completed,
        estimatedPrice: 5500,
      );
      await tester.pumpWidget(
        host(
          ProviderJobDetailsScreen(
            booking: done,
            service: _ProviderService(null),
            onChanged: (_) {},
            onPayment: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('customer-review')), findsNothing);
    });
  });

  group('overall provider rating', () {
    test('is the average of every review and moves with each new one', () {
      // Demo baseline: 10 reviews averaging 4.9.
      const baseline = RatingStats(sum: 49, count: 10);
      expect(baseline.label, '4.9');
      expect(baseline.plus(3).label, '4.7'); // a 3-star review pulls it down
      expect(baseline.plus(3).count, 11);
      expect(baseline.plus(5).label, '4.9');
      expect(const RatingStats(sum: 0, count: 0).average, isNull);
    });

    test('ignores malformed stats documents', () {
      expect(RatingStats.fromMap(null), isNull);
      expect(RatingStats.fromMap({'ratingSum': 5, 'ratingCount': 0}), isNull);
      expect(RatingStats.fromMap({'ratingSum': 1, 'ratingCount': 3}), isNull);
      expect(
        RatingStats.fromMap({'ratingSum': 54, 'ratingCount': 11})?.label,
        '4.9',
      );
    });

    Widget profile(ProviderProfileService service) => MaterialApp(
      theme: ProviderTheme.data,
      home: Scaffold(
        body: ProviderProfileScreen(
          user: const AppUser(
            uid: 'pro',
            name: 'Nuwan Fernando',
            email: 'nuwan@x.test',
            role: 'provider',
          ),
          authService: AuthService(auth: _Auth(), firestore: _Firestore()),
          service: service,
        ),
      ),
    );

    testWidgets('profile headlines the live average and review count', (
      tester,
    ) async {
      await tester.pumpWidget(
        profile(
          _ProfileService(
            stats: const RatingStats(sum: 52, count: 11),
            baseline: 4.9,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('Overall rating · 11 reviews'), findsOneWidget);
      expect(find.text('4.9'), findsNothing);
    });

    testWidgets('profile falls back to the stored rating before any review', (
      tester,
    ) async {
      await tester.pumpWidget(profile(_ProfileService(baseline: 4.9)));
      await tester.pumpAndSettle();
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Overall rating'), findsOneWidget);
    });

    testWidgets('profile says so when there is no rating at all', (
      tester,
    ) async {
      await tester.pumpWidget(profile(_ProfileService()));
      await tester.pumpAndSettle();
      expect(find.text('No ratings yet'), findsOneWidget);
    });

    testWidgets('customer sees the same overall rating on the provider card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ProfessionalCard(
              professional: professional.withStats(
                const RatingStats(sum: 52, count: 11),
              ),
            ),
          ),
        ),
      );
      expect(find.text('4.7'), findsOneWidget);
      expect(find.textContaining('11 reviews'), findsOneWidget);
    });
  });
}
