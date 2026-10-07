import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

abstract final class OnboardingStyle {
  static const teal = AppColors.brand700; // the brand blue now
  static const navy = AppColors.ink;
  static const muted = AppColors.ink3;
  static const background = AppColors.bg;
  static const white = AppColors.surface;
  static const lightTeal = AppColors.brand100; // soft blue now
  static const border = AppColors.borderSubtle;

  // Scoped to onboarding; existing authentication/customer/provider styling
  // and components retain their current behavior.
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
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: white,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
    this.imageAsset,
    this.imageAspectRatio,
    this.imageAlignment = Alignment.center,
    this.showExperiences = false,
  });

  final String title, description;
  final String? imageAsset;
  final double? imageAspectRatio;
  final Alignment imageAlignment;
  final bool showExperiences;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final imageHeight = (constraints.maxHeight * 0.62).clamp(220.0, 400.0);
      return SingleChildScrollView(
        key: PageStorageKey(title),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          children: [
            if (showExperiences)
              const _ExperienceCards()
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: OnboardingStyle.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    imageAsset!,
                    height: imageAspectRatio == null
                        ? imageHeight
                        : (constraints.maxWidth - 48) / imageAspectRatio!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: imageAlignment,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: OnboardingStyle.navy,
                  fontSize: constraints.maxWidth < 360 ? 28 : 30,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnboardingStyle.muted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ExperienceCards extends StatelessWidget {
  const _ExperienceCards();

  @override
  Widget build(BuildContext context) => const IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ExperienceCard(
            title: 'Customer',
            imageAsset: 'assets/images/onboarding_customer.jpg',
            steps: [
              (Icons.search_rounded, 'Find Service'),
              (Icons.calendar_today_outlined, 'Book'),
              (Icons.check_circle_outline_rounded, 'Service Completed'),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ExperienceCard(
            title: 'Service provider',
            imageAsset: 'assets/images/onboarding_provider.jpg',
            steps: [
              (Icons.notifications_none_rounded, 'Receive Request'),
              (Icons.task_alt_rounded, 'Accept'),
              (Icons.payments_outlined, 'Complete & Earn'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.title,
    required this.imageAsset,
    required this.steps,
  });
  final String title, imageAsset;
  final List<(IconData, String)> steps;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: OnboardingStyle.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: OnboardingStyle.border),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OnboardingStyle.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.5),
            excludeFromSemantics: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
          child: Column(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: OnboardingStyle.lightTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        steps[index].$1,
                        size: 15,
                        color: OnboardingStyle.teal,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          steps[index].$2,
                          style: const TextStyle(
                            color: OnboardingStyle.navy,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: OnboardingStyle.teal,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
