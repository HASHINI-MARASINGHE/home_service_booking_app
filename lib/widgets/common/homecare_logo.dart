import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The official vector mark of the HomeCare brand:
/// A gable roof with a chimney on the right, rounded U-shaped walls,
/// and a centered diamond spark window.
class HomeCareMarkPainter extends CustomPainter {
  const HomeCareMarkPainter({
    this.color = AppColors.brand700,
    this.strokeWidthFactor = 0.082,
  });

  final Color color;
  final double strokeWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * strokeWidthFactor;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Gable roof with chimney on the right slope:
    // Left eave: (0.22 * w, 0.44 * h)
    // Peak: (0.50 * w, 0.22 * h)
    // Right slope descends to chimney junction: (0.64 * w, 0.33 * h)
    // Chimney: up to (0.64 * w, 0.23 * h), across to (0.72 * w, 0.23 * h), down to (0.72 * w, 0.39 * h)
    // Right eave: (0.78 * w, 0.44 * h)
    final roofPath = Path();
    roofPath.moveTo(w * 0.22, h * 0.44);
    roofPath.lineTo(w * 0.50, h * 0.22);
    roofPath.lineTo(w * 0.64, h * 0.33);
    roofPath.lineTo(w * 0.64, h * 0.23);
    roofPath.lineTo(w * 0.72, h * 0.23);
    roofPath.lineTo(w * 0.72, h * 0.39);
    roofPath.lineTo(w * 0.78, h * 0.44);
    canvas.drawPath(roofPath, strokePaint);

    // 2. House walls: rounded U-shape container below the roof
    final wallsPath = Path();
    wallsPath.moveTo(w * 0.30, h * 0.49);
    wallsPath.lineTo(w * 0.30, h * 0.65);
    wallsPath.quadraticBezierTo(w * 0.30, h * 0.77, w * 0.50, h * 0.77);
    wallsPath.quadraticBezierTo(w * 0.70, h * 0.77, w * 0.70, h * 0.65);
    wallsPath.lineTo(w * 0.70, h * 0.49);
    canvas.drawPath(wallsPath, strokePaint);

    // 3. Centered diamond spark inside the house
    final diamondPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final diamondPath = Path();
    diamondPath.moveTo(w * 0.50, h * 0.45);
    diamondPath.lineTo(w * 0.565, h * 0.515);
    diamondPath.lineTo(w * 0.50, h * 0.58);
    diamondPath.lineTo(w * 0.435, h * 0.515);
    diamondPath.close();
    canvas.drawPath(diamondPath, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant HomeCareMarkPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidthFactor != oldDelegate.strokeWidthFactor;
}

/// The standalone HomeCare brand icon, optionally embedded inside
/// a soft rounded card matching the reference design.
class HomeCareBrandMark extends StatelessWidget {
  const HomeCareBrandMark({
    super.key,
    this.size = 72,
    this.color = AppColors.brand700,
    this.backgroundColor = AppColors.surface,
    this.showCard = true,
  });

  final double size;
  final Color color;
  final Color backgroundColor;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HomeCareMarkPainter(color: color),
      ),
    );

    if (!showCard) return mark;

    final cardSize = size * 1.35;
    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(cardSize * 0.28),
        border: Border.all(
          color: AppColors.brand100.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand700.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: mark,
    );
  }
}

/// The complete HomeCare brand logo with wordmark and optional tagline.
class HomeCareLogo extends StatelessWidget {
  const HomeCareLogo({
    super.key,
    this.markSize = 64,
    this.titleSize = 30,
    this.showTagline = true,
    this.taglineSize = 11,
    this.horizontal = false,
    this.color = AppColors.brand700,
    this.darkTextColor = AppColors.ink,
    this.taglineColor = AppColors.ink3,
    this.showCard = true,
  });

  final double markSize;
  final double titleSize;
  final bool showTagline;
  final double taglineSize;
  final bool horizontal;
  final Color color;
  final Color darkTextColor;
  final Color taglineColor;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final wordmark = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Home',
            style: TextStyle(
              color: darkTextColor,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          TextSpan(
            text: 'Care',
            style: TextStyle(
              color: color,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeCareBrandMark(
            size: markSize,
            color: color,
            showCard: showCard,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordmark,
              if (showTagline) ...[
                const SizedBox(height: 2),
                Text(
                  'HOME SERVICES & MAINTENANCE',
                  style: TextStyle(
                    color: taglineColor,
                    fontSize: taglineSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HomeCareBrandMark(
          size: markSize,
          color: color,
          showCard: showCard,
        ),
        SizedBox(height: markSize * 0.28),
        wordmark,
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'HOME SERVICES & MAINTENANCE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: taglineColor,
              fontSize: taglineSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
