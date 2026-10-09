import 'package:shared_preferences/shared_preferences.dart';

/// Stores only onboarding state; Firebase continues to own authentication.
class OnboardingPreferences {
  OnboardingPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const completedKey = 'onboarding_completed';
  final SharedPreferencesAsync _preferences;

  Future<bool> isCompleted() async =>
      await _preferences.getBool(completedKey) ?? false;

  Future<void> complete() => _preferences.setBool(completedKey, true);

  /// Removes only this flag, preserving all other preferences and the session.
  Future<void> reset() => _preferences.remove(completedKey);
}
