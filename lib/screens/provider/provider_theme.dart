import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Older color names used by the provider screens. They now point at the
/// style guide colors in [AppColors]; new code should use those directly.
/// (`teal` and `tealLight` keep their names but are the brand blue.)
abstract final class ProviderTheme {
  static const muted = AppColors.ink3;
  static const teal = AppColors.brand700;
  static const surface = AppColors.surface;
  static const navy = AppColors.ink;
  static const body = AppColors.ink;
  static const background = AppColors.bg;
  static const tealLight = AppColors.brand100;
  static const border = AppColors.borderSubtle;
  static const orangeBorder = AppColors.warningSolid;
  static const warningBackground = AppColors.warningSoft;
  static const grey = AppColors.neutralText;
  static const orange = AppColors.warningText;
  static const green = AppColors.successSolid;
  static const red = AppColors.errorSolid;

  /// Same theme as the rest of the app.
  static ThemeData get data => AppTheme.light;
}
