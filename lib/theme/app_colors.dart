import 'package:flutter/material.dart';

/// HomeCare UI Style Guide colors. These are the only colors the app uses.
///
/// Blue always means "you can tap this". Amber is only for rating stars and
/// gentle highlights, never for status. Every text color on its background is
/// 7 to 1 contrast or better (WCAG AAA).
abstract final class AppColors {
  // Brand blue
  static const brand900 = Color(0xFF0B2A5B);
  static const brand700 = Color(0xFF134A96); // main
  static const brand600 = Color(0xFF1B5BB5); // large graphics only
  static const brand100 = Color(0xFFD8E6F7);
  static const brand50 = Color(0xFFEEF4FB);

  // Warm accent: ratings and highlights only
  static const accent500 = Color(0xFFF2A900);
  static const accent700 = Color(0xFF6E4A00);
  static const accent100 = Color(0xFFFFF1C7);

  // Neutrals
  static const bg = Color(0xFFF7F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEEF1F5);
  static const borderSubtle = Color(0xFFD5DBE3); // decoration only
  static const borderControl = Color(0xFF5E6B7B); // inputs and buttons
  static const ink = Color(0xFF101B2B);
  static const ink2 = Color(0xFF344255);
  static const ink3 = Color(0xFF3F4D5E);
  static const focus = Color(0xFF101B2B);

  // Status: always shown with an icon shape and a word, never color alone
  static const successSolid = Color(0xFF005F52);
  static const successSoft = Color(0xFFDCF1EC);
  static const successText = Color(0xFF044B42);

  static const warningSolid = Color(0xFFE69F00);
  static const warningSoft = Color(0xFFFFF1D1);
  static const warningText = Color(0xFF5C3A00);

  static const errorSolid = Color(0xFFA02019);
  static const errorSoft = Color(0xFFFCE3E0);
  static const errorText = Color(0xFF7A1510);

  static const infoSolid = Color(0xFF134A96);
  static const infoSoft = Color(0xFFD8E6F7);
  static const infoText = Color(0xFF0B2A5B);

  static const neutralSolid = Color(0xFF2F3B4B);
  static const neutralSoft = Color(0xFFE6EAF0);
  static const neutralText = Color(0xFF2F3B4B);

  // Overlays (made from the ink colors above)
  static const shadow = Color(0x1A101B2B); // 10% ink
  static const scrim = Color(0x8A344255);

  // ---------------------------------------------------------------------
  // Older names used across the existing screens. They now point at the
  // style guide colors, so every screen changes theme without being edited.
  // New code should use the names above.
  // ---------------------------------------------------------------------
  static const primary = brand700;
  static const primaryDark = brand900;
  static const primarySoft = brand100;
  static const primaryTint = brand50;
  static const accentMint = brand100;

  static const background = bg;
  static const surfaceLavender = surfaceAlt;
  static const surfaceLavenderDeep = brand100;
  static const surfaceSage = surfaceAlt;

  static const navy = ink;
  static const body = ink2;
  static const muted = ink3;
  static const subtle = ink3;
  static const border = borderSubtle;
  static const divider = borderSubtle;

  static const danger = errorSolid;
  static const dangerSoft = errorSoft;
  static const warning = warningText;
  static const warningBorder = warningSolid;
  static const success = successSolid;
  static const star = accent700;
  static const peach = accent100;
}

/// Colors of the login and role selection screens. The names are kept, but
/// they now come from the style guide palette (they used to be teal).
abstract final class AuthColors {
  static const background = AppColors.bg;
  static const surface = AppColors.surface;
  static const primary = AppColors.brand700;
  static const primaryPressed = AppColors.brand900;
  static const heroStart = AppColors.brand900;
  static const heroEnd = AppColors.brand700;
  static const focusedFill = AppColors.brand50;
  static const mintBorder = AppColors.brand100; // soft blue now
  static const heading = AppColors.ink;
  static const secondary = AppColors.ink3;
  static const placeholder = AppColors.ink3;
  static const fieldBorder = AppColors.borderControl;
  static const error = AppColors.errorSolid;
  static const errorFill = AppColors.errorSoft;
  static const errorBorder = AppColors.errorSolid;
  static const onPrimary = AppColors.surface;

  static const cardShadow = AppColors.shadow;
  static const buttonShadow = Color(0x40134A96); // brand 700 at 25%
  static const focusGlow = Color(0x33134A96); // brand 700 at 20%
}
