import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles from the style guide. Only Regular and Bold, letter spacing 0,
/// nothing under 14 px. Sinhala has taller lines than English so the marks
/// above and below the letters are never cut.
///
/// Read them with `context.textStyles`, or through the Material text theme.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.bodyLarge,
    required this.bodySmall,
    required this.caption,
    required this.button,
    required this.label,
    required this.amount,
  });

  /// English, Sinhala, and Tamil `size / line` per style. Indic scripts (Sinhala,
  /// Tamil) use taller line heights to prevent vowel diacritic clipping.
  factory AppTextStyles.forLocale(Locale locale) {
    final taller = locale.languageCode == 'si' || locale.languageCode == 'ta';
    TextStyle s(
      double size,
      double line, {
      bool bold = false,
      Color color = AppColors.ink,
    }) => TextStyle(
      color: color,
      fontSize: size,
      height: line / size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      letterSpacing: 0,
    );
    return AppTextStyles(
      display: s(34, taller ? 54 : 42, bold: true),
      h1: s(28, taller ? 46 : 36, bold: true),
      h2: s(24, taller ? 40 : 32, bold: true),
      h3: s(20, taller ? 34 : 28, bold: true),
      bodyLarge: s(18, taller ? 32 : 28),
      bodySmall: s(16, taller ? 28 : 24, color: AppColors.ink2),
      caption: s(taller ? 15 : 14, taller ? 26 : 20, color: AppColors.ink3),
      button: s(18, taller ? 28 : 24, bold: true),
      label: s(16, taller ? 26 : 22, bold: true),
      amount: s(22, taller ? 34 : 28, bold: true),
    );
  }

  static const english = AppTextStyles(
    display: TextStyle(
      color: AppColors.ink,
      fontSize: 34,
      height: 42 / 34,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    h1: TextStyle(
      color: AppColors.ink,
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    h2: TextStyle(
      color: AppColors.ink,
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    h3: TextStyle(
      color: AppColors.ink,
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      color: AppColors.ink,
      fontSize: 18,
      height: 28 / 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      color: AppColors.ink2,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    caption: TextStyle(
      color: AppColors.ink3,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    button: TextStyle(
      color: AppColors.ink,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    label: TextStyle(
      color: AppColors.ink,
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    amount: TextStyle(
      color: AppColors.ink,
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
  );

  final TextStyle display; // welcome screen
  final TextStyle h1; // tab title
  final TextStyle h2; // section titles
  final TextStyle h3; // card titles
  final TextStyle bodyLarge; // default text (18)
  final TextStyle bodySmall; // details (16)
  final TextStyle caption; // smallest allowed (14)
  final TextStyle button; // all buttons
  final TextStyle label; // above inputs
  final TextStyle amount; // prices

  /// Every style with the given font (and a fallback for mixed text).
  AppTextStyles withFont(String? family, List<String> fallback) {
    TextStyle f(TextStyle s) =>
        s.copyWith(fontFamily: family, fontFamilyFallback: fallback);
    return copyWith(
      display: f(display),
      h1: f(h1),
      h2: f(h2),
      h3: f(h3),
      bodyLarge: f(bodyLarge),
      bodySmall: f(bodySmall),
      caption: f(caption),
      button: f(button),
      label: f(label),
      amount: f(amount),
    );
  }

  /// The Material text theme built from these styles, so plain `Text` and
  /// the standard widgets follow the style guide too.
  TextTheme toTextTheme() => TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: h1,
    headlineLarge: h1,
    headlineMedium: h1,
    headlineSmall: h2,
    titleLarge: h2,
    titleMedium: h3,
    titleSmall: label,
    bodyLarge: bodyLarge,
    bodyMedium: bodyLarge,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: label,
    labelSmall: caption,
  );

  @override
  AppTextStyles copyWith({
    TextStyle? display,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? bodyLarge,
    TextStyle? bodySmall,
    TextStyle? caption,
    TextStyle? button,
    TextStyle? label,
    TextStyle? amount,
  }) => AppTextStyles(
    display: display ?? this.display,
    h1: h1 ?? this.h1,
    h2: h2 ?? this.h2,
    h3: h3 ?? this.h3,
    bodyLarge: bodyLarge ?? this.bodyLarge,
    bodySmall: bodySmall ?? this.bodySmall,
    caption: caption ?? this.caption,
    button: button ?? this.button,
    label: label ?? this.label,
    amount: amount ?? this.amount,
  );

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) =>
      other is AppTextStyles && t >= 0.5 ? other : this;
}

extension AppTextStylesContext on BuildContext {
  /// The style guide text styles for the current theme and language.
  AppTextStyles get textStyles =>
      Theme.of(this).extension<AppTextStyles>() ?? AppTextStyles.english;
}

/// The text styles the existing screens already use, now on the style guide
/// sizes (English). Kept so those screens change without being edited.
abstract final class AppTypography {
  static const display = TextStyle(
    color: AppColors.ink,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const headline = TextStyle(
    color: AppColors.ink,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const screenTitle = TextStyle(
    color: AppColors.ink,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const title = TextStyle(
    color: AppColors.ink,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const subtitle = TextStyle(
    color: AppColors.ink,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    color: AppColors.ink2,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const bodyStrong = TextStyle(
    color: AppColors.ink,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const caption = TextStyle(
    color: AppColors.ink3,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const overline = TextStyle(
    color: AppColors.ink3,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const label = TextStyle(
    color: AppColors.ink,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const button = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const amount = TextStyle(
    color: AppColors.brand700,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
}
