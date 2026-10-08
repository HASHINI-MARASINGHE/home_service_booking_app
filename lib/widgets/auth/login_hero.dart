import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';
import '../common/homecare_logo.dart';

/// Blue header of the auth screens. Collapses to a 72px bar with only the
/// logo while the keyboard is open.
class LoginHero extends StatelessWidget {
  const LoginHero({
    super.key,
    required this.height,
    this.compact = false,
    this.illustrationHeight = 144,
    this.onBack,
  });

  static const floatingIcons = 'assets/images/login/login_floating_icons.png';
  static const illustration = 'assets/images/login/login_hero_illustration.png';
  static const duration = Duration(milliseconds: 200);

  /// Total height, including the status bar inset.
  final double height;
  final bool compact;
  final double illustrationHeight;

  /// Shows a white back arrow before the logo when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final logoSize = compact ? 32.0 : 40.0;
    final logoTop = topInset + (compact ? (72 - logoSize) / 2 : 28);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthColors.heroStart, AuthColors.heroEnd],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(compact ? 24 : 32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative layers are hidden from screen readers.
          Positioned.fill(
            child: ExcludeSemantics(
              child: AnimatedOpacity(
                duration: duration,
                opacity: compact ? 0 : 1,
                child: Image.asset(floatingIcons, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: ExcludeSemantics(
              child: AnimatedOpacity(
                duration: duration,
                opacity: compact ? 0 : 1,
                child: Image.asset(illustration, height: illustrationHeight),
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              left: 8,
              top: logoTop + (logoSize - 48) / 2,
              child: IconButton(
                key: const ValueKey('hero-back'),
                onPressed: onBack,
                tooltip: 'Back',
                color: AuthColors.onPrimary,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: const Icon(LucideIcons.arrowLeft, size: 24),
              ),
            ),
          AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOut,
            left: onBack == null ? 24 : 60,
            top: logoTop,
            child: Semantics(
              header: true,
              label: 'HomeCare',
              excludeSemantics: true,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: duration,
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: AuthColors.surface,
                      borderRadius: BorderRadius.circular(compact ? 8 : 10),
                    ),
                    alignment: Alignment.center,
                    child: HomeCareBrandMark(
                      size: logoSize * 0.72,
                      color: AuthColors.primary,
                      showCard: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: TextStyle(
                      color: AuthColors.onPrimary,
                      fontSize: compact ? 20 : 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    child: const Text('HomeCare'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
