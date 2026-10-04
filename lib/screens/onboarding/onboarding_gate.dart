import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../auth/auth_wrapper.dart';
import 'onboarding_page.dart';
import 'onboarding_preferences.dart';
import 'onboarding_screen.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, this.preferences, this.authBuilder});

  final OnboardingPreferences? preferences;
  final WidgetBuilder? authBuilder;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late final _preferences = widget.preferences ?? OnboardingPreferences();
  bool _loading = true;
  bool _completed = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      // Development only. Launch once with --dart-define=RESET_ONBOARDING=true.
      if (kDebugMode && const bool.fromEnvironment('RESET_ONBOARDING')) {
        await _preferences.reset();
      }
      final completed = await _preferences.isCompleted();
      if (mounted) setState(() => _completed = completed);
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
    if (_loading || _failed) {
      return Theme(
        data: OnboardingStyle.theme,
        child: Scaffold(
          backgroundColor: OnboardingStyle.background,
          body: SafeArea(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator(color: OnboardingStyle.teal)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Unable to load your app preferences.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
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
    return OnboardingScreen(onComplete: _finish);
  }
}
