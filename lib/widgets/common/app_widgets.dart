import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/app_error.dart';
import '../../theme/app_theme.dart';

/// White rounded card with the soft HomeCare shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.surface,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadius.card,
      border: border,
      boxShadow: color == AppColors.surface ? AppShadows.soft : null,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Circular back button + centred title used at the top of pushed screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.xs,
      AppSpacing.screen,
      AppSpacing.xs,
    ),
    child: SizedBox(
      height: 48,
      // Keeps the title centred while leaving room for wide trailing pills.
      child: NavigationToolbar(
        middleSpacing: AppSpacing.xs,
        leading: showBack
            ? CircleIconButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'Back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null,
        middle: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.screenTitle,
        ),
        trailing: trailing,
      ),
    ),
  );
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: AppColors.navy),
        ),
      ),
    ),
  );
}

/// Full-width filled button with an optional leading icon and busy state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: color == null
          ? null
          : FilledButton.styleFrom(backgroundColor: color),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : _ButtonLabel(label: label, icon: icon),
    ),
  );
}

/// White (or tinted) full-width button used for secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foreground = AppColors.primary,
    this.background = AppColors.surface,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color foreground, background;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.6),
        disabledForegroundColor: foreground.withValues(alpha: 0.5),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
              ),
            )
          : _ButtonLabel(label: label, icon: icon),
    ),
  );
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

/// Uppercase grey section label, optionally with a teal action on the right.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 3,
        child: Text(text.toUpperCase(), style: AppTypography.overline),
      ),
      if (trailing != null) ...[
        const SizedBox(width: AppSpacing.xs),
        // Right-aligned; long values (areas, service names) ellipsize
        // instead of overflowing on narrow phones.
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              child: trailing!,
            ),
          ),
        ),
      ],
    ],
  );
}

/// Small rounded status label (e.g. "Default", "Confirmed", "5 Items").
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.icon,
    this.dot = false,
  });

  final String label;
  final Color color, background;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: background, borderRadius: AppRadius.chip),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Rounded-square tinted icon used on cards.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.size = 44,
    this.circle = false,
  });

  final IconData icon;
  final Color color, background;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(AppRadius.md),
    ),
    child: Icon(icon, color: color, size: size * 0.48),
  );
}

/// Sage-tinted information banner (HomeCare Guarantee etc.).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = LucideIcons.shieldCheck,
    this.background = AppColors.surfaceSage,
    this.iconFilled = true,
    this.trailing,
  });

  final String title, message;
  final IconData icon;
  final Color background;
  final bool iconFilled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => AppCard(
    color: background,
    child: Row(
      children: [
        IconTile(
          icon: icon,
          circle: true,
          size: 46,
          color: iconFilled ? Colors.white : AppColors.primary,
          background: iconFilled ? AppColors.primary : AppColors.surface,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.subtitle),
              const SizedBox(height: 2),
              Text(message, style: AppTypography.caption),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          trailing!,
        ],
      ],
    ),
  );
}

class HomeCareGuarantee extends StatelessWidget {
  const HomeCareGuarantee({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => InfoBanner(
    title: 'HomeCare Guarantee',
    message:
        message ??
        'Verified technicians with background checks and free 30-day '
            'rework cover.',
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTypography.caption),
          ],
        ],
      ),
    ),
  );
}

/// Friendly error with a retry action. Never shows raw exception text.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final kind = AppError.kind(error);
    final (icon, title) = switch (kind) {
      AppErrorKind.network => (LucideIcons.wifiOff, 'You are offline'),
      AppErrorKind.session => (LucideIcons.lock, 'Session expired'),
      AppErrorKind.permission => (LucideIcons.shieldOff, 'Access denied'),
      AppErrorKind.notFound => (LucideIcons.searchX, 'Not found'),
      _ => (LucideIcons.alertTriangle, 'Something went wrong'),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(
              icon: icon,
              circle: true,
              size: 64,
              color: AppColors.danger,
              background: AppColors.dangerSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppError.message(error),
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Try again',
                  icon: LucideIcons.refreshCw,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grey drag handle at the top of bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.color = AppColors.surfaceLavenderDeep});
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 48,
      height: 5,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.chip),
    ),
  );
}

/// Destructive-action confirmation sheet matching the Cancel Booking and
/// Delete Address designs: tinted icon, title, rich message, optional
/// highlighted body, then a primary "keep" and a red "confirm" button.
class ConfirmationBottomSheet extends StatefulWidget {
  const ConfirmationBottomSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.keepLabel,
    required this.confirmLabel,
    required this.onConfirm,
    this.keepIcon,
    this.confirmIcon,
    this.highlight,
    this.footer,
    this.keepIsPrimary = true,
  });

  final IconData icon;
  final String title;
  final InlineSpan message;
  final String keepLabel, confirmLabel;
  final IconData? keepIcon, confirmIcon;
  final Widget? highlight, footer;
  final bool keepIsPrimary;

  /// Runs the action; the sheet closes with `true` when it succeeds and
  /// shows the friendly error inline when it throws.
  final Future<void> Function() onConfirm;

  static Future<bool> show(
    BuildContext context,
    ConfirmationBottomSheet sheet,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => sheet,
    );
    return result ?? false;
  }

  @override
  State<ConfirmationBottomSheet> createState() =>
      _ConfirmationBottomSheetState();
}

class _ConfirmationBottomSheetState extends State<ConfirmationBottomSheet> {
  bool _busy = false;
  Object? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          IconTile(
            icon: widget.icon,
            circle: true,
            size: 60,
            color: AppColors.danger,
            background: AppColors.dangerSoft,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            widget.message,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          if (widget.highlight != null) ...[
            const SizedBox(height: AppSpacing.md),
            widget.highlight!,
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppError.message(_error!),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          widget.keepIsPrimary
              ? PrimaryButton(
                  label: widget.keepLabel,
                  icon: widget.keepIcon,
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                )
              : SecondaryButton(
                  label: widget.keepLabel,
                  icon: widget.keepIcon,
                  foreground: AppColors.navy,
                  background: AppColors.surfaceLavender,
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: widget.confirmLabel,
            icon: widget.confirmIcon,
            foreground: AppColors.danger,
            background: AppColors.dangerSoft,
            busy: _busy,
            onPressed: _confirm,
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            widget.footer!,
          ],
        ],
      ),
    ),
  );
}

/// Empty-state illustration: concentric soft circles with an icon and two
/// small floating badges, as on the No Bookings / No Saved Addresses designs.
class EmptyIllustration extends StatelessWidget {
  const EmptyIllustration({
    super.key,
    required this.icon,
    required this.topBadge,
    required this.bottomBadge,
  });

  final IconData icon, topBadge, bottomBadge;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    height: 150,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 144,
          height: 144,
          decoration: const BoxDecoration(
            color: AppColors.surfaceSage,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 106,
          height: 106,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: Icon(icon, size: 34, color: AppColors.primary),
        ),
        Positioned(
          top: 4,
          right: 6,
          child: _Badge(icon: topBadge, color: AppColors.accentMint),
        ),
        Positioned(
          bottom: 14,
          left: 4,
          child: _Badge(icon: bottomBadge, color: AppColors.surface),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: AppShadows.soft,
    ),
    child: Icon(icon, size: 14, color: AppColors.primaryDark),
  );
}

/// Rounded avatar from a network URL with an initial-letter fallback.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 56,
    this.verified = false,
    this.square = false,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final bool verified, square;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final radius = square ? BorderRadius.circular(AppRadius.md) : null;
    final image = SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: radius ?? BorderRadius.circular(size),
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
    if (!verified) return image;
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        children: [
          image,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.badgeCheck,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.navy,
      ),
    );
}
