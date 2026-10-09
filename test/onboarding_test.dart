import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:home_service_bookin_app/l10n/locale_controller.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/screens/auth/auth_wrapper.dart';
import 'package:home_service_bookin_app/screens/auth/login_screen.dart';
import 'package:home_service_bookin_app/screens/auth/register_screen.dart';
import 'package:home_service_bookin_app/screens/customer/customer_home_screen.dart';
import 'package:home_service_bookin_app/screens/onboarding/onboarding_gate.dart';
import 'package:home_service_bookin_app/screens/onboarding/language_selection_screen.dart';
import 'package:home_service_bookin_app/screens/onboarding/onboarding_preferences.dart';
import 'package:home_service_bookin_app/screens/onboarding/onboarding_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';

// Mutable test controls simulate platform read/write failures.
// ignore: must_be_immutable
class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? pendingWrite;
  int writes = 0;

  @override
  Future<bool?> getBool(String key) async {
    if (failRead) throw StateError('Read failed');
    return values[key] as bool?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    writes++;
    if (failWrite) throw StateError('Write failed');
    await pendingWrite?.future;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class _Auth extends Fake implements FirebaseAuth {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _User extends Fake implements User {
  @override
  String get uid => 'customer-id';
}

class _AuthService extends AuthService {
  _AuthService({this.profile}) : super(auth: _Auth(), firestore: _Firestore());
  final AppUser? profile;
  @override
  Stream<User?> authStateChanges() =>
      Stream.value(profile == null ? null : _User());
  @override
  Future<AppUser?> getUserProfile(String uid) async => profile;
}

Widget app(Widget child, {double textScale = 1}) => MaterialApp(
  builder: (context, widget) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      padding: const EdgeInsets.only(top: 24, bottom: 24),
    ),
    child: widget!,
  ),
  home: child,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocaleController.instance.setLocale(const Locale('en'));
  });

  test('completion persists across preference wrapper instances; reset removes only its flag', () async {
    final storage = _Preferences()..values['unrelated_setting'] = 'keep';
    final first = OnboardingPreferences(preferences: storage);
    expect(await first.isCompleted(), isFalse);
    await first.complete();
    final restarted = OnboardingPreferences(preferences: storage);
    expect(await restarted.isCompleted(), isTrue);
    expect(
      storage.values.keys,
      unorderedEquals([
        'unrelated_setting',
        OnboardingPreferences.completedKey,
      ]),
    );
    await restarted.reset();
    expect(await first.isCompleted(), isFalse);
    expect(storage.values['unrelated_setting'], 'keep');
  });

  testWidgets(
    'Next advances all pages, updates dots, and Get Started completes',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        app(
          OnboardingScreen(
            onComplete: () async {
              completed++;
            },
          ),
        ),
      );
      expect(find.text('Help for your home,\nmade simple.'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('onboarding-indicator-0')),
            )
            .constraints!
            .maxWidth,
        26,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text('Connecting you with\nthe right people.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('onboarding-indicator-1')),
            )
            .constraints!
            .maxWidth,
        26,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('For Customers'), findsOneWidget);
      expect(find.text('For Providers'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('onboarding-indicator-2')),
            )
            .constraints!
            .maxWidth,
        26,
      );
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(completed, 1);
    },
  );

  testWidgets('horizontal swipe updates indicator in both directions', (
    tester,
  ) async {
    await tester.pumpWidget(app(OnboardingScreen(onComplete: () async {})));
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('onboarding-indicator-1')),
          )
          .constraints!
          .maxWidth,
      26,
    );
    await tester.drag(find.byType(PageView), const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('onboarding-indicator-0')),
          )
          .constraints!
          .maxWidth,
      26,
    );
  });

  testWidgets(
    'Language selection allows choosing English and Sinhala, then proceeds',
    (tester) async {
      final storage = _Preferences();
      await tester.pumpWidget(
        app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: storage),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose your language'), findsOneWidget);
      expect(
        find.text('Select your preferred language to continue'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('language-option-en')), findsOneWidget);
      expect(find.byKey(const ValueKey('language-option-si')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('language-option-si')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('language-continue-button')));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Language selection allows choosing Tamil and proceeds with Tamil onboarding',
    (tester) async {
      final storage = _Preferences();
      await tester.pumpWidget(
        app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: storage),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('language-option-ta')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('language-option-ta')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('language-continue-button')));
      await tester.pumpAndSettle();
      expect(LocaleController.instance.locale.languageCode, 'ta');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('தவிர்'), findsOneWidget);
    },
  );

  for (final page in [0, 1]) {
    testWidgets(
      'Skip on page ${page + 1} opens unchanged Login/Register and persists',
      (tester) async {
        final storage = _Preferences();
        final auth = _AuthService();
        Widget gate() => app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: storage),
            authBuilder: (_) => AuthWrapper(authService: auth),
          ),
        );
        await tester.pumpWidget(gate());
        await tester.pumpAndSettle();
        if (find.text('Choose your language').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }
        if (page == 1) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(storage.values[OnboardingPreferences.completedKey], isTrue);
        await tester.ensureVisible(find.text('Create an account'));
        await tester.tap(find.text('Create an account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue as Customer'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterScreen), findsOneWidget);
        await tester.tap(find.text('Already have an account? Log in'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(gate());
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
      },
    );
  }

  testWidgets('Get Started saves completion before entering auth', (
    tester,
  ) async {
    final storage = _Preferences();
    await tester.pumpWidget(
      app(
        OnboardingGate(
          preferences: OnboardingPreferences(preferences: storage),
          authBuilder: (_) => AuthWrapper(authService: _AuthService()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (find.text('Choose your language').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    for (var index = 0; index < 2; index++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(storage.values[OnboardingPreferences.completedKey], isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'completed onboarding preserves existing authenticated customer routing',
    (tester) async {
      final storage = _Preferences()
        ..values[OnboardingPreferences.completedKey] = true;
      final auth = _AuthService(
        profile: const AppUser(
          uid: 'customer-id',
          name: 'Customer',
          email: 'customer@example.com',
          role: AppUser.customerRole,
        ),
      );
      await tester.pumpWidget(
        app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: storage),
            authBuilder: (_) => AuthWrapper(authService: auth),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomerHomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  group('onboarding only for signed-out users', () {
    const home = Text('home screen', textDirection: TextDirection.ltr);

    testWidgets('a signed-in user goes straight to the app, every launch', (
      tester,
    ) async {
      // Onboarding was never completed on this device, yet it is skipped.
      await tester.pumpWidget(
        app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: _Preferences()),
            signedIn: () async => true,
            authBuilder: (_) => home,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home screen'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LanguageSelectionScreen), findsNothing);
    });

    testWidgets('a signed-out user sees onboarding when the app opens', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: _Preferences()),
            signedIn: () async => false,
            authBuilder: (_) => home,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home screen'), findsNothing);
      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    });

    testWidgets('with no way to read the session it counts as signed out', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          OnboardingGate(
            preferences: OnboardingPreferences(preferences: _Preferences()),
            signedIn: () async => throw StateError('no Firebase'),
            authBuilder: (_) => home,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home screen'), findsNothing);
      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    });
  });

  testWidgets('failed preference read shows Retry and can recover', (
    tester,
  ) async {
    final storage = _Preferences()..failRead = true;
    await tester.pumpWidget(
      app(
        OnboardingGate(
          preferences: OnboardingPreferences(preferences: storage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    storage.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('failed save keeps onboarding and allows retry', (tester) async {
    final storage = _Preferences()..failWrite = true;
    await tester.pumpWidget(
      app(
        OnboardingGate(
          preferences: OnboardingPreferences(preferences: storage),
          authBuilder: (_) => const Scaffold(body: Text('Auth destination')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (find.text('Choose your language').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      find.text('Unable to save your progress. Please try again.'),
      findsOneWidget,
    );
    expect(
      storage.values.containsKey(OnboardingPreferences.completedKey),
      isFalse,
    );
    storage.failWrite = false;
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Auth destination'), findsOneWidget);
  });

  testWidgets('completion waits for storage and ignores duplicate taps', (
    tester,
  ) async {
    final pending = Completer<void>();
    final storage = _Preferences()..pendingWrite = pending;
    await tester.pumpWidget(
      app(
        OnboardingGate(
          preferences: OnboardingPreferences(preferences: storage),
          authBuilder: (_) => const Scaffold(body: Text('Auth destination')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (find.text('Choose your language').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(storage.writes, 1);
    expect(find.text('Auth destination'), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Auth destination'), findsOneWidget);
  });

  for (final scenario in [
    (const Size(411, 914), 1.0, 'Pixel 7'),
    (const Size(320, 568), 1.0, 'small phone'),
    (const Size(411, 914), 2.0, 'large text'),
    (const Size(740, 360), 1.0, 'landscape'),
  ]) {
    testWidgets(
      'all pages fit ${scenario.$3} with safe visible bottom control',
      (tester) async {
        tester.view.physicalSize = scenario.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(
            OnboardingScreen(onComplete: () async {}),
            textScale: scenario.$2,
          ),
        );
        await tester.pumpAndSettle();
        for (var page = 0; page < 3; page++) {
          expect(tester.takeException(), isNull);
          final rect = tester.getRect(
            find.byKey(const ValueKey('onboarding-next')),
          );
          expect(rect.bottom, lessThanOrEqualTo(scenario.$1.height - 24));
          expect(rect.top, greaterThanOrEqualTo(24));
          if (page < 2) {
            await tester.tap(find.text('Next'));
            await tester.pumpAndSettle();
          }
        }
        expect(find.text('For Customers'), findsOneWidget);
        expect(find.text('For Providers'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
