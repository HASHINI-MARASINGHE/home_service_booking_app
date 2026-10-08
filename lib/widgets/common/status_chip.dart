import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';
import 'motion_widgets.dart';

/// The five kinds of status. Each one has its own icon SHAPE, so it can be
/// told apart even when the colors look the same (color blindness).
enum StatusType {
  /// Round shape with a check: done, verified, completed.
  success(
    icon: LucideIcons.circleCheck,
    solid: AppColors.successSolid,
    soft: AppColors.successSoft,
    text: AppColors.successText,
  ),

  /// Triangle: needs attention, waiting.
  warning(
    icon: LucideIcons.triangleAlert,
    solid: AppColors.warningSolid,
    soft: AppColors.warningSoft,
    text: AppColors.warningText,
  ),

  /// Eight sided stop shape: did not work, declined.
  error(
    icon: LucideIcons.octagonX,
    solid: AppColors.errorSolid,
    soft: AppColors.errorSoft,
    text: AppColors.errorText,
  ),

  /// Round shape with an i: good to know, in progress.
  info(
    icon: LucideIcons.info,
    solid: AppColors.infoSolid,
    soft: AppColors.infoSoft,
    text: AppColors.infoText,
  ),

  /// Crossed circle: closed, cancelled, not available.
  neutral(
    icon: LucideIcons.ban,
    solid: AppColors.neutralSolid,
    soft: AppColors.neutralSoft,
    text: AppColors.neutralText,
  );

  const StatusType({
    required this.icon,
    required this.solid,
    required this.soft,
    required this.text,
  });

  final IconData icon;
  final Color solid, soft, text;
}

/// A small pill that always shows an icon shape, a word and a color together.
/// The word is required: a status is never shown by color alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.type, required this.label});

  final StatusType type;
  final String label;

  static const _iconSize = 20.0;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(color: type.soft, borderRadius: AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.space1 + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The check pops in once when something is done.
            type == StatusType.success
                ? AnimatedCheck(
                    size: _iconSize,
                    color: type.text,
                    icon: type.icon,
                  )
                : Icon(type.icon, size: _iconSize, color: type.text),
            const SizedBox(width: AppSpacing.space1 + 2),
            Flexible(
              child: Text(
                label,
                style: context.textStyles.caption.copyWith(
                  color: type.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
