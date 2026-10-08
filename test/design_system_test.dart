import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/professional.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/theme/text_size_controller.dart';
import 'package:home_service_bookin_app/widgets/common/app_buttons.dart';
import 'package:home_service_bookin_app/widgets/common/app_text_field.dart';
import 'package:home_service_bookin_app/widgets/common/empty_state.dart';
import 'package:home_service_bookin_app/widgets/common/motion_widgets.dart';
import 'package:home_service_bookin_app/widgets/common/provider_card.dart';
import 'package:home_service_bookin_app/widgets/common/rating_badge.dart';
import 'package:home_service_bookin_app/widgets/common/service_tile.dart';
import 'package:home_service_bookin_app/widgets/common/status_chip.dart';
import 'package:home_service_bookin_app/widgets/common/text_size_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two colors.
double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('colors', () {
    test('use exactly the style guide values', () {
      expect(AppColors.brand900, const Color(0xFF0B2A5B));
      expect(AppColors.brand700, const Color(0xFF134A96));
      expect(AppColors.accent500, const Color(0xFFF2A900));
      expect(AppColors.bg, const Color(0xFFF7F5F2));
      expect(AppColors.ink, const Color(0xFF101B2B));
      expect(AppColors.successSolid, const Color(0xFF005F52));
      expect(AppColors.errorSolid, const Color(0xFFA02019));
    });

    test('the older names no longer point at the old teal', () {
      expect(AppColors.primary, AppColors.brand700);
      expect(AppColors.background, AppColors.bg);
      expect(AppColors.muted, AppColors.ink3);
      expect(AuthColors.primary, AppColors.brand700);
    });

    test('every text color is 7 to 1 or better (AAA)', () {
      final pairs = <String, (Color, Color)>{
        'ink on white': (AppColors.ink, AppColors.surface),
        'ink on bg': (AppColors.ink, AppColors.bg),
        'ink2 on white': (AppColors.ink2, AppColors.surface),
        'ink2 on bg': (AppColors.ink2, AppColors.bg),
        'ink3 on white': (AppColors.ink3, AppColors.surface),
        'ink3 on bg': (AppColors.ink3, AppColors.bg),
        'ink3 on grey rows': (AppColors.ink3, AppColors.surfaceAlt),
        'white on blue button': (AppColors.surface, AppColors.brand700),
        'white on pressed blue': (AppColors.surface, AppColors.brand900),
        'blue link on white': (AppColors.brand700, AppColors.surface),
        'blue on soft blue': (AppColors.brand700, AppColors.brand50),
        'dark blue on selected': (AppColors.brand900, AppColors.brand100),
        'white on success': (AppColors.surface, AppColors.successSolid),
        'success text': (AppColors.successText, AppColors.successSoft),
        'ink on warning solid': (AppColors.ink, AppColors.warningSolid),
        'warning text': (AppColors.warningText, AppColors.warningSoft),
        'white on error': (AppColors.surface, AppColors.errorSolid),
        'error text': (AppColors.errorText, AppColors.errorSoft),
        'info text': (AppColors.infoText, AppColors.infoSoft),
        'neutral text': (AppColors.neutralText, AppColors.neutralSoft),
        'star outline on white': (AppColors.accent700, AppColors.surface),
      };
      pairs.forEach((name, pair) {
        expect(
          _contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(7),
          reason: name,
        );
      });
    });

    test('control borders are easy to see (3 to 1 or better)', () {
      expect(
        _contrast(AppColors.borderControl, AppColors.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(AppColors.borderControl, AppColors.bg),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('typography', () {
    test('English sizes and lines follow the guide', () {
      final t = AppTextStyles.forLocale(const Locale('en'));
      double line(TextStyle s) => s.fontSize! * s.height!;
      expect((t.display.fontSize, line(t.display).round()), (34, 42));
      expect((t.h1.fontSize, line(t.h1).round()), (28, 36));
      expect((t.h2.fontSize, line(t.h2).round()), (24, 32));
      expect((t.h3.fontSize, line(t.h3).round()), (20, 28));
      expect((t.bodyLarge.fontSize, line(t.bodyLarge).round()), (18, 28));
      expect((t.bodySmall.fontSize, line(t.bodySmall).round()), (16, 24));
      expect((t.caption.fontSize, line(t.caption).round()), (14, 20));
      expect((t.button.fontSize, line(t.button).round()), (18, 24));
      expect((t.label.fontSize, line(t.label).round()), (16, 22));
      expect((t.amount.fontSize, line(t.amount).round()), (22, 28));
    });

    test('Sinhala has taller lines and a 15 px caption', () {
      final t = AppTextStyles.forLocale(const Locale('si'));
      double line(TextStyle s) => s.fontSize! * s.height!;
      expect(line(t.display).round(), 54);
      expect(line(t.h1).round(), 46);
      expect(line(t.h2).round(), 40);
      expect(line(t.h3).round(), 34);
      expect(line(t.bodyLarge).round(), 32);
      expect(line(t.bodySmall).round(), 28);
      expect((t.caption.fontSize, line(t.caption).round()), (15, 26));
    });

    test('only Regular and Bold, no letter spacing, nothing under 14 px', () {
      for (final locale in const [Locale('en'), Locale('si')]) {
        final t = AppTextStyles.forLocale(locale);
        for (final s in [
          t.display,
          t.h1,
          t.h2,
          t.h3,
          t.bodyLarge,
          t.bodySmall,
          t.caption,
          t.button,
          t.label,
          t.amount,
        ]) {
          expect(s.fontWeight, anyOf(FontWeight.w400, FontWeight.w700));
          expect(s.letterSpacing, 0);
          expect(s.fontSize, greaterThanOrEqualTo(14));
        }
      }
    });
  });

  group('theme', () {
    final theme = AppTheme.light;

    test('screen, buttons and navigation follow the guide', () {
      expect(theme.scaffoldBackgroundColor, AppColors.bg);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.brand700);
      final filled = theme.filledButtonTheme.style!;
      expect(filled.minimumSize!.resolve({})!.height, 56);
      expect(filled.backgroundColor!.resolve({}), AppColors.brand700);
      expect(
        filled.backgroundColor!.resolve({WidgetState.pressed}),
        AppColors.brand900,
      );
      expect(filled.foregroundColor!.resolve({}), AppColors.surface);
      expect(
        filled.side!.resolve({WidgetState.focused})!.width,
        greaterThanOrEqualTo(3),
      );
      expect(
        theme.navigationBarTheme.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
      expect(theme.navigationBarTheme.height, 72);
    });

    test('inputs have a 2 px grey border and a thick blue focus border', () {
      final input = theme.inputDecorationTheme;
      final normal = input.enabledBorder as OutlineInputBorder;
      final focused = input.focusedBorder as OutlineInputBorder;
      expect(normal.borderSide.width, 2);
      expect(normal.borderSide.color, AppColors.borderControl);
      expect(focused.borderSide.color, AppColors.brand700);
      expect(focused.borderSide.width, greaterThan(2));
      expect(input.floatingLabelBehavior, FloatingLabelBehavior.always);
    });

    test('cards are white with a 16 radius and a subtle border', () {
      final card = theme.cardTheme;
      final shape = card.shape as RoundedRectangleBorder;
      expect(card.color, AppColors.surface);
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, AppColors.borderSubtle);
    });
  });

  group('buttons', () {
    testWidgets('primary is 56 px tall, full width, and taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AppPrimaryButton(label: 'Send request', onPressed: () => taps++)),
      );
      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, 56);
      expect(size.width, tester.getSize(find.byType(Scaffold)).width);
      await tester.tap(find.text('Send request'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(FilledButton)),
        matchesSemantics(
          label: 'Send request',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('a disabled primary says why', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppPrimaryButton(
            label: 'Send request',
            onPressed: null,
            disabledReason: 'Choose a time to continue.',
          ),
        ),
      );
      expect(find.text('Choose a time to continue.'), findsOneWidget);
    });

    testWidgets('secondary is an outlined 56 px button', (tester) async {
      await tester.pumpWidget(
        _host(AppSecondaryButton(label: 'Reschedule', onPressed: () {})),
      );
      expect(tester.getSize(find.byType(OutlinedButton)).height, 56);
    });

    testWidgets('danger is red with an icon and a word', (tester) async {
      await tester.pumpWidget(
        _host(AppDangerButton(label: 'Cancel booking', onPressed: () {})),
      );
      expect(find.text('Cancel booking'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style!.backgroundColor!.resolve({}), AppColors.errorSolid);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('a long label wraps instead of overflowing at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: AppPrimaryButton(
              label: 'Review booking and send the request now',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('StatusChip', () {
    test('each type has its own icon shape', () {
      final icons = StatusType.values.map((t) => t.icon).toSet();
      expect(icons.length, StatusType.values.length);
    });

    testWidgets('shows the icon, the word and the colors together', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final type in StatusType.values)
                StatusChip(type: type, label: type.name),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final type in StatusType.values) {
        expect(find.text(type.name), findsOneWidget);
        expect(find.byIcon(type.icon), findsOneWidget);
        final chip = find.ancestor(
          of: find.text(type.name),
          matching: find.byType(DecoratedBox),
        );
        final box = tester.widget<DecoratedBox>(chip.first);
        expect((box.decoration as BoxDecoration).color, type.soft);
      }
    });
  });

  group('RatingBadge', () {
    testWidgets('shows an outlined star with the number beside it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const RatingBadge(rating: 4.8)));
      expect(find.text('4.8'), findsOneWidget);
      final stars = tester.widgetList<Icon>(find.byIcon(Icons.star_rounded));
      expect(stars.length, 2);
      // A dark outline star behind the amber one.
      expect(stars.map((s) => s.color), [
        AppColors.accent700,
        AppColors.accent500,
      ]);
    });
  });

  group('ProviderCard', () {
    const provider = Professional(
      id: 'p1',
      name: 'Nuwan Fernando',
      specialty: 'AC technician',
      rating: 4.8,
      reviewCount: 124,
      verified: true,
      pricing: 2500,
    );

    testWidgets('shows the name, profession, verified, rating and price', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(ProviderCard(provider: provider, onTap: () => taps++)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nuwan Fernando'), findsOneWidget);
      expect(find.text('AC technician'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.byIcon(StatusType.success.icon), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('124 reviews'), findsOneWidget);
      expect(find.text('From Rs. 2,500'), findsOneWidget);
      await tester.tap(find.text('Nuwan Fernando'));
      expect(taps, 1);
    });
  });

  group('ServiceTile', () {
    testWidgets('selected shows a check and the word, not only color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Row(
            children: [
              ServiceTile(
                icon: Icons.plumbing,
                label: 'Plumbing',
                onTap: () {},
                width: 120,
              ),
              ServiceTile(
                icon: Icons.bolt,
                label: 'Electrical',
                selected: true,
                onTap: () {},
                width: 120,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Selected'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('shows a title, a help line and an optional button', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          EmptyState(
            title: 'No bookings yet',
            message: 'Your bookings will show here.',
            actionLabel: 'Find a provider',
            onAction: () => taps++,
          ),
        ),
      );
      expect(find.text('No bookings yet'), findsOneWidget);
      expect(find.text('Your bookings will show here.'), findsOneWidget);
      await tester.tap(find.text('Find a provider'));
      expect(taps, 1);
    });

    testWidgets('has no button unless one is given', (tester) async {
      await tester.pumpWidget(
        _host(const EmptyState(title: 'Nothing here', message: 'Come back.')),
      );
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('AppTextField', () {
    testWidgets('always shows its label, is 56 px tall and takes text', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _host(
          AppTextField(
            label: 'Your address',
            hintText: 'House number, street',
            controller: controller,
          ),
        ),
      );
      expect(find.text('Your address'), findsOneWidget);
      expect(tester.getSize(find.byType(TextField)).height, 56);
      await tester.enterText(find.byType(TextField), 'No. 42');
      expect(controller.text, 'No. 42');
    });

    testWidgets('an error shows an icon and words', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppTextField(
            label: 'Email',
            errorText: 'Add the full email, like name@example.com.',
          ),
        ),
      );
      expect(
        find.text('Add the full email, like name@example.com.'),
        findsOneWidget,
      );
      expect(find.byIcon(StatusType.error.icon), findsOneWidget);
    });
  });

  group('motion', () {
    testWidgets('a list item fades and slides in, then settles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const FadeSlideIn(index: 2, child: Text('Item'))),
      );
      expect(find.text('Item'), findsOneWidget);
      expect(find.byType(Opacity), findsWidgets);
      await tester.pumpAndSettle();
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Item'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('no animation at all when the phone reduces motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FadeSlideIn(index: 2, child: Text('Item')),
          reduceMotion: true,
        ),
      );
      expect(
        find.ancestor(of: find.text('Item'), matching: find.byType(Opacity)),
        findsNothing,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a pressed button shrinks a little', (tester) async {
      await tester.pumpWidget(
        _host(AppPrimaryButton(label: 'Send request', onPressed: () {})),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Send request')),
      );
      await tester.pump(AppMotion.base);
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, AppMotion.pressedScale);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a pressed button does not move when motion is reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppPrimaryButton(label: 'Send request', onPressed: () {}),
          reduceMotion: true,
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });

    test('durations follow the guide', () {
      expect(AppMotion.base, const Duration(milliseconds: 200));
      expect(AppMotion.sheet, const Duration(milliseconds: 300));
      expect(AppMotion.curve, Curves.easeOut);
    });
  });

  group('text size setting', () {
    tearDown(() async {
      await TextSizeController.instance.setSize(AppTextSize.normal);
    });

    test('Normal 18, Large 22 and Extra large 27', () {
      expect(AppTextSize.normal.bodySize, 18);
      expect(AppTextSize.large.bodySize, 22);
      expect(AppTextSize.extraLarge.bodySize, 27);
      expect(AppTextSize.normal.factor, 1);
      expect(AppTextSize.extraLarge.factor, 1.5);
    });

    test('is saved, and loaded again', () async {
      final controller = TextSizeController.instance;
      await controller.setSize(AppTextSize.large);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_text_size'), 'large');

      await controller.setSize(AppTextSize.normal);
      SharedPreferences.setMockInitialValues({'app_text_size': 'extraLarge'});
      await controller.load();
      expect(controller.size, AppTextSize.extraLarge);
    });

    test('multiplies the phone scale but never goes past 200%', () async {
      final controller = TextSizeController.instance;
      await controller.setSize(AppTextSize.extraLarge);
      expect(
        controller.scalerFor(const TextScaler.linear(1)).scale(100),
        closeTo(150, 0.01),
      );
      expect(
        controller.scalerFor(const TextScaler.linear(1.5)).scale(100),
        200,
      );
      await controller.setSize(AppTextSize.normal);
      expect(controller.scalerFor(const TextScaler.linear(3)).scale(100), 200);
      expect(
        controller.scalerFor(const TextScaler.linear(0.8)).scale(100),
        100,
      );
    });

    testWidgets('the selector shows a check on the chosen size', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const TextSizeSelector()));
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('text-size-large')));
      await tester.pump();
      expect(TextSizeController.instance.size, AppTextSize.large);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('text-size-large')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });
  });
}
