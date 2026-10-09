import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/professional.dart';
import 'package:home_service_bookin_app/models/service_category.dart';
import 'package:home_service_bookin_app/screens/customer/customer_home_screen.dart';
import 'package:home_service_bookin_app/screens/customer/providers/all_providers_screen.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

import 'support/customer_fakes.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

Professional pro(
  String id,
  String name,
  String specialty, {
  String? code,
  double? rating,
  int reviews = 0,
  String about = '',
  String phone = '+94770000000',
}) => Professional(
  id: id,
  name: name,
  specialty: specialty,
  services: [specialty],
  providerCode: code,
  rating: rating,
  reviewCount: reviews,
  about: about,
  phone: phone,
  experience: 6,
  verified: true,
);

final plumber = pro(
  'p1',
  'Kasun Wijesinghe',
  'Plumbing & Sanitation Specialist',
  code: 'HCP-1002',
  rating: 4.7,
  reviews: 10,
  about: 'Leak repairs and bathroom plumbing.',
);
final acPro = pro(
  'p2',
  'Nuwan Fernando',
  'Air Conditioning & Electrical Specialist',
  code: 'HCP-1001',
  rating: 4.9,
  reviews: 12,
);
final cleaner = pro(
  'p3',
  'Ishara Perera',
  'Deep House Cleaner',
  code: 'HCP-1004',
);

Future<FakeBookingService> openHome(
  WidgetTester tester,
  List<Professional> providers,
) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final service = FakeBookingService(
    bookings: [booking()],
    professionals: providers,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CustomerHomeScreen(
        user: testUser,
        authService: AuthService(auth: _Auth(), firestore: _Db()),
        addressService: FakeAddressService([address(isDefault: true)]),
        bookingService: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  group('service categories', () {
    test('providers are placed in categories by what they do', () {
      ServiceCategory by(String id) =>
          ServiceCategory.all.firstWhere((c) => c.id == id);
      expect(by('plumbing').matches(plumber), isTrue);
      expect(by('plumbing').matches(acPro), isFalse);
      expect(by('ac').matches(acPro), isTrue);
      expect(by('electrical').matches(acPro), isTrue);
      expect(by('cleaning').matches(cleaner), isTrue);
      // A provider with no recognised trade belongs to no category.
      final other = pro('x', 'Someone', 'Service provider');
      expect(ServiceCategory.all.any((c) => c.matches(other)), isFalse);
      expect(by('plumbing').count([plumber, acPro, cleaner]), 1);
    });

    test('"ac" is matched as a word, not inside other words', () {
      final ac = ServiceCategory.all.firstWhere((c) => c.id == 'ac');
      expect(ac.matches(pro('a', 'A', 'AC Technician')), isTrue);
      expect(ac.matches(pro('b', 'B', 'Face cream seller')), isFalse);
    });
  });

  group('customer home shows real providers', () {
    testWidgets('lists the verified providers with rating, reviews and ID', (
      tester,
    ) async {
      await openHome(tester, [plumber, acPro, cleaner]);
      expect(find.text('Services for your home'), findsOneWidget);
      expect(find.text('Verified providers'), findsOneWidget);
      expect(find.text('3 providers'), findsOneWidget);
      // A to Z by name, with the same live data the booking screens use.
      expect(find.text('Ishara Perera'), findsOneWidget);
      expect(find.text('Kasun Wijesinghe'), findsOneWidget);
      expect(find.text('Nuwan Fernando'), findsOneWidget);
      expect(find.text('10 reviews'), findsOneWidget);
      expect(find.text('ID HCP-1001'), findsOneWidget);
      // None of the old built-in sample people are shown any more.
      expect(find.text('Dilan'), findsNothing);
      expect(find.text('Cleaner'), findsNothing);
    });

    testWidgets('categories filter the list and show their counts', (
      tester,
    ) async {
      await openHome(tester, [plumber, acPro, cleaner]);
      for (final label in ['All', 'Plumbing', 'Electrical']) {
        expect(find.text(label), findsWidgets);
      }
      await tester.tap(find.byKey(const ValueKey('category-plumbing')));
      await tester.pumpAndSettle();
      // The service cards show their own counts, so read the list's count.
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('provider-count'))).data,
        '1 provider',
      );
      expect(find.text('Kasun Wijesinghe'), findsOneWidget);
      expect(find.text('Nuwan Fernando'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('category-all')));
      await tester.pumpAndSettle();
      expect(find.text('3 providers'), findsOneWidget);
    });

    testWidgets('search narrows by name, trade or Provider ID', (tester) async {
      await openHome(tester, [plumber, acPro, cleaner]);
      Future<void> search(String text) async {
        await tester.enterText(
          find.byKey(const ValueKey('provider-search')),
          text,
        );
        await tester.pumpAndSettle();
      }

      await search('nuwan');
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('provider-count'))).data,
        '1 provider',
      );
      await search('clean');
      expect(find.text('Ishara Perera'), findsOneWidget);
      expect(find.text('Kasun Wijesinghe'), findsNothing);
      await search('hcp-1002');
      expect(find.text('Kasun Wijesinghe'), findsOneWidget);
      await search('astronaut');
      expect(find.byKey(const ValueKey('no-providers')), findsOneWidget);
      expect(find.textContaining('No providers match'), findsOneWidget);
    });

    testWidgets('says so while nobody is verified yet', (tester) async {
      await openHome(tester, const []);
      expect(find.byKey(const ValueKey('no-providers')), findsOneWidget);
      expect(find.textContaining('No verified providers yet'), findsOneWidget);
    });

    testWidgets('tapping a provider opens their Provider Profile page', (
      tester,
    ) async {
      await openHome(tester, [plumber, acPro]);
      await tester.tap(find.byKey(const ValueKey('provider-card-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Provider Profile'), findsOneWidget);
      expect(find.text('Kasun Wijesinghe'), findsWidgets);
    });

    testWidgets('"See all" opens the full list of providers', (tester) async {
      await openHome(tester, [plumber, acPro]);
      await tester.tap(find.byKey(const ValueKey('see-all-providers')));
      await tester.pumpAndSettle();
      expect(find.byType(AllProvidersScreen), findsOneWidget);
    });
  });
}
