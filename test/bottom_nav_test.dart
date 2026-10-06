import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/widgets/common/app_bottom_nav.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget host(List<AppNavItem> items, int selected, ValueChanged<int> onTap) =>
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            items: items,
            selectedIndex: selected,
            onSelected: onTap,
          ),
        ),
      );

  group('customer navigation (Nav/Customer)', () {
    testWidgets('shows Home, Bookings, Saved, Profile with the design icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppBottomNav.customerItems, 0, (_) {}),
      );
      for (final label in ['Home', 'Bookings', 'Saved', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final icon in [
        LucideIcons.house,
        LucideIcons.clipboard,
        LucideIcons.bookmark,
        LucideIcons.user,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('only the selected tab is highlighted', (tester) async {
      await tester.pumpWidget(host(AppBottomNav.customerItems, 1, (_) {}));
      final selected = tester.widget<Text>(find.text('Bookings'));
      final idle = tester.widget<Text>(find.text('Home'));
      expect(selected.style!.fontWeight, FontWeight.w700);
      expect(selected.style!.color, AppColors.primary);
      expect(idle.style!.fontWeight, FontWeight.w500);
      expect(idle.style!.color, AppColors.muted);
      expect(
        tester.getSemantics(find.text('Bookings')),
        matchesSemantics(
          label: 'Bookings',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
    });

    testWidgets('tapping a tab reports its index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(host(AppBottomNav.customerItems, 0, taps.add));
      await tester.tap(find.text('Saved'));
      await tester.tap(find.text('Profile'));
      expect(taps, [2, 3]);
    });
  });

  group('provider navigation (Nav/Provider)', () {
    testWidgets('shows Leads, My Jobs, Earnings, Profile with the design icons', (
      tester,
    ) async {
      await tester.pumpWidget(host(AppBottomNav.providerItems, 2, (_) {}));
      for (final label in ['Leads', 'My Jobs', 'Earnings', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final icon in [
        LucideIcons.house,
        LucideIcons.calendar,
        LucideIcons.wallet,
        LucideIcons.user,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }
      expect(
        tester.widget<Text>(find.text('Earnings')).style!.fontWeight,
        FontWeight.w700,
      );
    });
  });

  testWidgets('tabs stay tappable (48px+) and fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(AppBottomNav.providerItems, 1, (_) {}));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(
      find.ancestor(of: find.text('My Jobs'), matching: find.byType(InkWell)),
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
