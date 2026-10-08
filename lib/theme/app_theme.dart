import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

// Existing screens import everything from here, so the token files are
// re-exported.
export 'app_colors.dart';
export 'app_motion.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// The HomeCare Material 3 theme, built only from the style guide tokens.
abstract final class AppTheme {
  /// English theme with the phone's default font. Used where no language is
  /// known (and in tests, where no font can be downloaded).
  static ThemeData get light => build(const Locale('en'));

  /// The theme for [locale] with Atkinson Hyperlegible (English) or Noto
  /// Sans Sinhala (Sinhala), and the other font as fallback for mixed text.
  static ThemeData forLocale(Locale locale) {
    final sinhala = locale.languageCode == 'si';
    final primary = sinhala
        ? GoogleFonts.notoSansSinhala()
        : GoogleFonts.atkinsonHyperlegible();
    final other = sinhala
        ? GoogleFonts.atkinsonHyperlegible()
        : GoogleFonts.notoSansSinhala();
    return build(
      locale,
      fontFamily: primary.fontFamily,
      fontFallback: [if (other.fontFamily != null) other.fontFamily!],
    );
  }

  static ThemeData build(
    Locale locale, {
    String? fontFamily,
    List<String> fontFallback = const [],
  }) {
    final base = AppTextStyles.forLocale(locale);
    final styles = fontFamily == null
        ? base
        : base.withFont(fontFamily, fontFallback);
    final textTheme = styles.toTextTheme();

    const scheme = ColorScheme.light(
      primary: AppColors.brand700,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.brand100,
      onPrimaryContainer: AppColors.brand900,
      secondary: AppColors.brand700,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.brand100,
      onSecondaryContainer: AppColors.brand900,
      tertiary: AppColors.accent700,
      onTertiary: AppColors.surface,
      tertiaryContainer: AppColors.accent100,
      onTertiaryContainer: AppColors.accent700,
      error: AppColors.errorSolid,
      onError: AppColors.surface,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.errorText,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.ink3,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.bg,
      surfaceContainer: AppColors.surfaceAlt,
      surfaceContainerHigh: AppColors.surfaceAlt,
      surfaceContainerHighest: AppColors.surfaceAlt,
      outline: AppColors.borderControl,
      outlineVariant: AppColors.borderSubtle,
      shadow: AppColors.ink,
      scrim: AppColors.ink2,
      surfaceTint: Colors.transparent,
    );

    // A thick outline that shows where the keyboard focus is.
    const focusSide = BorderSide(color: AppColors.focus, width: 3);

    OutlineInputBorder field(Color color, double width) => OutlineInputBorder(
      borderRadius: AppRadius.field,
      borderSide: BorderSide(color: color, width: width),
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.button);
    const buttonSize = Size(AppSizes.minTap, AppSizes.buttonHeight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      textTheme: textTheme,
      extensions: [styles],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: const IconThemeData(
        size: AppSizes.iconButton,
        color: AppColors.ink2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: styles.h3,
        iconTheme: const IconThemeData(
          size: AppSizes.iconButton,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(
            color: AppColors.borderSubtle,
            width: AppSizes.borderControl,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        // The label is always visible, never only a hint.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: styles.label,
        floatingLabelStyle: styles.label.copyWith(color: AppColors.ink),
        hintStyle: styles.bodyLarge.copyWith(color: AppColors.ink3),
        helperStyle: styles.caption,
        errorStyle: styles.caption.copyWith(
          color: AppColors.errorText,
          fontWeight: FontWeight.w700,
        ),
        errorMaxLines: 3,
        prefixIconColor: AppColors.ink2,
        suffixIconColor: AppColors.ink2,
        // 14 + 28 line + 14 = a 56 px tall field.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: field(AppColors.borderControl, AppSizes.borderControl),
        enabledBorder: field(AppColors.borderControl, AppSizes.borderControl),
        disabledBorder: field(AppColors.borderSubtle, AppSizes.borderControl),
        focusedBorder: field(AppColors.brand700, AppSizes.borderSelected),
        errorBorder: field(AppColors.errorSolid, AppSizes.borderControl),
        focusedErrorBorder: field(
          AppColors.errorSolid,
          AppSizes.borderSelected,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.brand700,
        selectionColor: AppColors.brand700.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.brand700,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(styles.button),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.surfaceAlt
                : states.contains(WidgetState.pressed)
                ? AppColors.brand900
                : AppColors.brand700,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.ink3
                : AppColors.surface,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? focusSide
                : states.contains(WidgetState.disabled)
                ? const BorderSide(
                    color: AppColors.borderSubtle,
                    width: AppSizes.borderControl,
                  )
                : BorderSide.none,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(styles.button),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? AppColors.brand50
                : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.ink3
                : AppColors.brand700,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? focusSide
                : BorderSide(
                    color: states.contains(WidgetState.disabled)
                        ? AppColors.borderSubtle
                        : AppColors.brand700,
                    width: AppSizes.borderControl,
                  ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTap, AppSizes.minTap),
          ),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(styles.label),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.ink3
                : states.contains(WidgetState.pressed)
                ? AppColors.brand900
                : AppColors.brand700,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused) ? focusSide : null,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.brand50.withValues(alpha: 0.6),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
          iconSize: AppSizes.iconButton,
          foregroundColor: AppColors.ink,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
          side: const BorderSide(
            color: AppColors.borderSubtle,
            width: AppSizes.borderControl,
          ),
        ),
        titleTextStyle: styles.h3,
        contentTextStyle: styles.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: styles.bodySmall.copyWith(color: AppColors.surface),
        actionTextColor: AppColors.brand100,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.scrim,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheetRadius),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.nav,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brand100,
        // Labels are always shown: an icon alone is not enough.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.iconButton,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand700
                : AppColors.ink2,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => styles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand700
                : AppColors.ink2,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand700,
        circularTrackColor: AppColors.brand100,
        linearTrackColor: AppColors.brand100,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.brand700 : null,
        ),
        side: const BorderSide(
          color: AppColors.borderControl,
          width: AppSizes.borderControl,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand700
              : AppColors.borderControl,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.surface
              : AppColors.borderControl,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand700
              : AppColors.surfaceAlt,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(
          AppColors.borderControl,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.ink2,
        textColor: AppColors.ink,
        titleTextStyle: styles.bodyLarge,
        subtitleTextStyle: styles.bodySmall,
        minVerticalPadding: AppSpacing.xs,
      ),
    );
  }
}
