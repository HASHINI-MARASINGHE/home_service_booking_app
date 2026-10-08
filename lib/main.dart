import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/onboarding/onboarding_gate.dart';
import 'theme/app_theme.dart';
import 'theme/text_size_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocaleController.instance.load();
  await TextSizeController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      LocaleController.instance,
      TextSizeController.instance,
    ]),
    builder: (context, _) => MaterialApp(
      title: 'HomeCare',
      theme: AppTheme.forLocale(LocaleController.instance.locale),
      locale: LocaleController.instance.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // The chosen text size and the phone's own text size apply to every
      // screen together, and never go past 200%.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextSizeController.instance.scalerFor(media.textScaler),
          ),
          child: child!,
        );
      },
      home: const OnboardingGate(),
    ),
  );
}
