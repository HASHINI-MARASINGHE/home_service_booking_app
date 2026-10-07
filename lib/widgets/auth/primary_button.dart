import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Full-width 52px teal button. While [loading] it shows a spinner and
/// [loadingLabel] and ignores taps, so a request cannot be sent twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
  });

  final String label;
  final String? loadingLabel;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      // Loading keeps the full teal; only a truly disabled button fades.
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? AuthColors.primaryPressed
            : states.contains(WidgetState.disabled) && !loading
            ? AuthColors.primary.withValues(alpha: 0.45)
            : AuthColors.primary,
      ),
      foregroundColor: const WidgetStatePropertyAll(AuthColors.onPrimary),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AuthColors.buttonShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        style: style,
        onPressed: loading ? null : onPressed,
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AuthColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loadingLabel ?? label),
                ],
              )
            : Text(label),
      ),
    );
  }
}
