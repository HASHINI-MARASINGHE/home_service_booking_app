import 'package:flutter/material.dart';

/// HomeCare design tokens shared by the customer booking and address screens.
/// Screens read these instead of hard-coding colors or sizes.
abstract final class AppColors {
  static const primary = Color(0xFF0B7C72);
  static const primaryDark = Color(0xFF075E55);
  static const primarySoft = Color(0xFFDCEBE6);
  static const primaryTint = Color(0xFFE8F3EF);
  static const accentMint = Color(0xFF9FE9DD);

  static const background = Color(0xFFF8F8FE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLavender = Color(0xFFEFF0FB);
  static const surfaceLavenderDeep = Color(0xFFE4E6F8);
  static const surfaceSage = Color(0xFFE6EEEB);

  static const navy = Color(0xFF0F172A);
  static const body = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const subtle = Color(0xFF94A3B8);
  static const border = Color(0xFFE6E8F2);
  static const divider = Color(0xFFE2E8F0);

  static const danger = Color(0xFFC81E1E);
  static const dangerSoft = Color(0xFFFDE3E3);
  static const warning = Color(0xFFA45309);
  static const warningSoft = Color(0xFFFFF1E7);
  static const warningBorder = Color(0xFFFAD9BE);
  static const success = Color(0xFF0B7A5A);
  static const successSoft = Color(0xFFDDF6EA);
  static const star = Color(0xFFB45309);
  static const peach = Color(0xFFFFDCC7);

  static const shadow = Color(0x140F172A);
  static const scrim = Color(0x8A64748B);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal gutter used by every customer screen.
  static const screen = 16.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;

  static final card = BorderRadius.circular(lg);
  static final button = BorderRadius.circular(md);
  static final field = BorderRadius.circular(md);
  static final chip = BorderRadius.circular(pill);
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

abstract final class AppTypography {
  static const display = TextStyle(
    color: AppColors.navy,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  static const headline = TextStyle(
    color: AppColors.navy,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const screenTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    color: AppColors.navy,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static const subtitle = TextStyle(
    color: AppColors.navy,
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    color: AppColors.body,
    fontSize: 14,
    height: 1.4,
  );
  static const bodyStrong = TextStyle(
    color: AppColors.navy,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(
    color: AppColors.muted,
    fontSize: 12.5,
    height: 1.35,
  );
  static const overline = TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
  );
  static const label = TextStyle(
    color: AppColors.navy,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const button = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700);
  static const amount = TextStyle(
    color: AppColors.primary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.field,
      borderSide: const BorderSide(color: AppColors.border),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.screenTitle,
      ),
      textTheme: const TextTheme(
        headlineSmall: AppTypography.headline,
        titleLarge: AppTypography.screenTitle,
        titleMedium: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.border),
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.body.copyWith(color: AppColors.subtle),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        modalBarrierColor: AppColors.scrim,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: const CircleBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.body,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.body,
          ),
        ),
      ),
    );
  }
}
