import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';
import 'package:home_service_bookin_app/widgets/common/app_backdrop.dart';
import 'package:home_service_bookin_app/widgets/common/homecare_logo.dart';

Future<void> pumpShell(WidgetTester tester, {required bool backdrop}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BrandShell(
          backdrop: backdrop,
          child: const Scaffold(body: Text('page')),
        ),
      ),
    );

void main() {
  testWidgets('customer/provider shell draws the backdrop and lets it show', (
    tester,
  ) async {
    await pumpShell(tester, backdrop: true);
    expect(find.byType(AppBackdrop), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final context = tester.element(find.byType(Scaffold));
    expect(
      scaffold.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      Colors.transparent,
    );
  });

  testWidgets('a shell without the flag (admin) keeps the plain background', (
    tester,
  ) async {
    await pumpShell(tester, backdrop: false);
    expect(find.byType(AppBackdrop), findsNothing);
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.bg);
  });

  testWidgets('pages cross-fade so see-through pages never overlap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: backdropTheme(AppTheme.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('second')),
                ),
              ),
              child: const Text('first'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('first'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.text('first'),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fades.any((fade) => fade.opacity.value < 1), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
  });
}
