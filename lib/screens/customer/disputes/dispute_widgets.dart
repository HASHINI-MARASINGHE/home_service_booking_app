import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/dispute.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';

/// The job at the top of the screen: provider, payment badge and amount.
class DisputeJobCard extends StatelessWidget {
  const DisputeJobCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (booking.paymentStatus) {
      'escrow' => ('In Escrow', AppColors.warning, AppColors.warningSoft),
      'paid' => ('Paid', AppColors.success, AppColors.successSoft),
      'refund_pending' ||
      'refunded' => ('Refund', AppColors.primaryDark, AppColors.primaryTint),
      _ => (booking.status.label, AppColors.muted, AppColors.surfaceLavender),
    };
    return AppCard(
      child: Row(
        children: [
          PersonAvatar(name: booking.providerName ?? booking.serviceName),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: label,
                      color: color,
                      background: background,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Provider: ${booking.providerName ?? 'Your professional'}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Booking #${booking.displayReference}',
                        style: AppTypography.caption,
                      ),
                    ),
                    Text(
                      Formatters.lkr(booking.chargeTotal),
                      style: AppTypography.amount.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small rounded option under the reason dropdown ("Defective repair").
class DisputeTagChip extends StatelessWidget {
  const DisputeTagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.surfaceLavender,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? AppColors.primaryDark : AppColors.body,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

/// The photos in a dispute. With [onRemove] / [onAdd] it is editable (the
/// form); without them it just shows the pictures (the status view).
class DisputePhotoGrid extends StatelessWidget {
  const DisputePhotoGrid({
    super.key,
    required this.photos,
    this.onRemove,
    this.onAdd,
    this.adding = false,
  });

  final List<DisputePhoto> photos;
  final void Function(int index)? onRemove;
  final VoidCallback? onAdd;
  final bool adding;

  static const tile = 84.0;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (var i = 0; i < photos.length; i++)
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              // Base64 text is turned back into a picture here.
              child: Image.memory(
                photos[i].bytes,
                key: ValueKey('dispute-photo-$i'),
                width: tile,
                height: tile,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: tile,
                  height: tile,
                  child: ColoredBox(
                    color: AppColors.surfaceLavender,
                    child: Icon(LucideIcons.imageOff, color: AppColors.muted),
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: -6,
                right: -6,
                child: InkWell(
                  key: ValueKey('remove-photo-$i'),
                  onTap: () => onRemove!(i),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      if (onAdd != null)
        Semantics(
          button: true,
          label: 'Add photo',
          child: InkWell(
            key: const ValueKey('add-dispute-photo'),
            onTap: adding ? null : onAdd,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: CustomPaint(
              painter: const _DashedBorder(color: AppColors.subtle),
              child: SizedBox(
                width: tile,
                height: tile,
                child: adding
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    : const Icon(LucideIcons.plus, color: AppColors.muted),
              ),
            ),
          ),
        ),
    ],
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Pending → Under Review → Resolved.
class DisputeTracker extends StatelessWidget {
  const DisputeTracker({super.key, required this.status});
  final DisputeStatus status;

  @override
  Widget build(BuildContext context) {
    final current = status.index;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final step in DisputeStatus.values) ...[
          if (step.index > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(top: 13),
                color: step.index <= current
                    ? AppColors.primary
                    : AppColors.divider,
              ),
            ),
          SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.index <= current
                        ? AppColors.primary
                        : AppColors.surface,
                    border: Border.all(
                      color: step.index <= current
                          ? AppColors.primary
                          : AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child:
                      step.index < current || status == DisputeStatus.resolved
                      ? const Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : step.index == current
                      ? const Icon(
                          LucideIcons.clock,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: step.index <= current
                        ? AppColors.navy
                        : AppColors.muted,
                    fontWeight: step.index == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The sentence under the tracker, e.g. "We will respond by ...".
String disputeStatusMessage(Dispute dispute) => switch (dispute.status) {
  DisputeStatus.pending =>
    dispute.respondDeadline == null
        ? 'Your claim was received and is waiting for the safety desk.'
        : 'Your claim was received. We will respond by '
              '${Formatters.shortDate(dispute.respondDeadline!.toLocal())}, '
              '${Formatters.clock(dispute.respondDeadline!.toLocal())}.',
  DisputeStatus.underReview =>
    'The safety desk is reviewing your claim and the photos you attached.',
  DisputeStatus.resolved => 'Your claim has been decided.',
};
