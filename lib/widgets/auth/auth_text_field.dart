import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';

/// Labelled 52px input used on the login screen. The label and prefix icon
/// follow the field state: teal while focused, red while [errorText] is set.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    this.fieldKey,
    this.hintText,
    this.errorText,
    this.suffix,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final Key? fieldKey;
  final String? hintText;
  final String? errorText;
  final Widget? suffix;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const height = 56.0;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = widget.focusNode.hasFocus && widget.enabled;
    final accent = hasError
        ? AuthColors.error
        : focused
        ? AuthColors.primary
        : null;
    final borderColor = accent ?? AuthColors.fieldBorder;
    final fill = !widget.enabled
        ? AuthColors.background
        : hasError
        ? AuthColors.errorFill
        : focused
        ? AuthColors.focusedFill
        : AuthColors.surface;
    final radius = BorderRadius.circular(AppRadius.controlRadius);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor, width: accent == null ? 2 : 3),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color:
                accent ??
                (widget.enabled ? AuthColors.heading : AuthColors.secondary),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: focused && !hasError
                ? [
                    BoxShadow(
                      color: AuthColors.mintBorder.withValues(alpha: 0.6),
                      spreadRadius: 3,
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: widget.obscureText,
            obscuringCharacter: '•',
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.enabled ? widget.autofillHints : null,
            autocorrect: false,
            enableSuggestions: !widget.obscureText,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: AuthColors.primary,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color: widget.enabled ? AuthColors.heading : AuthColors.secondary,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              constraints: const BoxConstraints.tightFor(
                height: AuthTextField.height,
              ),
              filled: true,
              fillColor: fill,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: AuthColors.placeholder,
                fontSize: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: Icon(
                widget.prefixIcon,
                size: 24,
                color: accent ?? AuthColors.secondary,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              suffixIcon: hasError && widget.suffix == null
                  ? const ExcludeSemantics(
                      child: Icon(
                        LucideIcons.circleAlert,
                        size: 20,
                        color: AuthColors.error,
                      ),
                    )
                  : widget.suffix,
              border: border,
              enabledBorder: border,
              focusedBorder: border,
              disabledBorder: border,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!,
                style: const TextStyle(
                  color: AuthColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
