import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../auth/auth_wrapper.dart';
import '../splash/splash_screen.dart';
import 'language_selection_screen.dart';
import 'onboarding_page.dart';
import 'onboarding_preferences.dart';
import 'onboarding_screen.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    this.preferences,
    this.authBuilder,
    this.showLanguageSelection = true,
    this.splashDuration,
    this.signedIn,
  });

  final OnboardingPreferences? preferences;
  final WidgetBuilder? authBuilder;
  final bool showLanguageSelection;
  final Duration? splashDuration;

  /// Tells whether someone is signed in when the app opens. Defaults to the
  /// Firebase session; tests can pass their own.
  final Future<bool> Function()? signedIn;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final _preferences = widget.preferences ?? OnboardingPreferences();
  bool _loading = true;
  bool _completed = false;
  bool _failed = false;
  bool _languageChosen = false;

  Duration get _effectiveSplashDuration =>
      widget.splashDuration ??
      (widget.preferences != null
          ? Duration.zero
          : const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Whether a Firebase session was restored. Waits for the first auth state
  /// (a saved session is restored asynchronously at start-up) but never for
  /// long, and treats any failure as "not signed in".
  static Future<bool> _firebaseSignedIn() async {
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 3),
      );
      return user != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isSignedIn() async {
    try {
      return await (widget.signedIn ?? _firebaseSignedIn)();
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final stopwatch = Stopwatch()..start();
    try {
      // Development only. Launch once with --dart-define=RESET_ONBOARDING=true.
      if (kDebugMode && const bool.fromEnvironment('RESET_ONBOARDING')) {
        await _preferences.reset();
      }
      // Onboarding is for people who are signed out: a first launch, or the
      // app opened again after logging out. Someone who is still signed in
      // goes straight to their home screen.
      final signedIn = await _isSignedIn();
      final completed = signedIn
          ? true
          : widget.preferences != null
          ? await _preferences.isCompleted()
          : false;
      final hasSavedLang = await LocaleController.instance.hasSavedLanguage();

      final elapsed = stopwatch.elapsed;
      if (_effectiveSplashDuration > elapsed) {
        await Future.delayed(_effectiveSplashDuration - elapsed);
      }

      if (mounted) {
        setState(() {
          _completed = completed;
          _languageChosen = hasSavedLang;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finish() async {
    await _preferences.complete();
    if (mounted) setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SplashScreen(
        key: ValueKey('splash-screen'),
        minDuration: Duration.zero,
      );
    }

    if (_failed) {
      return Theme(
        data: OnboardingStyle.theme,
        child: Scaffold(
          backgroundColor: OnboardingStyle.background,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load your app preferences.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Replace the entry layer rather than pushing a route. Back cannot return
    // to completed onboarding, and AuthWrapper keeps its existing role logic.
    if (_completed) {
      return widget.authBuilder?.call(context) ?? const AuthWrapper();
    }
    if (widget.showLanguageSelection && !_languageChosen) {
      return LanguageSelectionScreen(
        onContinue: () async {
          if (mounted) setState(() => _languageChosen = true);
        },
      );
    }
    return OnboardingScreen(onComplete: _finish);
  }
}
