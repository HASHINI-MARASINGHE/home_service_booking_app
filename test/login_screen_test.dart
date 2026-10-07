import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:home_service_bookin_app/screens/auth/login_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/widgets/auth/auth_error_banner.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _AuthService extends AuthService {
  _AuthService() : super(auth: _Auth(), firestore: _Firestore());

  final logins = <({String email, String password})>[];
  Completer<void>? pending;
  Object? failure;

  @override
  Future<void> login({required String email, required String password}) async {
    logins.add((email: email, password: password));
    await pending?.future;
    if (failure != null) throw failure!;
  }
}

class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

final _email = find.byKey(const ValueKey('login-email'));
final _password = find.byKey(const ValueKey('login-password'));
final _submit = find.byKey(const ValueKey('login-submit'));

void main() {
  late _AuthService auth;
  late _Preferences prefs;

  setUp(() {
    auth = _AuthService();
    prefs = _Preferences();
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(402, 874),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(
          authService: auth,
          onRegister: () {},
          preferences: prefs,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(_submit);
    await tester.tap(_submit);
    await tester.pump();
  }

  TextField field(WidgetTester tester, Finder finder) =>
      tester.widget<TextField>(finder);

  testWidgets('renders the default layout at 360x640 without overflow', (
    tester,
  ) async {
    await pump(tester, size: const Size(360, 640));
    expect(find.text('HomeCare'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Log in to book and manage your home services'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Admin sign in'), findsOneWidget);
    expect(find.text('Your details are protected'), findsOneWidget);
    expect(field(tester, _email).keyboardType, TextInputType.emailAddress);
    expect(field(tester, _email).textInputAction, TextInputAction.next);
    expect(field(tester, _password).textInputAction, TextInputAction.done);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid email shows the field error and does not sign in', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(_email, 'nuwan.invalid-email');
    await tester.enterText(_password, 'secret123');
    await tapSubmit(tester);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(auth.logins, isEmpty);

    // Fixing the address clears the error.
    await tester.enterText(_email, 'nuwan.perera@gmail.com');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsNothing);
  });

  testWidgets('invalid email is flagged when the field loses focus', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(_email, 'not-an-email');
    await tester.tap(_password);
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('eye button toggles password visibility', (tester) async {
    await pump(tester);
    expect(field(tester, _password).obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('login-password-toggle')));
    await tester.pump();
    expect(field(tester, _password).obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('loading state disables the form and blocks double submit', (
    tester,
  ) async {
    auth.pending = Completer<void>();
    await pump(tester);
    await tester.enterText(_email, '  nuwan.perera@gmail.com ');
    await tester.enterText(_password, 'secret123');
    await tapSubmit(tester);

    expect(find.text('Logging in…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(field(tester, _email).enabled, isFalse);
    expect(field(tester, _password).enabled, isFalse);
    await tester.tap(_submit);
    await tester.pump();
    expect(auth.logins, hasLength(1));
    expect(auth.logins.single.email, 'nuwan.perera@gmail.com');

    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('wrong credentials show the inline banner; editing clears it', (
    tester,
  ) async {
    auth.failure = FirebaseAuthException(code: 'invalid-credential');
    await pump(tester);
    await tester.enterText(_email, 'nuwan.perera@gmail.com');
    await tester.enterText(_password, 'wrong-password');
    await tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(
      find.text('Incorrect email or password. Please try again.'),
      findsOneWidget,
    );

    await tester.enterText(_password, 'another');
    await tester.pump();
    expect(find.byType(AuthErrorBanner), findsNothing);
  });

  testWidgets('network failure shows the connection message', (tester) async {
    auth.failure = FirebaseAuthException(code: 'network-request-failed');
    await pump(tester);
    await tester.enterText(_email, 'nuwan.perera@gmail.com');
    await tester.enterText(_password, 'secret123');
    await tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Check your connection and try again.'), findsOneWidget);
  });

  testWidgets('remember me stores only the email and prefills it', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(_email, 'nuwan.perera@gmail.com');
    await tester.enterText(_password, 'secret123');
    await tester.tap(find.byKey(const ValueKey('login-remember')));
    await tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(prefs.values, {
      LoginScreen.rememberedEmailKey: 'nuwan.perera@gmail.com',
    });

    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester);
    expect(field(tester, _email).controller!.text, 'nuwan.perera@gmail.com');
    expect(field(tester, _password).controller!.text, isEmpty);

    await tester.tap(find.byKey(const ValueKey('login-remember')));
    await tester.pumpAndSettle();
    expect(prefs.values, isEmpty);
  });

  testWidgets('keyboard open collapses the hero without overflow', (
    tester,
  ) async {
    await pump(tester, size: const Size(360, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.tap(_password);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('HomeCare'), findsOneWidget);
    expect(find.text('Admin sign in'), findsNothing);
    expect(tester.getRect(_password).bottom, lessThanOrEqualTo(640 - 280));
  });
}
