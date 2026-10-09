import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/professional.dart';
import '../../theme/app_theme.dart';
import 'app_widgets.dart' show PersonAvatar;
import 'motion_widgets.dart';
import 'rating_badge.dart';
import 'status_chip.dart';

/// One service provider in a list: photo, name, profession, a Verified chip,
/// the rating (outlined star plus number) and the starting price.
///
/// (Not to be confused with the plain `ProviderCard` container in
/// `widgets/provider/provider_widgets.dart`; never import both in one file.)
class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider, required this.onTap});

  final Professional provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final styles = context.textStyles;
    final l10n = context.l10n;
    final detailStyle = styles.caption;
    return Semantics(
      button: true,
      onTap: onTap,
      child: AppPressable(
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.card,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: AppSizes.borderControl,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PersonAvatar(name: p.name, photoUrl: p.photoUrl, size: 56),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Names are shown exactly as stored, never translated.
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: styles.h3,
                          ),
                          if (p.specialty.isNotEmpty)
                            Text(
                              p.specialty,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: styles.bodySmall,
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (p.verified)
                                StatusChip(
                                  type: StatusType.success,
                                  label: l10n.verifiedBadge,
                                ),
                              if (p.rating != null)
                                RatingBadge(rating: p.rating!),
                              if (p.reviewCount > 0)
                                Text(
                                  l10n.reviewCount(p.reviewCount),
                                  style: detailStyle,
                                ),
                              if (p.providerCode != null)
                                Text(
                                  l10n.providerIdLabel(p.providerCode!),
                                  style: detailStyle.copyWith(
                                    color: AppColors.brand900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          if (p.pricing != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.fromPrice(rupees(p.pricing!)),
                              style: styles.amount.copyWith(
                                color: AppColors.brand700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: AppSizes.iconButton,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
