import 'package:flutter/material.dart';

/// Motion rules: subtle, no flashing, no auto-moving banners, and none at all
/// when the phone asks for reduced motion.
abstract final class AppMotion {
  /// Most transitions.
  static const base = Duration(milliseconds: 200);

  /// Bottom sheets.
  static const sheet = Duration(milliseconds: 300);

  /// Delay between neighbouring list items.
  static const stagger = Duration(milliseconds: 40);

  static const curve = Curves.easeOut;
  static const sheetCurve = Curves.easeInOut;

  /// Pressed buttons and cards shrink slightly.
  static const pressedScale = 0.97;

  /// How far a list item slides up while it fades in.
  static const slideDistance = 12.0;

  /// True when every animation must be skipped.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [base], or no time at all when motion is reduced.
  static Duration duration(BuildContext context) =>
      reduced(context) ? Duration.zero : base;
}
