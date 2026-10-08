import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/professional.dart';
import '../../models/rating_stats.dart';
import '../../models/review.dart';
import '../../models/service_category.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_search_bar.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/review_widgets.dart';

/// Admin panel: monitor ratings and reviews per service category.
class AdminRatingsScreen extends StatefulWidget {
  const AdminRatingsScreen({
    super.key,
    required this.service,
    this.standalone = false,
  });
  final AdminService service;
  final bool standalone;

  @override
  State<AdminRatingsScreen> createState() => _AdminRatingsScreenState();
}

class _AdminRatingsScreenState extends State<AdminRatingsScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  String _ratingFilter = 'All';
  late final TabController _tabs = TabController(
    length: ServiceCategory.all.length + 2,
    vsync: this,
  );
  // Live stream of verified professionals sorted by highest rating first.
  late final Stream<List<Professional>> _professionals = widget.service
      .watchAllProfessionals();

  @override
  void dispose() {
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  // Real-time multi-field search and rating tier filtering.
  List<Professional> _filter(List<Professional> list) {
    final query = _search.text.trim().toLowerCase();
    return list.where((p) {
      final r = p.rating ?? 0.0;
      if (_ratingFilter == '⭐ 4.5+' && (p.rating == null || r < 4.5)) return false;
      if (_ratingFilter == '⭐ 4.0 - 4.4' && (p.rating == null || r < 4.0 || r >= 4.5)) return false;
      if (_ratingFilter == '⚠️ Under 4.0' && (p.rating == null || r >= 4.0)) return false;
      if (_ratingFilter == 'Unrated' && (p.rating != null && (p.reviewCount) > 0)) return false;

      if (query.isEmpty) return true;
      if (p.name.toLowerCase().contains(query)) return true;
      if (p.specialty.toLowerCase().contains(query)) return true;
      if (p.providerCode?.toLowerCase().contains(query) ?? false) return true;
      return p.services.any((s) => s.toLowerCase().contains(query));
    }).toList();
  }

  bool _matchesAnyCategory(Professional p) =>
      ServiceCategory.all.any((cat) => cat.matches(p));

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Professional>>(
    stream: _professionals,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ErrorState(
          error: snapshot.error!,
          onRetry: () => setState(() {}),
        );
      }
      final all = snapshot.data ?? [];
      final filteredAll = _filter(all);

      final content = Column(
        children: [
          _SummaryBar(professionals: all),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.xs,
            ),
            child: AppSearchBar(
              controller: _search,
              hintText: 'Search provider, code, or service…',
              onChanged: (_) => setState(() {}),
              onClear: () => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppFilterChipBar<String>(
              items: [
                FilterItem(value: 'All', label: 'All Ratings', count: all.length),
                FilterItem(
                  value: '⭐ 4.5+',
                  label: '⭐ 4.5+',
                  count: all.where((p) => (p.rating ?? 0) >= 4.5).length,
                ),
                FilterItem(
                  value: '⭐ 4.0 - 4.4',
                  label: '⭐ 4.0 - 4.4',
                  count: all.where((p) => (p.rating ?? 0) >= 4.0 && (p.rating ?? 0) < 4.5).length,
                ),
                FilterItem(
                  value: '⚠️ Under 4.0',
                  label: '⚠️ Under 4.0',
                  count: all.where((p) => p.rating != null && p.rating! < 4.0).length,
                ),
                FilterItem(
                  value: 'Unrated',
                  label: 'Unrated',
                  count: all.where((p) => p.rating == null || p.reviewCount == 0).length,
                ),
              ],
              selected: _ratingFilter,
              onSelected: (tier) => setState(() => _ratingFilter = tier),
            ),
          ),
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.label,
              tabs: [
                Tab(text: 'All (${filteredAll.length})'),
                for (final cat in ServiceCategory.all)
                  Tab(
                    text:
                        '${cat.label} (${_filter(all.where(cat.matches).toList()).length})',
                  ),
                Tab(
                  text:
                      'Other (${_filter(all.where((p) => !_matchesAnyCategory(p)).toList()).length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: !snapshot.hasData
                ? const LoadingState(message: 'Loading provider ratings…')
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _ProviderList(
                        professionals: filteredAll,
                        service: widget.service,
                        emptyLabel: _search.text.isEmpty
                            ? 'No verified providers yet.'
                            : 'No providers match your search.',
                      ),
                      for (final cat in ServiceCategory.all)
                        _ProviderList(
                          professionals: _filter(
                            all.where(cat.matches).toList(),
                          ),
                          service: widget.service,
                          emptyLabel: _search.text.isEmpty
                              ? 'No verified ${cat.label.toLowerCase()} providers.'
                              : 'No ${cat.label.toLowerCase()} providers match your search.',
                        ),
                      _ProviderList(
                        professionals: _filter(
                          all.where((p) => !_matchesAnyCategory(p)).toList(),
                        ),
                        service: widget.service,
                        emptyLabel: _search.text.isEmpty
                            ? 'No verified providers in other categories.'
                            : 'No other providers match your search.',
                      ),
                    ],
                  ),
          ),
        ],
      );

      if (widget.standalone) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ratings & Reviews')),
          body: SafeArea(child: content),
        );
      }
      return content;
    },
  );
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.professionals});
  final List<Professional> professionals;

  @override
  Widget build(BuildContext context) {
    final rated = professionals.where((p) => p.rating != null).toList();
    final avgAll = rated.isEmpty
        ? null
        : rated.fold<double>(0, (s, p) => s + p.rating!) / rated.length;
    final totalReviews = professionals.fold<int>(
      0,
      (s, p) => s + p.reviewCount,
    );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _StatTile(
            icon: LucideIcons.users,
            label: 'Providers',
            value: '${professionals.length}',
            color: AppColors.primary,
          ),
          _divider(),
          _StatTile(
            icon: LucideIcons.star,
            label: 'Avg Rating',
            value: avgAll == null ? '—' : avgAll.toStringAsFixed(1),
            color: AppColors.star,
          ),
          _divider(),
          _StatTile(
            icon: LucideIcons.messageSquare,
            label: 'Reviews',
            value: '$totalReviews',
            color: AppColors.primaryDark,
          ),
          _divider(),
          _StatTile(
            icon: LucideIcons.trendingUp,
            label: 'Rated',
            value: '${rated.length}',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.title.copyWith(color: color, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ProviderList extends StatelessWidget {
  const _ProviderList({
    required this.professionals,
    required this.service,
    required this.emptyLabel,
  });
  final List<Professional> professionals;
  final AdminService service;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (professionals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.star, size: 48, color: AppColors.subtle),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyLabel,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      itemCount: professionals.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) =>
          _ProviderRatingCard(professional: professionals[i], service: service),
    );
  }
}

class _ProviderRatingCard extends StatelessWidget {
  const _ProviderRatingCard({
    required this.professional,
    required this.service,
  });
  final Professional professional;
  final AdminService service;

  @override
  Widget build(BuildContext context) {
    final p = professional;
    return AppCard(
      key: ValueKey('rating-card-${p.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AdminProviderReviewsScreen(professional: p, service: service),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(
                name: p.name,
                photoUrl: p.photoUrl,
                size: 46,
                verified: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      p.specialty.isEmpty ? 'Service Provider' : p.specialty,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.providerCode != null)
                      Text(
                        p.providerCode!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StreamBuilder<RatingStats?>(
                stream: service.watchRatingStats(p.id),
                builder: (context, snap) {
                  final stats = snap.data;
                  final avg = stats?.average ?? p.rating;
                  return _RatingBadge(
                    average: avg,
                    count: stats?.count ?? p.reviewCount,
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
          if (p.services.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final svc in p.services.take(4)) _ServiceChip(label: svc),
                if (p.services.length > 4)
                  _ServiceChip(
                    label: '+${p.services.length - 4} more',
                    faded: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.average, required this.count});
  final double? average;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (average == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLavender,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text('No ratings', style: AppTypography.caption),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
              const SizedBox(width: 3),
              Text(
                average!.toStringAsFixed(1),
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.warning,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Text(
            '$count ${count == 1 ? 'review' : 'reviews'}',
            style: AppTypography.caption.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label, this.faded = false});
  final String label;
  final bool faded;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: faded ? AppColors.surfaceLavender : AppColors.primaryTint,
      borderRadius: AppRadius.chip,
    ),
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        color: faded ? AppColors.muted : AppColors.primaryDark,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail screen: all reviews for one provider
// ─────────────────────────────────────────────────────────────────────────────

class AdminProviderReviewsScreen extends StatefulWidget {
  const AdminProviderReviewsScreen({
    super.key,
    required this.professional,
    required this.service,
  });
  final Professional professional;
  final AdminService service;

  @override
  State<AdminProviderReviewsScreen> createState() =>
      _AdminProviderReviewsScreenState();
}

class _AdminProviderReviewsScreenState
    extends State<AdminProviderReviewsScreen> {
  late final Stream<RatingStats?> _stats = widget.service.watchRatingStats(
    widget.professional.id,
  );
  late final Stream<List<Review>> _reviews = widget.service
      .watchProviderReviews(widget.professional.id);

  @override
  Widget build(BuildContext context) {
    final p = widget.professional;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SafeArea(
        child: StreamBuilder<RatingStats?>(
          stream: _stats,
          builder: (context, statsSnap) {
            final stats = statsSnap.data;
            return StreamBuilder<List<Review>>(
              stream: _reviews,
              builder: (context, reviewSnap) {
                if (reviewSnap.hasError) {
                  return ErrorState(error: reviewSnap.error!);
                }
                final reviews = reviewSnap.data ?? [];
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        child: Column(
                          children: [
                            _ProviderHeader(professional: p, stats: stats),
                            if (stats != null && stats.count > 0) ...[
                              const SizedBox(height: AppSpacing.md),
                              _StarDistribution(reviews: reviews),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          0,
                          AppSpacing.screen,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.messageSquare,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${reviews.length} ${reviews.length == 1 ? 'Review' : 'Reviews'}',
                              style: AppTypography.subtitle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!reviewSnap.hasData)
                      const SliverFillRemaining(
                        child: LoadingState(message: 'Loading reviews…'),
                      )
                    else if (reviews.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  size: 48,
                                  color: AppColors.subtle,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No reviews yet for ${p.name}.',
                                  style: AppTypography.body,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          0,
                          AppSpacing.screen,
                          AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) =>
                              _ReviewCard(review: reviews[i]),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({required this.professional, required this.stats});
  final Professional professional;
  final RatingStats? stats;

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final avg = stats?.average ?? p.rating;
    final count = stats?.count ?? p.reviewCount;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              PersonAvatar(
                name: p.name,
                photoUrl: p.photoUrl,
                size: 60,
                verified: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTypography.title),
                    Text(
                      p.specialty.isEmpty ? 'Service Provider' : p.specialty,
                      style: AppTypography.body,
                    ),
                    if (p.providerCode != null)
                      StatusPill(
                        label: p.providerCode!,
                        icon: LucideIcons.badgeCheck,
                        background: AppColors.primaryTint,
                        color: AppColors.primaryDark,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: avg == null
                  ? AppColors.surfaceLavender
                  : AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: avg == null
                ? const Text(
                    'No ratings yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warning,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StarRow(rating: avg.round(), size: 24),
                      const SizedBox(height: 4),
                      Text(
                        '$count ${count == 1 ? 'review' : 'reviews'} · '
                        '${p.completedJobs} completed jobs',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StarDistribution extends StatelessWidget {
  const _StarDistribution({required this.reviews});
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();
    final counts = List.filled(6, 0);
    for (final r in reviews) {
      if (r.rating >= 1 && r.rating <= 5) counts[r.rating]++;
    }
    final max = counts.reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating breakdown', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.sm),
          for (int star = 5; star >= 1; star--)
            _DistributionRow(
              star: star,
              count: counts[star],
              max: max,
              total: reviews.length,
            ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.star,
    required this.count,
    required this.max,
    required this.total,
  });
  final int star, count, max, total;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : count / max;
    final pct = total == 0 ? 0 : (count * 100 / total).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$star',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.chip,
              child: LinearProgressIndicator(
                value: fraction.toDouble(),
                minHeight: 8,
                backgroundColor: AppColors.surfaceLavender,
                valueColor: AlwaysStoppedAnimation(
                  star >= 4
                      ? AppColors.success
                      : star == 3
                      ? AppColors.star
                      : AppColors.danger,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.end,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  Color _starColor(int rating) => switch (rating) {
    5 => AppColors.success,
    4 => AppColors.infoSolid,
    3 => AppColors.star,
    2 => AppColors.warning,
    _ => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final r = review;
    return AppCard(
      key: ValueKey('review-${r.bookingId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(
                name: r.customerName.isEmpty ? 'Customer' : r.customerName,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.customerName.isEmpty ? 'Customer' : r.customerName,
                      style: AppTypography.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (r.serviceName.isNotEmpty)
                      Text(r.serviceName, style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _starColor(r.rating).withValues(alpha: 0.15),
                  borderRadius: AppRadius.chip,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: _starColor(r.rating),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${r.rating}',
                      style: TextStyle(
                        color: _starColor(r.rating),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${r.comment}"',
              style: AppTypography.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (r.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in r.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: AppRadius.chip,
                    ),
                    child: Text(
                      tag,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (r.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              Formatters.shortDate(r.createdAt!),
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}
