import 'package:flutter/material.dart';

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
            : const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: OnboardingStyle.theme,
    child: Scaffold(
      backgroundColor: OnboardingStyle.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _page < 2
                        ? Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: TextButton(
                              key: const ValueKey('onboarding-skip'),
                              onPressed: _saving || _moving ? null : _finish,
                              child: const Text('Skip'),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Expanded(
                  child: PageView(
                    key: const ValueKey('onboarding-pages'),
                    controller: _controller,
                    physics: _saving
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (page) => setState(() => _page = page),
                    children: const [
                      OnboardingPage(
                        title: 'Help for your home,\nmade simple.',
                        description: 'Find trusted professionals for repairs,\nmaintenance and everyday home services.',
                        imageAsset: 'assets/images/onboarding_home.jpg',
                        imageAlignment: Alignment.topCenter,
                      ),
                      OnboardingPage(
                        title: 'Connecting you with\nthe right people.',
                        description: 'Customers find reliable help. Service\nproviders find opportunities to grow.',
                        imageAsset: 'assets/images/onboarding_connection.jpg',
                        imageAspectRatio: 1.25,
                      ),
                      OnboardingPage(
                        title: 'One app. Two ways to\nget things done.',
                        description: 'Book the help you need or provide your\nskills to customers who need them.',
                        showExperiences: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: index == _page ? 26 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _page
                                      ? OnboardingStyle.teal
                                      : OnboardingStyle.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('onboarding-next'),
                        onPressed: _saving || _moving ? null : _next,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: OnboardingStyle.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _page == 2 ? 'Get Started' : 'Next',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
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
    ),
  );
}
