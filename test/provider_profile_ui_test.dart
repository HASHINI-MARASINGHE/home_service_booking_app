import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/provider_profile.dart';
import 'package:home_service_bookin_app/models/provider_verification.dart';
import 'package:home_service_bookin_app/models/rating_stats.dart';
import 'package:home_service_bookin_app/screens/provider/provider_profile_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/services/provider_profile_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

class _Profiles extends ProviderProfileService {
  _Profiles(this.profile) : super(auth: _Auth(), firestore: _Db());
  final ProviderProfile profile;

  @override
  Stream<ProviderProfile> watchProfile() => Stream.value(profile);

  @override
  Stream<RatingStats?> watchRatingStats() =>
      Stream.value(const RatingStats(sum: 7, count: 2));
}

const _full = ProviderProfile(
  providerId: 'pro',
  phone: '0721515123',
  profession: 'Plumber',
  experience: 2,
  about: 'Pipes, taps and drains.',
  services: ['Plumbing', 'Leak repair'],
  pricing: 2500,
  availability: true,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    ProviderProfile profile, {
    VerificationStatus? status = VerificationStatus.verified,
    String? code = 'HCP-1005',
    Size size = const Size(390, 2600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProviderProfileScreen(
            user: const AppUser(
              uid: 'pro',
              name: 'Yash',
              email: 'yash@homecare.test',
              role: 'provider',
            ),
            authService: AuthService(auth: _Auth(), firestore: _Db()),
            service: _Profiles(profile),
            verificationStatus: status,
            verification: code == null
                ? null
                : ProviderVerification(
                    uid: 'pro',
                    status: VerificationStatus.verified,
                    fullName: 'Yash',
                    phone: '0721515123',
                    profession: 'Plumber',
                    experienceYears: 2,
                    providerCode: code,
                  ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows who the provider is, the verification and the rating', (
    tester,
  ) async {
    await pump(tester, _full);
    expect(find.text('Yash'), findsOneWidget);
    expect(find.text('yash@homecare.test'), findsOneWidget);
    expect(find.text('Verified provider'), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-id')), findsOneWidget);
    expect(find.text('HCP-1005'), findsOneWidget);
    expect(find.text('3.5'), findsOneWidget);
    expect(find.text('Overall rating · 2 reviews'), findsOneWidget);
  });

  testWidgets('lists the service credentials as rows', (tester) async {
    await pump(tester, _full);
    expect(find.text('SERVICE CREDENTIALS'), findsOneWidget);
    expect(find.text('0721515123'), findsOneWidget);
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.text('2 years'), findsOneWidget);
    expect(find.text('Pipes, taps and drains.'), findsOneWidget);
    expect(find.text('Plumbing, Leak repair'), findsOneWidget);
    expect(find.text('LKR 2,500'), findsOneWidget);
    expect(find.text('Available for new jobs'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-profile-phone')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-add')), findsNothing);
  });

  testWidgets('empty rows say so and offer to add them', (tester) async {
    await pump(
      tester,
      const ProviderProfile(
        providerId: 'pro',
        profession: 'Plumber',
        availability: false,
      ),
    );
    expect(
      find.text('Not added yet'),
      findsNWidgets(3),
    ); // phone, about, services
    expect(find.byKey(const ValueKey('profile-add')), findsNWidgets(2));
    expect(find.text('Not currently available'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-profile-phone')), findsNothing);
  });

  testWidgets('Add opens the profile editor', (tester) async {
    await pump(
      tester,
      const ProviderProfile(providerId: 'pro', profession: 'Plumber'),
    );
    await tester.tap(find.byKey(const ValueKey('profile-add')).first);
    await tester.pumpAndSettle();
    expect(find.text('Save profile'), findsOneWidget);
    expect(find.text('SERVICE CREDENTIALS'), findsNothing);
  });

  testWidgets('Edit Profile opens the editor too', (tester) async {
    await pump(tester, _full);
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Save profile'), findsOneWidget);
  });

  testWidgets('a provider waiting for verification sees that, with no ID', (
    tester,
  ) async {
    await pump(tester, _full, status: VerificationStatus.pending, code: null);
    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-id')), findsNothing);
  });

  testWidgets('has Edit Profile and Log out', (tester) async {
    await pump(tester, _full);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('fits a narrow phone', (tester) async {
    await pump(tester, _full, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
