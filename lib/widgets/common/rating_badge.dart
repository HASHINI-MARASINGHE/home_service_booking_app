import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../theme/app_theme.dart';

/// A rating: an amber star with a dark outline, and the number beside it.
/// The amber fill alone is only 2 to 1 against white, so the outline and the
/// written number carry the meaning.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final double rating;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    final text = rating.toStringAsFixed(1);
    return Semantics(
      container: true,
      label: context.l10n.ratingSemantics(text),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A slightly bigger dark star behind the amber one is the outline.
          const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.star_rounded, size: _size, color: AppColors.accent700),
              Icon(
                Icons.star_rounded,
                size: _size - 6,
                color: AppColors.accent500,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            text,
            style: context.textStyles.label.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
