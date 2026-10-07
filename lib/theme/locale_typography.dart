import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';

/// Atkinson Hyperlegible for English and Noto Sans Sinhala for Sinhala, each
/// with the other as fallback for mixed text. Letter spacing is always 0 and
/// Sinhala gets taller lines so its marks above and below are not cut.
abstract final class LocaleTypography {
  /// Tests switch this off so no font is downloaded.
  @visibleForTesting
  static bool enabled = true;

  static bool isSinhala(Locale locale) => locale.languageCode == 'si';

  /// Line height multiplier for body text (about 1.75 Sinhala, 1.5 English).
  static double bodyHeight(Locale locale) => isSinhala(locale) ? 1.75 : 1.5;

  /// Line height multiplier for headings (about 1.6 Sinhala, 1.3 English).
  static double headingHeight(Locale locale) => isSinhala(locale) ? 1.6 : 1.3;

  /// Returns [base] with the font for the current language. Screens that were
  /// not given the app localizations (such as isolated widget tests) are
  /// returned unchanged.
  static ThemeData apply(BuildContext context, ThemeData base) {
    if (!enabled ||
        Localizations.of<AppLocalizations>(context, AppLocalizations) == null) {
      return base;
    }
    final locale = Localizations.localeOf(context);
    final sinhala = isSinhala(locale);
    final primary = sinhala
        ? GoogleFonts.notoSansSinhala()
        : GoogleFonts.atkinsonHyperlegible();
    final fallback = sinhala
        ? GoogleFonts.atkinsonHyperlegible()
        : GoogleFonts.notoSansSinhala();
    final family = primary.fontFamily;
    final fallbacks = [if (fallback.fontFamily != null) fallback.fontFamily!];

    TextStyle? style(TextStyle? s, {double? height}) => s?.copyWith(
      fontFamily: family,
      fontFamilyFallback: fallbacks,
      letterSpacing: 0,
      height: height ?? s.height,
      fontSize: s.fontSize != null && s.fontSize! < 14 ? 14 : s.fontSize,
    );

    final t = base.textTheme;
    final body = bodyHeight(locale);
    final heading = headingHeight(locale);
    final textTheme = TextTheme(
      displayLarge: style(t.displayLarge, height: heading),
      displayMedium: style(t.displayMedium, height: heading),
      displaySmall: style(t.displaySmall, height: heading),
      headlineLarge: style(t.headlineLarge, height: heading),
      headlineMedium: style(t.headlineMedium, height: heading),
      headlineSmall: style(t.headlineSmall, height: heading),
      titleLarge: style(t.titleLarge, height: heading),
      titleMedium: style(t.titleMedium, height: heading),
      titleSmall: style(t.titleSmall, height: heading),
      bodyLarge: style(t.bodyLarge, height: body),
      bodyMedium: style(t.bodyMedium, height: body),
      bodySmall: style(t.bodySmall, height: body),
      labelLarge: style(t.labelLarge, height: body),
      labelMedium: style(t.labelMedium, height: body),
      labelSmall: style(t.labelSmall, height: body),
    );

    ButtonStyle? button(ButtonStyle? b) => b?.copyWith(
      textStyle: WidgetStatePropertyAll(
        style(b.textStyle?.resolve({}) ?? t.labelLarge, height: body),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: style(
          base.appBarTheme.titleTextStyle ?? t.titleLarge,
          height: heading,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: button(base.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button(base.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: button(base.textButtonTheme.style),
      ),
    );
  }
}
