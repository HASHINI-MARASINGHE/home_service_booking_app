import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale from the style guide: 4, 8, 12, 16, 20, 24, 32, 40, 48.
abstract final class AppSpacing {
  static const space1 = 4.0; // icon to text
  static const space2 = 8.0; // tight groups
  static const space3 = 12.0; // gap between buttons
  static const space4 = 16.0; // inside cards
  static const space5 = 20.0; // screen side margin
  static const space6 = 24.0; // between cards
  static const space8 = 32.0; // between sections
  static const space10 = 40.0; // big gaps
  static const space12 = 48.0; // empty states

  // Names used by the existing screens.
  static const xxs = space1;
  static const xs = space2;
  static const sm = space3;
  static const md = space4;
  static const lg = space5;
  static const xl = space6;
  static const xxl = space8;

  /// Horizontal gutter used by every screen.
  static const screen = space5;
}

/// Radius scale: 12 buttons and inputs, 16 cards, 24 sheets.
abstract final class AppRadius {
  static const controlRadius = 12.0;
  static const cardRadius = 16.0;
  static const sheetRadius = 24.0;

  // Numbers used by the existing screens.
  static const sm = controlRadius;
  static const md = controlRadius;
  static const lg = cardRadius;
  static const xl = sheetRadius;
  static const pill = 999.0;

  // Ready-made shapes used by the existing screens.
  static final card = BorderRadius.circular(cardRadius);
  static final button = BorderRadius.circular(controlRadius);
  static final field = BorderRadius.circular(controlRadius);
  static final sheet = BorderRadius.circular(sheetRadius);
  static final chip = BorderRadius.circular(pill);
}

/// Touch and size rules from the style guide.
abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const inputHeight = 56.0;

  /// Smallest tap area: even a small icon gets this much room.
  static const minTap = 48.0;
  static const iconButton = 24.0;
  static const iconNav = 28.0;
  static const nav = 72.0;

  /// Lines on controls are thick so they are easy to see.
  static const borderControl = 2.0;
  static const borderSelected = 4.0;

  /// Smallest text size allowed anywhere.
  static const minText = 14.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const soft = [
    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Bars and dialogs only: 0 -4 16 at 10% ink.
  static const bar = [
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4)),
  ];
}
