import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The two blues of the HomeCare logo (top left to bottom right).
const _tileStart = Color(0xFF2F6BD1);
const _tileEnd = Color(0xFF0E2E6E);
const _heartEnd = Color(0xFF143C85);

// The logo is drawn in a 1024 x 1024 box (see design/app_icon). The house is
// a rounded gable shape with a heart cut out of its middle.
Path _house() => Path()
  ..moveTo(512, 215)
  ..lineTo(842, 495)
  ..quadraticBezierTo(850, 502, 850, 512)
  ..lineTo(850, 770)
  ..quadraticBezierTo(850, 810, 810, 810)
  ..lineTo(214, 810)
  ..quadraticBezierTo(174, 810, 174, 770)
  ..lineTo(174, 512)
  ..quadraticBezierTo(174, 502, 182, 495)
  ..close();

Path _heart() => Path()
  ..moveTo(512, 690)
  ..cubicTo(420, 620, 380, 575, 380, 525)
  ..cubicTo(380, 485, 410, 458, 445, 458)
  ..cubicTo(475, 458, 497, 474, 512, 498)
  ..cubicTo(527, 474, 549, 458, 579, 458)
  ..cubicTo(614, 458, 644, 485, 644, 525)
  ..cubicTo(644, 575, 604, 620, 512, 690)
  ..close();

/// Just the house with its heart cut out, in one [color]. Use it on a colored
/// background (it fills the box, so leave some space around it).
class HomeCareMarkPainter extends CustomPainter {
  const HomeCareMarkPainter({this.color = AppColors.brand700});

  final Color color;

  // The house spans x 174..850 and y 215..810 of the 1024 box.
  static const _width = 676.0;
  static const _height = 595.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _width;
    canvas
      ..translate(
        -174 * scale,
        (size.height - _height * scale) / 2 - 215 * scale,
      )
      ..scale(scale);
    canvas.drawPath(
      Path.combine(PathOperation.difference, _house(), _heart()),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant HomeCareMarkPainter old) => color != old.color;
}

/// The full logo: the blue circle of the app icon with the white house and its
/// heart.
class _HomeCareTilePainter extends CustomPainter {
  const _HomeCareTilePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);
    const bounds = Rect.fromLTWH(0, 0, 1024, 1024);
    canvas.drawCircle(
      const Offset(512, 512),
      512,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_tileStart, _tileEnd],
        ).createShader(bounds),
    );
    // The house is drawn at 78% around the centre, as in the app icon.
    canvas
      ..translate(512, 512)
      ..scale(0.7825)
      ..translate(-512, -512);
    canvas.drawPath(_house(), Paint()..color = Colors.white);
    canvas.drawPath(
      _heart(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_tileStart, _heartEnd],
        ).createShader(const Rect.fromLTRB(380, 458, 644, 690)),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeCareTilePainter old) => false;
}

/// The HomeCare brand icon. With [showCard] it is the app icon itself (a blue
/// circle, [size] * 1.35 wide); without it, just the white-on-nothing
/// house glyph in [color], [size] wide, to place on your own background.
class HomeCareBrandMark extends StatelessWidget {
  const HomeCareBrandMark({
    super.key,
    this.size = 72,
    this.color = AppColors.brand700,
    this.showCard = true,
    this.shadow = true,
  });

  final double size;
  final Color color;
  final bool showCard;

  /// A soft shadow under the tile; turn off in small places such as bars.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    if (!showCard) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: HomeCareMarkPainter(color: color)),
      );
    }
    final tile = size * 1.35;
    return Container(
      width: tile,
      height: tile,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: _tileEnd.withValues(alpha: 0.25),
                  blurRadius: tile * 0.3,
                  offset: Offset(0, tile * 0.1),
                ),
              ]
            : null,
      ),
      child: const CustomPaint(painter: _HomeCareTilePainter()),
    );
  }
}

/// The complete HomeCare logo: icon, wordmark and tagline.
class HomeCareLogo extends StatelessWidget {
  const HomeCareLogo({
    super.key,
    this.markSize = 64,
    this.titleSize = 30,
    this.showTagline = true,
    this.taglineSize = 11,
    this.horizontal = false,
    this.color = AppColors.brand700,
    this.darkTextColor = AppColors.brand900,
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

  static const tagline = 'TRUSTED HOME SERVICES';

  @override
  Widget build(BuildContext context) {
    final wordmark = HomeCareWordmark(
      size: titleSize,
      homeColor: darkTextColor,
      careColor: color,
    );
    final tag = Text(
      tagline,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        color: taglineColor,
        fontSize: taglineSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeCareBrandMark(size: markSize, color: color, showCard: showCard),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordmark,
              if (showTagline) ...[const SizedBox(height: 2), tag],
            ],
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeCareBrandMark(size: markSize, color: color, showCard: showCard),
        SizedBox(height: markSize * 0.28),
        wordmark,
        if (showTagline) ...[const SizedBox(height: 6), tag],
      ],
    );
  }
}

/// "HomeCare" with Home in dark blue and Care in the brand blue. It uses the
/// app font, so it follows the language setting.
class HomeCareWordmark extends StatelessWidget {
  const HomeCareWordmark({
    super.key,
    this.size = 20,
    this.homeColor = AppColors.brand900,
    this.careColor = AppColors.brand700,
  });

  final double size;
  final Color homeColor, careColor;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Color color) => TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.1,
    );
    return Semantics(
      label: 'HomeCare',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Home', style: style(homeColor)),
            TextSpan(text: 'Care', style: style(careColor)),
          ],
        ),
      ),
    );
  }
}

/// A slim bar with the logo, shown at the top of every page of the app.
class BrandBar extends StatelessWidget {
  const BrandBar({super.key, this.trailing, this.color = AppColors.bg});

  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    // A logo keeps its size: it does not grow with the text size setting.
    child: MediaQuery.withNoTextScaling(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: Row(
          children: [
            const HomeCareBrandMark(size: 25, shadow: false),
            const SizedBox(width: 10),
            const HomeCareWordmark(size: 20),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

/// Puts the [BrandBar] above a whole page (a Scaffold with its own app bar
/// and bottom navigation), so the logo is on every page of a role without
/// each screen having to add it.
class BrandShell extends StatelessWidget {
  const BrandShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.bg,
    child: Column(
      children: [
        SafeArea(bottom: false, child: const BrandBar()),
        // The bar already sits below the status bar; the page must not leave
        // a second gap for it.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    ),
  );
}
