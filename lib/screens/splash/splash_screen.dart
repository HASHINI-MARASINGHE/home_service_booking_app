import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../widgets/common/homecare_logo.dart';

/// Professional HomeCare Splash / Loading Screen.
///
/// Features:
/// - Clean light background with subtle soft radial brand tint
/// - Official HomeCare vector brand card & wordmark in center
/// - "HOME SERVICES & MAINTENANCE" tagline
/// - Smooth animated progress indicator with "INITIALIZING" label
/// - "✓ Verified Technicians • Sri Lanka" trust badge at bottom
/// - Safe area handling with responsive scrolling support for all form factors
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onInitialized,
    this.minDuration = const Duration(milliseconds: 1400),
  });

  /// Optional callback invoked when the splash duration finishes.
  final VoidCallback? onInitialized;

  /// Minimum time the splash screen displays before calling [onInitialized].
  final Duration minDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    if (widget.onInitialized != null) {
      if (widget.minDuration == Duration.zero) {
        widget.onInitialized!();
      } else {
        _completeTimer = Timer(widget.minDuration, () {
          if (mounted) widget.onInitialized!();
        });
      }
    }
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFCFF),
              Colors.white,
              Color(0xFFF6F9FD),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),
                          // Animated Center Logo & Wordmark
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: const HomeCareLogo(
                                markSize: 56,
                                titleSize: 32,
                                showTagline: true,
                                taglineSize: 11,
                                showCard: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 38),
                          // Subtle loading progress indicator
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: AnimatedBuilder(
                                      animation: _progressAnimation,
                                      builder: (context, _) {
                                        return LinearProgressIndicator(
                                          value: _progressAnimation.value < 0.05
                                              ? null
                                              : _progressAnimation.value,
                                          minHeight: 3.2,
                                          backgroundColor: AppColors.brand100
                                              .withValues(alpha: 0.7),
                                          valueColor:
                                              const AlwaysStoppedAnimation<Color>(
                                            AppColors.brand700,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'INITIALIZING',
                                  style: TextStyle(
                                    color: AppColors.ink3,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 4),
                          // Bottom trust & brand message
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand50,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.brand700
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.shieldCheck,
                                    color: AppColors.brand700,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Verified Technicians • Sri Lanka',
                                  style: TextStyle(
                                    color: AppColors.ink2,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
