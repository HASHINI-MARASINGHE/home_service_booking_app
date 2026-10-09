import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/review.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Read-only row of five stars.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 18});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$rating out of 5 stars',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i <= rating ? AppColors.star : AppColors.subtle,
            ),
        ],
      ),
    ),
  );
}

/// Everything a review says: stars, highlights, written feedback and whether
/// the customer recommends the specialist. Used by both customer and provider.
class ReviewBody extends StatelessWidget {
  const ReviewBody({super.key, required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StarRow(rating: r.rating, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '${r.rating}.0 · ${Review.ratingLabel(r.rating)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong,
              ),
            ),
          ],
        ),
        if (r.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final tag in r.tags) _TagPill(tag)],
          ),
        ],
        if (r.comment.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('"${r.comment}"', style: AppTypography.body),
        ],
        if (r.recommend != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                r.recommend! ? LucideIcons.thumbsUp : LucideIcons.thumbsDown,
                size: 16,
                color: r.recommend! ? AppColors.success : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.recommend!
                      ? 'Recommends this specialist'
                      : 'Does not recommend this specialist',
                  style: AppTypography.caption.copyWith(color: AppColors.body),
                ),
              ),
            ],
          ),
        ],
        if (r.updatedAt != null || r.createdAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            r.updatedAt != null
                ? 'Edited on ${Formatters.shortDate(r.updatedAt!)}'
                : 'Reviewed on ${Formatters.shortDate(r.createdAt!)}',
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: AppRadius.chip,
    ),
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// One-line "★★★★☆ 4.0" for list cards. Shows nothing until reviewed.
class ReviewRatingLine extends StatelessWidget {
  const ReviewRatingLine({super.key, required this.stream, this.prefix});
  final Stream<Review?> stream;
  final String? prefix;

  @override
  Widget build(BuildContext context) => StreamBuilder<Review?>(
    stream: stream,
    builder: (context, snapshot) {
      final review = snapshot.data;
      if (review == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            if (prefix != null) ...[
              Text(prefix!, style: AppTypography.caption),
              const SizedBox(width: 6),
            ],
            StarRow(rating: review.rating, size: 16),
            const SizedBox(width: 6),
            Text(
              '${review.rating}.0',
              style: AppTypography.caption.copyWith(
                color: AppColors.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    },
  );
}
