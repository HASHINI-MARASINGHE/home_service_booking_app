import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language (English, Sinhala, or Tamil), remembers it between runs and
/// tells listeners at once when it changes, so no restart is needed.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final instance = LocaleController._();

  static const supported = [
    ui.Locale('en'),
    ui.Locale('si'),
    ui.Locale('ta'),
  ];
  static const _key = 'app_language';

  ui.Locale _locale = const ui.Locale('en');
  ui.Locale get locale => _locale;

  /// Checks if a language preference was explicitly saved previously.
  Future<bool> hasSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) != null;
    } catch (_) {
      return false;
    }
  }

  /// Reads the saved language. With nothing saved, follows the phone language
  /// and falls back to English when that is not one of the supported languages.
  Future<void> load() async {
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(_key);
    } catch (_) {
      // Storage unavailable: just use the phone language below.
    }
    _locale = _resolve(saved) ?? _fromPhone();
    notifyListeners();
  }

  Future<void> setLocale(ui.Locale locale) async {
    final next = _resolve(locale.languageCode);
    if (next == null || next == _locale) return;
    _locale = next;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        next.languageCode,
      );
    } catch (_) {
      // The language still changed for this session.
    }
  }

  static ui.Locale? _resolve(String? code) {
    for (final locale in supported) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  static ui.Locale _fromPhone() =>
      _resolve(ui.PlatformDispatcher.instance.locale.languageCode) ??
      const ui.Locale('en');
}
