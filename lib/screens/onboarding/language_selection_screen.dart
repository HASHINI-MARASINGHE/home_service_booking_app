import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/homecare_logo.dart';
import 'onboarding_page.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key, required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late Locale _selected = LocaleController.instance.locale;
  bool _saving = false;

  Future<void> _handleContinue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await LocaleController.instance.setLocale(_selected);
      await widget.onContinue();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save language preference. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _continueText() {
    switch (_selected.languageCode) {
      case 'ta':
        return 'Continue';
      case 'si':
        return 'Continue';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: OnboardingStyle.theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 680;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: isCompact ? 12 : 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isCompact) const SizedBox(height: 12),
                          // HomeCare Brand Mark
                          Center(
                            child: HomeCareBrandMark(
                              size: isCompact ? 38 : 46,
                              color: AppColors.brand700,
                              showCard: true,
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : 16),
                          Text(
                            'Choose your language',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: isCompact ? 22 : 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select your preferred language to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.ink3,
                              fontSize: isCompact ? 13 : 14,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: isCompact ? 14 : 20),
                          _LanguageOptionCard(
                            key: const ValueKey('language-option-en'),
                            title: 'English',
                            subtitle: 'English',
                            selected: _selected.languageCode == 'en',
                            compact: isCompact,
                            onTap: () {
                              setState(() => _selected = const Locale('en'));
                            },
                          ),
                          SizedBox(height: isCompact ? 8 : 10),
                          _LanguageOptionCard(
                            key: const ValueKey('language-option-si'),
                            title: 'සිංහල',
                            subtitle: 'Sinhala',
                            selected: _selected.languageCode == 'si',
                            compact: isCompact,
                            onTap: () {
                              setState(() => _selected = const Locale('si'));
                            },
                          ),
                          SizedBox(height: isCompact ? 8 : 10),
                          _LanguageOptionCard(
                            key: const ValueKey('language-option-ta'),
                            title: 'தமிழ்',
                            subtitle: 'Tamil',
                            selected: _selected.languageCode == 'ta',
                            compact: isCompact,
                            onTap: () {
                              setState(() => _selected = const Locale('ta'));
                            },
                          ),
                          SizedBox(height: isCompact ? 16 : 22),
                          FilledButton(
                            key: const ValueKey('language-continue-button'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brand700,
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(isCompact ? 48 : 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _saving ? null : _handleContinue,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _continueText(),
                                        style: TextStyle(
                                          fontSize: isCompact ? 15 : 16,
                                          fontWeight: FontWeight.w700,
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
                          if (!isCompact) const SizedBox(height: 12),
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

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 10 : 13,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brand700 : AppColors.borderSubtle,
              width: selected ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.brand700.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                const BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? AppColors.brand700 : AppColors.ink,
                        fontSize: compact ? 17 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? AppColors.brand700.withValues(alpha: 0.8)
                            : AppColors.ink3,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.brand700 : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.brand700
                        : AppColors.ink3.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
