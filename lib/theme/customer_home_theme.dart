import 'app_colors.dart';

/// Older color names used by the customer screens. They now point at the
/// style guide colors in [AppColors]; new code should use those directly.
abstract final class CustomerHomeTheme {
  static const background = AppColors.bg;
  static const primary = AppColors.brand700;
  static const primaryDark = AppColors.brand900;
  static const mint = AppColors.brand100; // soft selected fill (now blue)
  static const border = AppColors.borderSubtle;
  static const text = AppColors.ink;
  static const mutedText = AppColors.ink3;
  static const shadow = AppColors.shadow;
}
