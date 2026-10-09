import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Paints [AppBackdropPainter] behind [child].
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: const AppBackdropPainter(quiet: true),
      child: child,
    ),
  );
}

/// Theme for pages that sit on an [AppBackdrop]: scaffolds and app bars are
/// see-through, and a page fades the one below it out while it comes in, so
/// two see-through pages never show through each other.
ThemeData backdropTheme(ThemeData base) => base.copyWith(
  scaffoldBackgroundColor: Colors.transparent,
  appBarTheme: base.appBarTheme.copyWith(backgroundColor: Colors.transparent),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _CrossfadeTransitions(
        ZoomPageTransitionsBuilder(),
      ),
      TargetPlatform.iOS: _CrossfadeTransitions(
        CupertinoPageTransitionsBuilder(),
      ),
      TargetPlatform.macOS: _CrossfadeTransitions(
        CupertinoPageTransitionsBuilder(),
      ),
      TargetPlatform.windows: _CrossfadeTransitions(
        ZoomPageTransitionsBuilder(),
      ),
      TargetPlatform.linux: _CrossfadeTransitions(ZoomPageTransitionsBuilder()),
      TargetPlatform.fuchsia: _CrossfadeTransitions(
        ZoomPageTransitionsBuilder(),
      ),
    },
  ),
);

class _CrossfadeTransitions extends PageTransitionsBuilder {
  const _CrossfadeTransitions(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    FadeTransition(opacity: ReverseAnimation(secondaryAnimation), child: child),
  );
}

/// The HomeCare background, first made for the onboarding screens:
/// - Light gradient base
/// - Soft organic curves & layered translucent surfaces
/// - Delicate rings with blue accent dots
/// - Subtle roof contour in Screen 1 & gentle flow curves in Screen 2 & 3
class AppBackdropPainter extends CustomPainter {
  const AppBackdropPainter({this.page = 0, this.quiet = false});

  final int page;

  /// Only the gradient and the soft curves, without the rings and the roof
  /// line, for screens full of content.
  final bool quiet;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base gradient
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF7FAFD), Colors.white, Color(0xFFEFF5FC)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Large soft organic blob (top right) – more prominent
    final blobPaint1 = Paint()
      ..color = const Color(0xFFDBEAFA).withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;
    final path1 = Path();
    path1.moveTo(w * 0.30, 0);
    path1.quadraticBezierTo(w * 0.65, h * 0.12, w, h * 0.25);
    path1.lineTo(w, 0);
    path1.close();
    canvas.drawPath(path1, blobPaint1);

    // 3. Sweeping soft curve (middle to bottom) – more prominent
    final blobPaint2 = Paint()
      ..color = const Color(0xFFE4EEFB).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, h * 0.50);
    path2.quadraticBezierTo(w * 0.35, h * 0.40, w, h * 0.58);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, blobPaint2);

    if (quiet) return;

    // 4. Subtle decorative rings with blue dots
    final ringPaint = Paint()
      ..color = AppColors.brand700.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final dotPaint = Paint()
      ..color = AppColors.brand700
      ..style = PaintingStyle.fill;

    // Screen-specific background nuances
    if (page == 0) {
      // Screen 1: Top-left subtle house/roof architectural outline
      final roofPaint = Paint()
        ..color = AppColors.brand700.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final roofPath = Path();
      roofPath.moveTo(w * 0.04, h * 0.22);
      roofPath.lineTo(w * 0.15, h * 0.12);
      roofPath.lineTo(w * 0.28, h * 0.22);
      canvas.drawPath(roofPath, roofPaint);

      // Top-left small ring with accent dot
      final c1 = Offset(w * 0.08, h * 0.19);
      canvas.drawCircle(c1, 5.0, ringPaint);
      canvas.drawCircle(Offset(c1.dx + 4.5, c1.dy - 2.5), 2.0, dotPaint);

      // Mid-right soft circle
      final c2 = Offset(w * 0.88, h * 0.52);
      canvas.drawCircle(c2, 6.0, ringPaint);
    } else if (page == 1) {
      // Screen 2: Top-center gentle wave & ring
      final wavePaint = Paint()
        ..color = AppColors.brand700.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      final wavePath = Path();
      wavePath.moveTo(w * 0.30, h * 0.18);
      wavePath.quadraticBezierTo(w * 0.48, h * 0.14, w * 0.65, h * 0.20);
      canvas.drawPath(wavePath, wavePaint);

      final c1 = Offset(w * 0.44, h * 0.17);
      canvas.drawCircle(c1, 5.0, ringPaint);
      canvas.drawCircle(Offset(c1.dx + 4.0, c1.dy - 3.0), 2.0, dotPaint);
    } else {
      // Screen 3: Middle-right ring with accent dot
      final c1 = Offset(w * 0.94, h * 0.46);
      canvas.drawCircle(c1, 5.5, ringPaint);
      canvas.drawCircle(Offset(c1.dx - 4.5, c1.dy + 3.0), 2.0, dotPaint);

      final c2 = Offset(w * 0.08, h * 0.68);
      canvas.drawCircle(c2, 4.5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AppBackdropPainter oldDelegate) =>
      oldDelegate.page != page || oldDelegate.quiet != quiet;
}
