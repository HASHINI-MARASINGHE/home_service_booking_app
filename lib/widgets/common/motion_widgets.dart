import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Makes its child shrink slightly while it is pressed. It only watches the
/// pointer, so taps still reach the child (a button or card) as usual. Does
/// nothing when the phone asks for reduced motion.
class AppPressable extends StatefulWidget {
  const AppPressable({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(widget.enabled),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressedScale : 1,
        duration: AppMotion.base,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// A list item that fades in and slides up a little. Items with a higher
/// [index] start slightly later (a small stagger, at most 5 steps). The item
/// is simply shown when the phone asks for reduced motion.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _progress;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) return;
    final steps = widget.index.clamp(0, 5);
    final delay = AppMotion.stagger * steps;
    final total = AppMotion.base + delay;
    _controller = AnimationController(vsync: this, duration: total);
    // One controller, so no timers: the delay is the start of the interval.
    _progress = CurvedAnimation(
      parent: _controller!,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: AppMotion.curve,
      ),
    );
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * AppMotion.slideDistance),
          child: child,
        ),
      ),
    );
  }
}

/// A check mark that pops in once, to show that something worked. Shown
/// straight away when the phone asks for reduced motion.
class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({
    super.key,
    this.size = AppSizes.iconButton,
    this.color = AppColors.successText,
    this.icon = Icons.check_circle_outline,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.6, end: 1),
    duration: AppMotion.duration(context),
    curve: AppMotion.curve,
    builder: (context, scale, child) => Opacity(
      opacity: ((scale - 0.6) / 0.4).clamp(0, 1),
      child: Transform.scale(scale: scale, child: child),
    ),
    child: Icon(icon, size: size, color: color),
  );
}
