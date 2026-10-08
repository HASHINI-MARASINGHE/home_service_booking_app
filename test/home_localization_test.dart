import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_service_bookin_app/l10n/app_localizations.dart';
import 'package:home_service_bookin_app/l10n/locale_controller.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/booking.dart';
import 'package:home_service_bookin_app/screens/customer/customer_home_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_dashboard_screen.dart';
import 'package:home_service_bookin_app/screens/provider/provider_theme.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/theme/locale_typography.dart';
import 'package:home_service_bookin_app/widgets/common/language_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

const _provider = AppUser(
  uid: 'provider',
  name: 'Test Provider',
  email: 'provider@example.com',
  role: 'provider',
);

const _en = ui.Locale('en');
const _si = ui.Locale('si');

/// A MaterialApp wired like the real one: delegates, locale and text scale.
Widget _app(Widget home, {ui.Locale locale = _en, double textScale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );

Widget _customerHome() => CustomerHomeScreen(
  user: testUser,
  authService: AuthService(auth: _Auth(), firestore: _Db()),
  addressService: FakeAddressService(),
  bookingService: FakeBookingService(),
);

Widget _dashboard({List<Booking> bookings = const []}) => Theme(
  data: ProviderTheme.data,
  child: Scaffold(
    body: ProviderDashboardScreen(
      user: _provider,
      bookings: bookings,
      onOpen: (_) {},
      onViewJobs: () {},
    ),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // No font downloads in tests; the layout rules are still checked.
    LocaleTypography.enabled = false;
  });

  tearDown(() async {
    LocaleTypography.enabled = true;
    await LocaleController.instance.setLocale(_en);
  });

  group('LocaleController', () {
    test('saves the chosen language and loads it again', () async {
      final controller = LocaleController.instance;
      await controller.setLocale(_si);
      expect(controller.locale, _si);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'si');

      await controller.setLocale(_en);
      await controller.load();
      expect(controller.locale, _en);

      SharedPreferences.setMockInitialValues({'app_language': 'si'});
      await controller.load();
      expect(controller.locale, _si);
    });

    test(
      'notifies listeners at once and ignores unsupported languages',
      () async {
        final controller = LocaleController.instance;
        var calls = 0;
        void listener() => calls++;
        controller.addListener(listener);
        addTearDown(() => controller.removeListener(listener));

        await controller.setLocale(_si);
        expect(calls, 1);
        await controller.setLocale(const ui.Locale('fr'));
        expect(controller.locale, _si);
        expect(calls, 1);
      },
    );
  });

  group('LocaleTypography', () {
    // The real fonts cannot be downloaded in a test, so fetching is turned
    // off; the "font not bundled" error that follows is expected and cleared.
    Future<ThemeData> themeFor(WidgetTester tester, ui.Locale locale) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      LocaleTypography.enabled = true;
      late ThemeData result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              result = LocaleTypography.apply(context, ProviderTheme.data);
              return const SizedBox();
            },
          ),
          locale: locale,
        ),
      );
      await tester.pump();
      tester.takeException();
      return result;
    }

    testWidgets(
      'English uses Atkinson Hyperlegible, Sinhala Noto Sans Sinhala',
      (tester) async {
        final en = (await themeFor(tester, _en)).textTheme.bodyMedium!;
        final si = (await themeFor(tester, _si)).textTheme.bodyMedium!;
        expect(en.fontFamily, contains('AtkinsonHyperlegible'));
        expect(en.fontFamilyFallback!.single, contains('NotoSansSinhala'));
        expect(si.fontFamily, contains('NotoSansSinhala'));
        expect(si.fontFamilyFallback!.single, contains('AtkinsonHyperlegible'));
      },
    );

    testWidgets(
      'no letter spacing, nothing under 14 px, taller Sinhala lines',
      (tester) async {
        final en = await themeFor(tester, _en);
        final si = await themeFor(tester, _si);
        for (final theme in [en, si]) {
          final styles = [
            theme.textTheme.headlineSmall,
            theme.textTheme.titleLarge,
            theme.textTheme.titleMedium,
            theme.textTheme.bodyMedium,
            theme.textTheme.bodySmall,
            theme.appBarTheme.titleTextStyle,
          ];
          for (final style in styles) {
            expect(style!.letterSpacing, 0);
            expect(style.fontSize, greaterThanOrEqualTo(14));
          }
        }
        // Style guide: body 18/28 in English and 18/32 in Sinhala, section
        // titles 24/32 and 24/40.
        expect(si.textTheme.bodyMedium!.height, closeTo(32 / 18, 0.001));
        expect(si.textTheme.titleLarge!.height, closeTo(40 / 24, 0.001));
        expect(en.textTheme.bodyMedium!.height, closeTo(28 / 18, 0.001));
        expect(en.textTheme.titleLarge!.height, closeTo(32 / 24, 0.001));
      },
    );
  });

  group('LanguageSwitch', () {
    testWidgets('shows both names in their own script with a check', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Scaffold(body: LanguageSwitch())));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('සිංහල'), findsOneWidget);
      // The selected language has a check as well as a color.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('language-English'))),
        isSemantics(label: 'English', isSelected: true, isButton: true),
      );
    });

    testWidgets('tap areas are at least 48 px', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: LanguageSwitch())));
      for (final name in ['English', 'සිංහල']) {
        final size = tester.getSize(find.byKey(ValueKey('language-$name')));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('tapping සිංහල moves the check and changes the language', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Scaffold(body: LanguageSwitch())));
      await tester.tap(find.text('සිංහල'));
      await tester.pump();
      expect(LocaleController.instance.locale, _si);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('language-සිංහල')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });
  });

  group('Customer Home', () {
    testWidgets('English text and the switch are shown', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(_customerHome()));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSwitch), findsOneWidget);
      expect(find.text('Hello, Dilshan 👋'), findsOneWidget);
      expect(find.text('Verified providers'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
    });

    testWidgets('Sinhala replaces the home text without a restart', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(_customerHome(), locale: _si));
      await tester.pumpAndSettle();
      expect(find.text('තහවුරු කළ සේවා සපයන්නන්'), findsOneWidget);
      expect(find.text('සියල්ල බලන්න'), findsOneWidget);
      expect(find.text('Verified providers'), findsNothing);
      expect(find.text('ජල නළ වැඩ'), findsOneWidget);
      // What users type or what comes from data is never translated.
      expect(find.text('Nuwan Fernando'), findsOneWidget);
      expect(find.text('මුල් පිටුව'), findsOneWidget); // bottom tab
    });

    for (final locale in [_en, _si]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'fits a 320 x 640 phone in ${locale.languageCode} at ${scale * 100}% text',
          (tester) async {
            tester.view.physicalSize = const Size(320, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _app(_customerHome(), locale: locale, textScale: scale),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('Provider Home', () {
    final pending = Booking(
      id: 'p1',
      customerId: 'customer',
      providerId: 'provider',
      serviceName: 'AC repair',
      customerName: 'Customer',
      address: 'Galle Road',
      status: BookingStatus.pending,
    );

    testWidgets('English text and the switch are shown', (tester) async {
      await tester.pumpWidget(_app(_dashboard(bookings: [pending])));
      expect(find.byType(LanguageSwitch), findsOneWidget);
      expect(find.text('Hello, Test Provider'), findsOneWidget);
      expect(find.text('New request'), findsOneWidget); // status badge
      expect(find.text('View request'), findsOneWidget);
    });

    testWidgets('Sinhala replaces the dashboard text', (tester) async {
      await tester.pumpWidget(
        _app(_dashboard(bookings: [pending]), locale: _si),
      );
      expect(find.text('ආයුබෝවන්, Test Provider'), findsOneWidget);
      expect(find.text('ඔබේ වැඩ, එකම තැනකින්.'), findsOneWidget);
      expect(find.text('ඉල්ලීම බලන්න'), findsOneWidget);
      expect(find.text('නව ඉල්ලීම'), findsWidgets);
      // Names and addresses stay exactly as stored.
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Galle Road'), findsOneWidget);
    });

    for (final locale in [_en, _si]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'fits a 320 x 640 phone in ${locale.languageCode} at ${scale * 100}% text',
          (tester) async {
            tester.view.physicalSize = const Size(320, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _app(
                _dashboard(bookings: [pending]),
                locale: locale,
                textScale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
