import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/screens/auth/auth_wrapper.dart';
import 'package:home_service_bookin_app/screens/auth/login_screen.dart';
import 'package:home_service_bookin_app/screens/auth/provider_registration_screen.dart';
import 'package:home_service_bookin_app/screens/auth/register_screen.dart';
import 'package:home_service_bookin_app/screens/auth/role_selection_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _SignedOutAuthService extends AuthService {
  _SignedOutAuthService() : super(auth: _Auth(), firestore: _Firestore());

  @override
  Stream<User?> authStateChanges() => Stream.value(null);
}

final _customer = find.byKey(const ValueKey('role-customer'));
final _provider = find.byKey(const ValueKey('role-provider'));
final _continue = find.byKey(const ValueKey('role-continue'));

bool _isChecked(WidgetTester tester, Finder card) => find
    .descendant(of: card, matching: find.byIcon(LucideIcons.circleCheck))
    .evaluate()
    .isNotEmpty;

void _phone(WidgetTester tester, [Size size = const Size(402, 874)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('RoleSelectionScreen', () {
    late List<String> continued;
    late int logins;

    Future<void> pump(WidgetTester tester) async {
      continued = [];
      logins = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RoleSelectionScreen(
            onContinue: continued.add,
            onLogin: () => logins++,
          ),
        ),
      );
    }

    testWidgets('fits 360x640 with the customer role selected by default', (
      tester,
    ) async {
      _phone(tester, const Size(360, 640));
      await pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Your Home, Our Care'), findsOneWidget);
      expect(find.text('How will you use HomeCare?'), findsOneWidget);
      expect(_isChecked(tester, _customer), isTrue);
      expect(_isChecked(tester, _provider), isFalse);
      await tester.ensureVisible(_customer);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_customer),
        matchesSemantics(
          label: 'I need a service',
          hint:
              'Find, book and track trusted home professionals. '
              'Verified, rated professionals. See the price before you book. '
              'Track every job in real time.',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );

      expect(find.text('Verified, rated professionals'), findsOneWidget);
      expect(find.text('Get job requests near you'), findsNothing);
      expect(find.text('Verified pros'), findsOneWidget);
      expect(find.text('Continue as Customer'), findsOneWidget);

      await tester.tap(_continue);
      expect(continued, [AppUser.customerRole]);
    });

    testWidgets('selecting provider shows its benefits and button label', (
      tester,
    ) async {
      _phone(tester);
      await pump(tester);
      await tester.ensureVisible(_provider);
      await tester.tap(_provider);
      await tester.pumpAndSettle();
      expect(_isChecked(tester, _provider), isTrue);
      expect(_isChecked(tester, _customer), isFalse);
      expect(find.text('Get job requests near you'), findsOneWidget);
      expect(find.text('Manage bookings and your schedule'), findsOneWidget);
      expect(find.text('Secure payments after each job'), findsOneWidget);
      expect(find.text('Verified, rated professionals'), findsNothing);
      expect(find.text('Continue as Provider'), findsOneWidget);
      expect(find.text('Continue as Customer'), findsNothing);

      await tester.tap(_continue);
      expect(continued, [AppUser.providerRole]);
    });

    testWidgets('Log in and the back arrow call back to login', (tester) async {
      _phone(tester);
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('role-login')));
      expect(logins, 1);
      await tester.tap(find.byKey(const ValueKey('hero-back')));
      expect(logins, 2);
    });
  });

  group('sign-up flow', () {
    Future<void> openRoles(WidgetTester tester) async {
      _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AuthWrapper(authService: _SignedOutAuthService()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create an account'));
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
    }

    testWidgets('customer continues to the register form with role preset', (
      tester,
    ) async {
      await openRoles(tester);
      await tester.tap(_continue);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Signing up as Customer'), findsOneWidget);
      expect(find.byKey(const ValueKey('role-dropdown')), findsNothing);
      expect(find.text('Name'), findsOneWidget);

      // "Change" goes back to role selection, keeping the choice.
      await tester.tap(find.byKey(const ValueKey('change-role')));
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(_isChecked(tester, _customer), isTrue);
    });

    testWidgets('provider continues to the provider registration flow', (
      tester,
    ) async {
      await openRoles(tester);
      await tester.ensureVisible(_provider);
      await tester.tap(_provider);
      await tester.pumpAndSettle();
      await tester.tap(_continue);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderRegistrationScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });

    testWidgets('Log in and system back both return to login', (tester) async {
      await openRoles(tester);
      await tester.tap(find.byKey(const ValueKey('role-login')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);

      await tester.ensureVisible(find.text('Create an account'));
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
    });
  });
}
