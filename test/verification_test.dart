import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_bookin_app/models/app_notification.dart';
import 'package:home_service_bookin_app/models/app_user.dart';
import 'package:home_service_bookin_app/models/provider_profile.dart';
import 'package:home_service_bookin_app/models/provider_verification.dart';
import 'package:home_service_bookin_app/models/rating_stats.dart';
import 'package:home_service_bookin_app/models/verification_draft.dart';
import 'package:home_service_bookin_app/screens/admin/admin_home_screen.dart';
import 'package:home_service_bookin_app/screens/admin/admin_verification_screen.dart';
import 'package:home_service_bookin_app/screens/auth/admin_login_screen.dart';
import 'package:home_service_bookin_app/screens/auth/auth_form.dart';
import 'package:home_service_bookin_app/screens/auth/provider_registration_screen.dart';
import 'package:home_service_bookin_app/screens/provider/unverified_provider_shell.dart';
import 'package:home_service_bookin_app/models/professional.dart';
import 'package:home_service_bookin_app/screens/provider/verification/verification_screen.dart';
import 'package:home_service_bookin_app/screens/provider/verification/verification_widgets.dart';
import 'package:home_service_bookin_app/services/admin_service.dart';
import 'package:home_service_bookin_app/services/auth_service.dart';
import 'package:home_service_bookin_app/services/document_picker.dart';
import 'package:home_service_bookin_app/services/provider_notification_service.dart';
import 'package:home_service_bookin_app/services/provider_profile_service.dart';
import 'package:home_service_bookin_app/services/provider_verification_service.dart';
import 'package:home_service_bookin_app/theme/app_theme.dart';

class _Auth extends Fake implements FirebaseAuth {}

class _Db extends Fake implements FirebaseFirestore {}

class _User extends Fake implements User {
  @override
  String get uid => 'new-provider';
}

// ---------------------------------------------------------------- fakes
class _Picker implements DocumentPicker {
  final picked = <String>[];

  PickedDocument _doc(String name, String type) => PickedDocument(
    name: name,
    bytes: Uint8List.fromList(List.filled(2048, 7)),
    contentType: type,
  );

  @override
  Future<PickedDocument?> pickImage() async {
    picked.add('image');
    return _doc('id_${picked.length}.jpg', 'image/jpeg');
  }

  @override
  Future<PickedDocument?> takeSelfie() async {
    picked.add('selfie');
    return _doc('selfie.jpg', 'image/jpeg');
  }

  @override
  Future<PickedDocument?> pickDocument() async {
    picked.add('document');
    return _doc('doc_${picked.length}.jpg', 'image/jpeg');
  }
}

class _Verification extends ProviderVerificationService {
  _Verification() : super(auth: _Auth(), firestore: _Db());
  final submitted = <VerificationDraft>[];

  @override
  Future<void> submitFor(String uid, VerificationDraft draft) async =>
      submitted.add(draft);

  @override
  Future<void> submit(VerificationDraft draft) async => submitted.add(draft);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(auth: _Auth(), firestore: _Db());
  Map<String, Object?>? registered;
  String? adminUser;
  Object? adminError;

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
    Future<void> Function(User user)? onCreated,
  }) async {
    registered = {'name': name, 'email': email, 'role': role};
    await onCreated?.call(_User());
    return AppUser(uid: 'new-provider', name: name, email: email, role: role);
  }

  @override
  Future<void> adminLogin({
    required String username,
    required String password,
  }) async {
    adminUser = username;
    if (adminError != null) throw adminError!;
  }
}

class _Notifications extends ProviderNotificationService {
  _Notifications(this.items) : super(auth: _Auth(), firestore: _Db());
  final List<AppNotification> items;

  @override
  Stream<List<AppNotification>> watchNotifications() => Stream.value(items);

  @override
  Stream<int> watchUnreadCount() =>
      Stream.value(items.where((n) => !n.read).length);
}

class _Profiles extends ProviderProfileService {
  _Profiles() : super(auth: _Auth(), firestore: _Db());

  @override
  Stream<ProviderProfile> watchProfile() => Stream.value(
    const ProviderProfile(providerId: 'p', profession: 'Plumber'),
  );

  @override
  Stream<RatingStats?> watchRatingStats() => Stream.value(null);
}

class _Admin extends AdminService {
  _Admin(this.items) : super(auth: _Auth(), firestore: _Db());
  final List<ProviderVerification> items;
  final verified = <String>[];
  final rejected = <String, String>{};

  @override
  Stream<List<ProviderVerification>> watchByStatus(VerificationStatus status) =>
      Stream.value(items.where((v) => v.status == status).toList());

  @override
  Stream<List<Professional>> watchAllProfessionals() => Stream.value(const []);

  @override
  Stream<int> watchPendingCount() => Stream.value(
    items.where((v) => v.status == VerificationStatus.pending).length,
  );

  @override
  Future<String> verify(ProviderVerification submission) async {
    verified.add(submission.uid);
    return 'HCP-1003';
  }

  @override
  Future<void> reject(ProviderVerification submission, String reason) async =>
      rejected[submission.uid] = reason;
}

VerificationFile file(String name) =>
    VerificationFile(name: name, url: 'https://example.test/$name');

ProviderVerification submission({
  VerificationStatus status = VerificationStatus.pending,
  String? code,
  String? reason,
}) => ProviderVerification(
  uid: 'new-provider',
  fullName: 'Sahan Perera',
  phone: '+94771234567',
  profession: 'Plumber',
  experienceYears: 4,
  about: 'Pipes and leaks.',
  idType: 'nic',
  idNumber: '928471923V',
  idFront: file('front.jpg'),
  idBack: file('back.jpg'),
  selfie: file('selfie.jpg'),
  cv: file('cv.jpg'),
  certificates: [file('cert.jpg')],
  experiences: const [ExperienceEntry(title: 'Site helper', years: 2)],
  status: status,
  providerCode: code,
  rejectionReason: reason,
);

Widget app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

VerificationDraft completeDraft() {
  final d = VerificationDraft(
    fullName: 'Sahan Perera',
    phone: '+94771234567',
    profession: 'Plumber',
    experienceYears: '4',
    idNumber: '928471923V',
  );
  final doc = PickedDocument(
    name: 'x.jpg',
    bytes: Uint8List(10),
    contentType: 'image/jpeg',
  );
  d.idFront = doc;
  d.idBack = doc;
  d.selfie = doc;
  d.cv = doc;
  d.certificates.add(doc);
  return d;
}

void main() {
  late DocumentPicker originalPicker;
  // Most tests below cover the strict mode (everything compulsory); the
  // relaxed group at the end covers today's default.
  setUp(() {
    originalPicker = DocumentPicker.instance;
    VerificationDraft.requireEverything = true;
  });
  tearDown(() {
    DocumentPicker.instance = originalPicker;
    VerificationDraft.requireEverything = false;
  });

  group('verification draft rules', () {
    test('NIC and passport numbers are checked by format', () {
      for (final ok in ['928471923V', '928471923x', '199284719231']) {
        expect(VerificationDraft.validIdNumber('nic', ok), isTrue, reason: ok);
      }
      for (final bad in ['92847192V', '9284719231', 'ABCDEFGHIJKL', '']) {
        expect(VerificationDraft.validIdNumber('nic', bad), isFalse);
      }
      expect(VerificationDraft.validIdNumber('passport', 'N1234567'), isTrue);
      expect(VerificationDraft.validIdNumber('passport', 'N12'), isFalse);
    });

    test('everything but experience is compulsory', () {
      final d = completeDraft();
      expect(d.firstProblem, isNull);
      expect(d.documentStepsDone, 3);
      // Experience is optional: still complete with none, and with some.
      expect(d.experiences, isEmpty);
      d.experiences.add(const ExperienceEntry(title: 'Helper'));
      expect(d.isComplete, isTrue);

      final missing = <String, (void Function(VerificationDraft), String)>{
        'details': ((d) => d.phone = '12', 'Complete your details first.'),
        'id front': (
          (d) => d.idFront = null,
          'Upload the front of your ID or passport.',
        ),
        'id back': (
          (d) => d.idBack = null,
          'Upload the back of your National ID.',
        ),
        'id number': ((d) => d.idNumber = '1', 'Enter a valid NIC number.'),
        'selfie': ((d) => d.selfie = null, 'Take your live selfie.'),
        'cv': ((d) => d.cv = null, 'Upload your CV.'),
        'certificate': (
          (d) => d.certificates.clear(),
          'Upload at least one course or training certificate.',
        ),
      };
      missing.forEach((name, entry) {
        final draft = completeDraft();
        entry.$1(draft);
        expect(draft.firstProblem, entry.$2, reason: name);
        expect(draft.isComplete, isFalse, reason: name);
      });
    });

    test('a passport does not need a back side', () {
      final d = completeDraft()
        ..idType = 'passport'
        ..idNumber = 'N1234567'
        ..idBack = null;
      expect(d.isComplete, isTrue);
    });
  });

  group('submission model', () {
    test('parses a stored submission and rejects incomplete documents', () {
      final parsed = ProviderVerification.fromMap('u', {
        'fullName': 'A B',
        'phone': '+94771234567',
        'profession': 'Electrician',
        'experienceYears': 3,
        'idType': 'passport',
        'idNumber': 'N1234567',
        'idFront': {'name': 'f.jpg', 'url': 'https://x/f.jpg'},
        'selfie': {'name': 's.jpg', 'url': 'https://x/s.jpg'},
        'cv': {'name': 'cv.jpg', 'url': 'https://x/cv.jpg'},
        'certificates': [
          {'name': 'c.jpg', 'url': 'https://x/c.jpg'},
          {'name': 'broken'},
        ],
        'status': 'verified',
        'providerCode': 'HCP-1004',
      });
      expect(parsed, isNotNull);
      expect(parsed!.isVerified, isTrue);
      expect(parsed.providerCode, 'HCP-1004');
      expect(parsed.idTypeLabel, 'Passport');
      expect(parsed.certificates, hasLength(1));
      expect(ProviderVerification.fromMap('u', {'fullName': 'x'}), isNull);
      expect(ProviderVerification.fromMap('u', null), isNull);
      expect(VerificationStatus.parse('nonsense'), VerificationStatus.none);
    });
  });

  group('register as provider', () {
    testWidgets('choosing Provider offers the verification sign-up', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          AuthForm(
            authService: _FakeAuthService(),
            register: true,
            onSwitch: () {},
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.byKey(const ValueKey('provider-continue')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('role-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Provider').last);
      await tester.pumpAndSettle();
      // Credentials move to the end of the provider flow.
      expect(find.text('Name'), findsNothing);
      expect(find.text('Password'), findsNothing);
      expect(find.byKey(const ValueKey('provider-continue')), findsOneWidget);
    });

    testWidgets('login offers an Admin sign in link', (tester) async {
      await tester.pumpWidget(
        app(
          AuthForm(
            authService: _FakeAuthService(),
            register: false,
            onSwitch: () {},
          ),
        ),
      );
      expect(find.byKey(const ValueKey('admin-signin-link')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('admin-signin-link')));
      await tester.pumpAndSettle();
      expect(find.text('HomeCare administration'), findsOneWidget);
    });

    testWidgets(
      'details, then documents, then login: nothing is created until the end',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        DocumentPicker.instance = _Picker();
        final auth = _FakeAuthService();
        final verification = _Verification();
        await tester.pumpWidget(
          app(
            ProviderRegistrationScreen(
              authService: auth,
              verificationService: verification,
            ),
          ),
        );
        expect(find.text('Step 1 of 3'), findsOneWidget);

        // Step 1: required details; empty fields are rejected.
        await tester.tap(find.byKey(const ValueKey('registration-next')));
        await tester.pump();
        expect(find.text('Enter your full name.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('detail-name')),
          'Sahan Perera',
        );
        await tester.enterText(
          find.byKey(const ValueKey('detail-phone')),
          '+94771234567',
        );
        await tester.enterText(
          find.byKey(const ValueKey('detail-profession')),
          'Plumber',
        );
        await tester.enterText(find.byKey(const ValueKey('detail-years')), '4');
        await tester.tap(find.byKey(const ValueKey('registration-next')));
        await tester.pumpAndSettle();
        expect(find.text('Step 2 of 3'), findsOneWidget);
        expect(find.text('Provider Verification'), findsOneWidget);

        // Step 2: Continue stays locked until every document is in.
        FilledButton next() => tester.widget<FilledButton>(
          find.descendant(
            of: find.byKey(const ValueKey('registration-next')),
            matching: find.byType(FilledButton),
          ),
        );
        expect(next().onPressed, isNull);
        expect(
          find.text('Upload the front of your ID or passport.'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('upload-id-front')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('upload-id-back')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('id-number')),
          '928471923V',
        );
        await tester.pumpAndSettle();
        expect(find.text('Validated'), findsOneWidget);
        expect(find.text('Step 2 of 3 · 1 Completed'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('step-selfie')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('upload-selfie')));
        await tester.pumpAndSettle();
        expect(find.text('Step 3 of 3 · 2 Completed'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('step-qualifications')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('upload-cv')));
        await tester.pumpAndSettle();
        expect(
          next().onPressed,
          isNull,
          reason: 'a certificate is still missing',
        );
        await tester.tap(find.byKey(const ValueKey('add-certificate')));
        await tester.pumpAndSettle();
        expect(find.text('Step 3 of 3 · 3 Completed'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(next().onPressed, isNotNull);
        expect(auth.registered, isNull, reason: 'no account yet');

        await tester.tap(find.byKey(const ValueKey('registration-next')));
        await tester.pumpAndSettle();

        // Step 3: the login, then everything is saved together.
        expect(find.text('Step 3 of 3'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('registration-next')));
        await tester.pump();
        expect(find.text('Enter a valid email address.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('register-email')),
          'sahan@x.test',
        );
        await tester.enterText(
          find.byKey(const ValueKey('register-password')),
          'secret12',
        );
        await tester.enterText(
          find.byKey(const ValueKey('register-confirm')),
          'different',
        );
        await tester.tap(find.byKey(const ValueKey('registration-next')));
        await tester.pump();
        expect(find.text('The passwords do not match.'), findsOneWidget);
        expect(auth.registered, isNull);
        await tester.enterText(
          find.byKey(const ValueKey('register-confirm')),
          'secret12',
        );
        await tester.tap(find.byKey(const ValueKey('registration-next')));
        await tester.pumpAndSettle();

        expect(auth.registered, {
          'name': 'Sahan Perera',
          'email': 'sahan@x.test',
          'role': 'provider',
        });
        final saved = verification.submitted.single;
        expect(saved.profession, 'Plumber');
        expect(saved.idNumber, '928471923V');
        expect(saved.certificates, hasLength(1));
        expect(saved.experiences, isEmpty, reason: 'experience is optional');
      },
    );

    testWidgets('optional work experience can be added and removed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DocumentPicker.instance = _Picker();
      final draft = completeDraft();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: VerificationDocumentsStep(draft: draft),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('step-qualifications')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-experience')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('experience-save')))
            .onPressed,
        isNull,
        reason: 'a role is needed',
      );
      await tester.enterText(
        find.byKey(const ValueKey('experience-title')),
        'Hotel maintenance',
      );
      await tester.enterText(
        find.byKey(const ValueKey('experience-years')),
        '3',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('experience-save')));
      await tester.pumpAndSettle();
      expect(draft.experiences.single.title, 'Hotel maintenance');
      expect(draft.experiences.single.years, 3);
      expect(draft.isComplete, isTrue);

      await tester.tap(find.byTooltip('Remove experience'));
      await tester.pumpAndSettle();
      expect(draft.experiences, isEmpty);
      expect(draft.isComplete, isTrue);
    });
  });

  group('resubmitting from the verification page', () {
    testWidgets('works even when the details form has scrolled out of view', (
      tester,
    ) async {
      // A short phone so the details card is far above the submit button.
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DocumentPicker.instance = _Picker();
      final service = _Verification();
      await tester.pumpWidget(
        app(
          VerificationScreen(
            user: const AppUser(
              uid: 'new-provider',
              name: 'Sahan Perera',
              email: 's@x.test',
              role: 'provider',
            ),
            service: service,
            previous: submission(
              status: VerificationStatus.rejected,
              reason: 'ID photo is blurry.',
            ),
          ),
        ),
      );
      // Details are pre-filled from the rejected submission.
      expect(find.byKey(const ValueKey('rejection-reason')), findsOneWidget);

      Future<void> tapScrolled(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapScrolled('upload-id-front');
      await tapScrolled('upload-id-back');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('id-number')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('id-number')),
        '928471923V',
      );
      await tapScrolled('step-selfie');
      await tapScrolled('upload-selfie');
      await tapScrolled('step-qualifications');
      await tapScrolled('upload-cv');
      await tapScrolled('add-certificate');
      await tapScrolled('verification-submit');

      expect(service.submitted, hasLength(1));
      expect(service.submitted.single.fullName, 'Sahan Perera');
      expect(tester.takeException(), isNull);
    });
  });

  group('provider waiting for verification', () {
    Widget shell(ProviderVerification? v, {List<AppNotification>? notes}) =>
        app(
          UnverifiedProviderShell(
            user: const AppUser(
              uid: 'new-provider',
              name: 'Sahan Perera',
              email: 's@x.test',
              role: 'provider',
            ),
            authService: _FakeAuthService(),
            verificationService: _Verification(),
            verification: v,
            profileService: _Profiles(),
            notificationService: _Notifications(notes ?? const []),
          ),
        );

    testWidgets('only Profile and Notifications are reachable', (tester) async {
      await tester.pumpWidget(shell(submission()));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Notifications'), findsOneWidget);
      for (final locked in ['Leads', 'My Jobs', 'Earnings']) {
        expect(find.text(locked), findsNothing);
      }
      expect(find.text('Verification pending'), findsOneWidget);
      expect(find.text('Your verification is being reviewed'), findsOneWidget);
      expect(find.byKey(const ValueKey('provider-id')), findsNothing);
    });

    testWidgets('a provider who has not submitted is asked to verify', (
      tester,
    ) async {
      await tester.pumpWidget(shell(null));
      await tester.pumpAndSettle();
      expect(find.text('Not verified yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('open-verification')), findsOneWidget);
    });

    testWidgets('a rejected submission shows the reason and a way to fix it', (
      tester,
    ) async {
      await tester.pumpWidget(
        shell(
          submission(
            status: VerificationStatus.rejected,
            reason: 'ID photo is blurry.',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your verification needs changes'), findsOneWidget);
      expect(find.text('ID photo is blurry.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-verification')));
      await tester.pumpAndSettle();
      expect(find.text('Identity Verification'), findsOneWidget);
      expect(find.byKey(const ValueKey('rejection-reason')), findsOneWidget);
    });

    testWidgets('notifications show an unread badge and the news', (
      tester,
    ) async {
      await tester.pumpWidget(
        shell(
          submission(),
          notes: [
            AppNotification(
              id: 'n1',
              recipientId: 'new-provider',
              type: 'verification',
              bookingId: '',
              title: 'Verification needs changes',
              body: 'ID photo is blurry.',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget, reason: 'unread badge');
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Verification needs changes'), findsOneWidget);
      expect(find.text('ID photo is blurry.'), findsOneWidget);
    });
  });

  group('relaxed sign-up (only the name is required for now)', () {
    setUp(() => VerificationDraft.requireEverything = false);

    test('a name alone is enough; what is typed must still be valid', () {
      final d = VerificationDraft(fullName: 'Sahan Perera');
      expect(d.isComplete, isTrue);
      expect(d.hasDocuments, isFalse);
      // Blank optional fields are fine, wrong ones are not.
      expect(VerificationDraft.phoneError(''), isNull);
      expect(VerificationDraft.yearsError(''), isNull);
      expect(VerificationDraft.professionError(''), isNull);
      expect((d..phone = '12').firstProblem, 'Complete your details first.');
      d.phone = '';
      expect((d..idNumber = '12').firstProblem, 'Enter a valid NIC number.');
      d.idNumber = '928471923V';
      expect(d.isComplete, isTrue);
      // The name is always required.
      expect(VerificationDraft(fullName: '').isComplete, isFalse);
    });

    test('a submission without documents is still a valid record', () {
      final parsed = ProviderVerification.fromMap('u', {
        'fullName': 'Name Only',
        'status': 'pending',
      });
      expect(parsed, isNotNull);
      expect(parsed!.hasNoDocuments, isTrue);
      expect(parsed.idFront, isNull);
      expect(parsed.certificates, isEmpty);
    });

    testWidgets('provider can register with only a name and skip documents', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = _FakeAuthService();
      final verification = _Verification();
      await tester.pumpWidget(
        app(
          ProviderRegistrationScreen(
            authService: auth,
            verificationService: verification,
          ),
        ),
      );
      expect(
        find.textContaining('Only your full name is required'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('detail-name')),
        'Sahan Perera',
      );
      await tester.tap(find.byKey(const ValueKey('registration-next')));
      await tester.pumpAndSettle();

      // Documents step: optional, nothing blocks Continue.
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('documents-optional-note')),
        findsOneWidget,
      );
      expect(find.text('Skip for now'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('registration-next')));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('register-email')),
        'sahan@x.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-password')),
        'secret12',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-confirm')),
        'secret12',
      );
      await tester.tap(find.byKey(const ValueKey('registration-next')));
      await tester.pumpAndSettle();

      expect(auth.registered?['role'], 'provider');
      final saved = verification.submitted.single;
      expect(saved.fullName, 'Sahan Perera');
      expect(saved.hasDocuments, isFalse);
    });

    testWidgets('the button says Continue once a document was added', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DocumentPicker.instance = _Picker();
      await tester.pumpWidget(
        app(
          ProviderRegistrationScreen(
            authService: _FakeAuthService(),
            verificationService: _Verification(),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('detail-name')),
        'Sahan Perera',
      );
      await tester.tap(find.byKey(const ValueKey('registration-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('upload-id-front')));
      await tester.pumpAndSettle();
      expect(find.text('Skip for now'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('admin sees when a provider uploaded no documents', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const bare = ProviderVerification(
        uid: 'new-provider',
        fullName: 'Name Only',
        phone: '',
        profession: '',
        experienceYears: 0,
        status: VerificationStatus.pending,
      );
      final service = _Admin([bare]);
      await tester.pumpWidget(
        app(AdminVerificationScreen(service: service, submission: bare)),
      );
      expect(find.byKey(const ValueKey('no-documents-note')), findsOneWidget);
      expect(find.text('Front · Not provided'), findsOneWidget);
      expect(find.text('CV · Not provided'), findsOneWidget);
      // The admin can still decide.
      expect(find.byKey(const ValueKey('verify-provider')), findsOneWidget);
    });
  });

  group('admin', () {
    testWidgets('sign in passes the username and shows refusals', (
      tester,
    ) async {
      final auth = _FakeAuthService()..adminError = const NotAnAdminException();
      await tester.pumpWidget(app(AdminLoginScreen(authService: auth)));
      await tester.tap(find.byKey(const ValueKey('admin-signin')));
      await tester.pump();
      expect(find.text('Enter your admin username.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('admin-username')),
        'admin',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-password')),
        'pw',
      );
      await tester.tap(find.byKey(const ValueKey('admin-signin')));
      await tester.pumpAndSettle();
      expect(auth.adminUser, 'admin');
      expect(
        find.text('This sign-in is for HomeCare admins only.'),
        findsOneWidget,
      );
    });

    test('usernames map to admin addresses', () {
      expect(AuthService.adminEmailFor('Admin'), 'admin@admin.homecare.app');
      expect(AuthService.adminEmailFor(' boss@x.test '), 'boss@x.test');
    });

    Widget dashboard(_Admin service) => app(
      AdminHomeScreen(
        user: const AppUser(
          uid: 'admin',
          name: 'HomeCare Admin',
          email: 'admin@admin.homecare.app',
          role: 'admin',
        ),
        authService: _FakeAuthService(),
        service: service,
      ),
    );

    testWidgets('lists pending providers and opens the details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = _Admin([
        submission(),
        submission(status: VerificationStatus.verified, code: 'HCP-1001'),
      ]);
      await tester.pumpWidget(dashboard(service));
      await tester.pumpAndSettle();
      expect(find.text('Sahan Perera'), findsOneWidget);
      expect(find.text('1'), findsOneWidget, reason: 'pending badge');

      await tester.tap(
        find.byKey(const ValueKey('provider-tile-new-provider')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Review provider'), findsOneWidget);
      expect(find.text('+94771234567'), findsOneWidget);
      expect(find.byKey(const ValueKey('detail-id-number')), findsOneWidget);
      expect(find.text('928471923V'), findsOneWidget);
      expect(find.text('Site helper'), findsOneWidget);
      expect(find.byKey(const ValueKey('verify-provider')), findsOneWidget);
    });

    testWidgets('verifying asks first, then reports the Provider ID', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = _Admin([submission()]);
      await tester.pumpWidget(dashboard(service));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('provider-tile-new-provider')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('verify-provider')));
      await tester.pumpAndSettle();
      expect(find.text('Verify Sahan Perera?'), findsOneWidget);
      expect(service.verified, isEmpty, reason: 'not until confirmed');
      await tester.tap(find.byKey(const ValueKey('confirm-verify')));
      await tester.pumpAndSettle();
      expect(service.verified, ['new-provider']);
      expect(find.textContaining('HCP-1003'), findsOneWidget);
    });

    testWidgets('sending back needs a real reason', (tester) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = _Admin([submission()]);
      await tester.pumpWidget(dashboard(service));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('provider-tile-new-provider')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reject-provider')));
      await tester.pumpAndSettle();
      FilledButton send() => tester.widget<FilledButton>(
        find.byKey(const ValueKey('confirm-reject')),
      );
      expect(send().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('reject-reason')),
        'ID photo is blurry.',
      );
      await tester.pump();
      expect(send().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('confirm-reject')));
      await tester.pumpAndSettle();
      expect(service.rejected, {'new-provider': 'ID photo is blurry.'});
    });

    testWidgets('empty queue says so; profile shows the admin', (tester) async {
      final service = _Admin(const []);
      await tester.pumpWidget(dashboard(service));
      await tester.pumpAndSettle();
      expect(
        find.text('No providers are waiting for verification.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('HomeCare Admin'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Log out'), 200);
      expect(find.text('Log out'), findsOneWidget);
    });
  });
}
