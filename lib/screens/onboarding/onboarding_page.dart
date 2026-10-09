import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/app_colors.dart';

abstract final class OnboardingStyle {
  static const teal = AppColors.brand700; // primary brand blue
  static const navy = AppColors.ink;
  static const muted = AppColors.ink3;
  static const background = Color(0xFFF7FAFD);
  static const white = AppColors.surface;
  static const lightTeal = AppColors.brand50; // soft brand tint
  static const border = AppColors.borderSubtle;

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal,
      primary: teal,
      surface: white,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: teal,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: white,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    this.pageIndex = 0,
    this.imageAsset,
    this.imageAspectRatio,
    this.imageAlignment = Alignment.center,
    this.showExperiences = false,
  });

  final int pageIndex;
  final String title, description;
  final String? imageAsset;
  final double? imageAspectRatio;
  final Alignment imageAlignment;
  final bool showExperiences;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxHeight < 680 || constraints.maxWidth < 360;
      final imageHeight = isCompact
          ? (constraints.maxHeight * 0.38).clamp(160.0, 220.0)
          : (constraints.maxHeight * 0.44).clamp(200.0, 300.0);

      final verticalPadding = isCompact ? 10.0 : 16.0;

      return Center(
        child: SingleChildScrollView(
          key: PageStorageKey(title),
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - (verticalPadding * 2)).clamp(0.0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showExperiences)
                    _ExperienceCards(isCompact: isCompact)
                  else
                    _HeroImageCard(
                      pageIndex: pageIndex,
                      imageAsset: imageAsset!,
                      imageHeight: imageHeight,
                      imageAlignment: imageAlignment,
                      isCompact: isCompact,
                    ),
                  SizedBox(height: isCompact ? 16 : 24),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: OnboardingStyle.navy,
                        fontSize: isCompact ? 24 : 27,
                        fontWeight: FontWeight.w800,
                        height: 1.20,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: OnboardingStyle.muted,
                        fontSize: isCompact ? 13.5 : 14.5,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _HeroImageCard extends StatelessWidget {
  const _HeroImageCard({
    required this.pageIndex,
    required this.imageAsset,
    required this.imageHeight,
    required this.imageAlignment,
    required this.isCompact,
  });

  final int pageIndex;
  final String imageAsset;
  final double imageHeight;
  final Alignment imageAlignment;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.locale.languageCode;
    final isSinhala = lang == 'si';
    final isTamil = lang == 'ta';

    // Build the core image card
    Widget imageCard = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand700.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          imageAsset,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: imageAlignment,
          excludeFromSemantics: true,
        ),
      ),
    );


    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Screen 2: Dashed arc decoration behind the card
          if (pageIndex == 1)
            Positioned(
              top: -24,
              right: -16,
              width: imageHeight * 0.75,
              height: imageHeight * 0.75,
              child: const CustomPaint(
                painter: _DashedArcPainter(),
              ),
            ),

          imageCard,

          // Screen 1: Floating badge at bottom-left
          if (pageIndex == 0)
            Positioned(
              left: 14,
              bottom: -16,
              child: _FloatingBadge(
                icon: Icons.verified_rounded,
                title: isTamil
                    ? 'சரிபார்க்கப்பட்ட நிபுணர்கள்'
                    : (isSinhala
                        ? 'සත්‍යාපිත වෘත්තිකයන්'
                        : 'Verified Pros'),
                subtitle: isTamil
                    ? '500+ உள்ளூர் நிபுணர்கள்'
                    : (isSinhala
                        ? '500+ දේශීය විශේෂඥයින්'
                        : '500+ Local Experts'),
                isCompact: isCompact,
              ),
            ),

          // Screen 2: Floating badge at top-right
          if (pageIndex == 1)
            Positioned(
              right: 14,
              top: -14,
              child: _FloatingBadge(
                icon: Icons.verified_user_rounded,
                title: isTamil
                    ? 'சரிபார்க்கப்பட்ட வழங்குநர்'
                    : (isSinhala
                        ? 'සත්‍යාපිත සේවාදායකයා'
                        : 'Verified Provider'),
                subtitle: isTamil
                    ? '4.9 (1.2k+ பணிகள்)'
                    : (isSinhala
                        ? '4.9 (සේවා 1.2k+)'
                        : '4.9 (1.2k+ jobs)'),
                hasRatingStar: true,
                isCompact: isCompact,
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasRatingStar = false,
    this.isCompact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasRatingStar;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand700.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brand700,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isCompact ? 15 : 17,
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasRatingStar) ...[
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.ink3,
                      fontSize: isCompact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Screen 3: Two side-by-side photos at the top with a connection circle,
/// then a single white card below with "For Customers" / "For Providers"
/// step columns — matching the reference design.
class _ExperienceCards extends StatelessWidget {
  const _ExperienceCards({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.locale.languageCode;
    final isSinhala = lang == 'si';
    final isTamil = lang == 'ta';

    final forCustomersLabel = isTamil
        ? 'வாடிக்கையாளர்களுக்கு'
        : isSinhala
            ? 'පාරිභෝගිකයන් සඳහා'
            : 'For Customers';
    final forProvidersLabel = isTamil
        ? 'சேவை வழங்குநர்களுக்கு'
        : isSinhala
            ? 'සේවා සපයන්නන් සඳහා'
            : 'For Providers';

    final photoHeight = isCompact ? 110.0 : 138.0;

    return Column(
      children: [
        // --- Top: Two side-by-side photos with connection circle ---
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand700.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/onboarding_customer.jpg',
                        height: photoHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.9),
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand700.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/onboarding_provider.jpg',
                        height: photoHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -1.0),
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Blue connection circle at intersection
            Positioned(
              bottom: -14,
              child: Container(
                width: isCompact ? 30 : 34,
                height: isCompact ? 30 : 34,
                decoration: BoxDecoration(
                  color: AppColors.brand700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand700.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: isCompact ? 16 : 18,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isCompact ? 22 : 28),

        // --- Steps card: two columns ---
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OnboardingStyle.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand700.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 14 : 18,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: For Customers
                Expanded(
                  child: _StepsColumn(
                    title: forCustomersLabel,
                    isCompact: isCompact,
                    steps: [
                      (
                        Icons.search_rounded,
                        isTamil
                            ? 'சேவையைத் தேடு'
                            : isSinhala
                                ? 'සේවාව සොයන්න'
                                : 'Find Service',
                      ),
                      (
                        Icons.calendar_today_outlined,
                        isTamil
                            ? 'முன்பதிவு செய்'
                            : isSinhala
                                ? 'වෙන්කරන්න'
                                : 'Book',
                      ),
                      (
                        Icons.check_circle_outline_rounded,
                        isTamil
                            ? 'சேவை நிறைவு'
                            : isSinhala
                                ? 'සේවාව නිමයි'
                                : 'Service Completed',
                      ),
                    ],
                  ),
                ),
                // Right: For Providers
                Expanded(
                  child: _StepsColumn(
                    title: forProvidersLabel,
                    isCompact: isCompact,
                    steps: [
                      (
                        Icons.notifications_none_rounded,
                        isTamil
                            ? 'கோரிக்கையைப் பெறு'
                            : isSinhala
                                ? 'ඉල්ලීම ලබාගන්න'
                                : 'Receive Request',
                      ),
                      (
                        Icons.task_alt_rounded,
                        isTamil
                            ? 'ஏற்றுக்கொள்'
                            : isSinhala
                                ? 'පිළිගන්න'
                                : 'Accept Job',
                      ),
                      (
                        Icons.payments_outlined,
                        isTamil
                            ? 'நிறைவு செய்து சம்பாதி'
                            : isSinhala
                                ? 'නිමකර උපයන්න'
                                : 'Complete & Earn',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepsColumn extends StatelessWidget {
  const _StepsColumn({
    required this.title,
    required this.steps,
    required this.isCompact,
  });

  final String title;
  final List<(IconData, String)> steps;
  final bool isCompact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: OnboardingStyle.navy,
          fontSize: isCompact ? 12.5 : 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: isCompact ? 10 : 14),
      for (var i = 0; i < steps.length; i++) ...[
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(
                color: OnboardingStyle.lightTeal,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                steps[i].$1,
                size: isCompact ? 13 : 14,
                color: OnboardingStyle.teal,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                steps[i].$2,
                style: TextStyle(
                  color: OnboardingStyle.navy,
                  fontSize: isCompact ? 11 : 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (i < steps.length - 1)
          Padding(
            padding: EdgeInsets.only(
              left: isCompact ? 9 : 10,
              top: isCompact ? 3 : 4,
              bottom: isCompact ? 3 : 4,
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              size: 11,
              color: AppColors.ink3,
            ),
          ),
      ],
    ],
  );
}

/// Draws a decorative dashed arc for Screen 2's background
class _DashedArcPainter extends CustomPainter {
  const _DashedArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brand700.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const dashLen = 6.0;
    const gapLen = 5.0;
    const totalSweep = 4.5;
    const startAngle = -1.2;

    var angle = startAngle;
    final end = startAngle + totalSweep;
    while (angle < end) {
      final sweep = (dashLen / radius).clamp(0.0, end - angle);
      canvas.drawArc(rect, angle, sweep, false, paint);
      angle += sweep + gapLen / radius;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedArcPainter oldDelegate) => false;
}
