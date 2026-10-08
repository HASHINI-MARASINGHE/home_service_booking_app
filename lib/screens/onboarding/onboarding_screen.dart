import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/app_colors.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _saving = false;
  bool _moving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save your progress. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    if (_moving || _saving) return;
    if (_page == 2) {
      await _finish();
      return;
    }
    setState(() => _moving = true);
    try {
      await _controller.animateToPage(
        _page + 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.locale.languageCode;
    final isSinhala = lang == 'si';
    final isTamil = lang == 'ta';

    final skipLabel = isTamil
        ? 'தவிர்'
        : isSinhala
            ? 'මඟහරින්න'
            : 'Skip';

    final page1Title = isTamil
        ? 'உங்கள் வீட்டிற்கு பராமரிப்பு,\nமிகவும் எளிதாக.'
        : isSinhala
            ? 'ඔබේ නිවසට සත්කාරය,\nපහසුවෙන්ම.'
            : 'Help for your home,\nmade simple.';
    final page1Desc = isTamil
        ? 'பழுதுபார்ப்பு மற்றும் அன்றாட வீட்டு சேவைகளுக்கு நம்பகமான நிபுணர்களை கண்டறியுங்கள்.'
        : isSinhala
            ? 'අලුත්වැඩියා සහ දෛනික නිවාස සේවා සඳහා විශ්වාසවන්ත වෘත්තිකයන් සොයා ගන්න.'
            : 'Find trusted professionals for repairs,\nmaintenance and everyday home services.';

    final page2Title = isTamil
        ? 'சரியான நிபுணர்களுடன்\nஉங்களை இணைக்கிறது.'
        : isSinhala
            ? 'සුදුසුම පුද්ගලයන් සමඟ\nඔබව සම්බන්ධ කරයි.'
            : 'Connecting you with\nthe right people.';
    final page2Desc = isTamil
        ? 'வாடிக்கையாளர்களுக்கு நம்பகமான உதவி. சேவை வழங்குநர்களுக்கு புதிய வாய்ப்புகள்.'
        : isSinhala
            ? 'පාරිභෝගිකයින්ට විශ්වාසනීය සේවාවක්. සේවා සපයන්නන්ට නව අවස්ථා.'
            : 'Customers find reliable help. Service\nproviders find opportunities to grow.';

    final page3Title = isTamil
        ? 'ஒரே செயலி. பணிகளை முடிக்க\nஇரண்டு வழிகள்.'
        : isSinhala
            ? 'එක් යෙදුමක්. වැඩ පහසු කරන\nක්‍රම දෙකක්.'
            : 'One app. Two ways\nto get things done.';
    final page3Desc = isTamil
        ? 'உங்களுக்குத் தேவையான சேவையைப் பதிவு செய்யுங்கள் அல்லது உங்கள் திறமையால் சேவை வழங்குங்கள்.'
        : isSinhala
            ? 'ඔබට අවශ්‍ය සේවාව වෙන්කරවා ගන්න හෝ ඔබේ කුසලතාවයෙන් සේවය සපයන්න.'
            : 'Book the help you need or provide your skills to\ncustomers who need them.';

    return Theme(
      data: OnboardingStyle.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFD),
        body: Stack(
          children: [
            // Subtle, beautiful organic background matching reference design
            Positioned.fill(
              child: CustomPaint(
                painter: _OnboardingBackgroundPainter(page: _page),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      // Top header: safe area & Skip button
                      SizedBox(
                        height: 52,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _page < 3
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: TextButton(
                                    key: const ValueKey('onboarding-skip'),
                                    onPressed:
                                        _saving || _moving ? null : _finish,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.brand700,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: Text(skipLabel),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),

                      // Main Swipeable Visual Area
                      Expanded(
                        child: PageView(
                          key: const ValueKey('onboarding-pages'),
                          controller: _controller,
                          physics: _saving
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics(),
                          onPageChanged: (page) => setState(() => _page = page),
                          children: [
                            OnboardingPage(
                              pageIndex: 0,
                              title: page1Title,
                              description: page1Desc,
                              imageAsset: 'assets/images/onboarding_home.jpg',
                              imageAlignment: Alignment.topCenter,
                            ),
                            OnboardingPage(
                              pageIndex: 1,
                              title: page2Title,
                              description: page2Desc,
                              imageAsset:
                                  'assets/images/onboarding_connection.jpg',
                              imageAlignment: Alignment.center,
                            ),
                            OnboardingPage(
                              pageIndex: 2,
                              title: page3Title,
                              description: page3Desc,
                              showExperiences: true,
                            ),
                          ],
                        ),
                      ),

                      // Bottom Controls: Page Indicators & Primary Action Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Page Indicators
                            Semantics(
                              label: 'Page ${_page + 1} of 3',
                              liveRegion: true,
                              child: ExcludeSemantics(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    3,
                                    (index) => AnimatedContainer(
                                      key: ValueKey('onboarding-indicator-$index'),
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3.5,
                                      ),
                                      width: index == _page ? 26 : 8,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: index == _page
                                            ? AppColors.brand700
                                            : const Color(0xFFCBDDF7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Primary CTA Button
                            FilledButton(
                              key: const ValueKey('onboarding-next'),
                              onPressed: _saving || _moving ? null : _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _page == 2
                                                ? (isTamil
                                                    ? 'தொடங்குங்கள்'
                                                    : isSinhala
                                                        ? 'ආරම්භ කරන්න'
                                                        : 'Get Started')
                                                : (isTamil
                                                    ? 'அடுத்து'
                                                    : isSinhala
                                                        ? 'ඊළඟ'
                                                        : 'Next'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }
}

/// Custom painter that creates the subtle, elegant background from the reference design:
/// - Light gradient base
/// - Soft organic curves & layered translucent surfaces
/// - Delicate rings with blue accent dots
/// - Subtle roof contour in Screen 1 & gentle flow curves in Screen 2 & 3
class _OnboardingBackgroundPainter extends CustomPainter {
  const _OnboardingBackgroundPainter({required this.page});

  final int page;

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
        colors: [
          Color(0xFFF7FAFD),
          Colors.white,
          Color(0xFFEFF5FC),
        ],
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
  bool shouldRepaint(covariant _OnboardingBackgroundPainter oldDelegate) =>
      oldDelegate.page != page;
}
