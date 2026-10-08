import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';

/// Gives a screen the theme for the current language: Atkinson Hyperlegible
/// for English and Noto Sans Sinhala for Sinhala (each the other's fallback),
/// with the size and line height table of the style guide.
abstract final class LocaleTypography {
  /// Tests switch this off so no font is downloaded.
  @visibleForTesting
  static bool enabled = true;

  static bool isSinhala(Locale locale) => locale.languageCode == 'si';

  /// The language theme from [AppTheme.forLocale]. Screens that were not
  /// given the app localizations (such as isolated widget tests) get [base]
  /// unchanged.
  static ThemeData apply(BuildContext context, ThemeData base) {
    if (!enabled ||
        Localizations.of<AppLocalizations>(context, AppLocalizations) == null) {
      return base;
    }
    return AppTheme.forLocale(Localizations.localeOf(context));
  }
}
