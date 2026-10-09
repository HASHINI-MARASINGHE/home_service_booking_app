import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/professional.dart';
import '../../../models/review.dart';
import '../../../services/app_error.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../../widgets/common/review_widgets.dart';
import '../customer_scope.dart';

/// Rate & Review for one completed job. Before a review exists it is the
/// form from the design; afterwards the same route shows "Your review".
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Stream<Booking?>? _booking;
  Stream<Review?>? _review;
  Stream<Professional?>? _professional;
  String? _providerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = CustomerScope.of(context).bookings;
    _booking ??= service.watchBooking(widget.bookingId);
    _review ??= service.watchReview(widget.bookingId);
  }

  void _retry() {
    final service = CustomerScope.of(context).bookings;
    setState(() {
      _booking = service.watchBooking(widget.bookingId);
      _review = service.watchReview(widget.bookingId);
      _providerId = null;
    });
  }

  Stream<Professional?> _professionalFor(Booking booking) {
    if (_providerId != booking.providerId || _professional == null) {
      _providerId = booking.providerId;
      _professional = CustomerScope.of(context).bookings
          .watchProfessional(booking.providerId)
          .handleError((_) {});
    }
    return _professional!;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: StreamBuilder<Booking?>(
        stream: _booking,
        builder: (context, bookingSnap) => StreamBuilder<Review?>(
          stream: _review,
          builder: (context, reviewSnap) {
            final booking = bookingSnap.data;
            final review = reviewSnap.data;
            final error = bookingSnap.error ?? reviewSnap.error;
            Widget body;
            if (error != null) {
              body = ErrorState(error: error, onRetry: _retry);
            } else if (bookingSnap.connectionState == ConnectionState.waiting ||
                reviewSnap.connectionState == ConnectionState.waiting) {
              body = const LoadingState();
            } else if (booking == null) {
              body = ErrorState(
                error: StateError(
                  'This booking was not found or is not linked to your '
                  'account.',
                ),
              );
            // Access guard - only allows reviews once the booking status is 'completed'.
            // If a review already exists, switches UI mode to show existing review with edit option.
            } else if (booking.status != BookingStatus.completed &&
                review == null) {
              body = ErrorState(
                error: StateError(
                  'You can review a job once it has been completed.',
                ),
              );
            } else {
              body = StreamBuilder<Professional?>(
                stream: _professionalFor(booking),
                builder: (context, pro) => _ReviewBody(
                  booking: booking,
                  professional: pro.data,
                  review: review,
                ),
              );
            }
            return Column(
              children: [
                ScreenHeader(
                  title: review == null ? 'Rate & Review' : 'Your Review',
                ),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _ReviewBody extends StatefulWidget {
  const _ReviewBody({
    required this.booking,
    required this.professional,
    required this.review,
  });
  final Booking booking;
  final Professional? professional;
  final Review? review;

  @override
  State<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<_ReviewBody> {
  int _rating = 0;
  final _tags = <String>{};
  final _comment = TextEditingController();
  bool? _recommend;
  bool _busy = false;
  bool _editing = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  // Handles both initial submission and editing mode.
  // Gathers star rating (1-5), ordered tags, feedback comment, and recommendation toggle.
  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = CustomerScope.of(context).bookings;
      // Keep the design's order rather than tap order.
      final tags = [
        for (final t in Review.tagOptions)
          if (_tags.contains(t)) t,
      ];
      final wasEditing = _editing;
      if (wasEditing) {
        await service.updateReview(
          booking: widget.booking,
          rating: _rating,
          comment: _comment.text,
          tags: tags,
          recommend: _recommend,
        );
      } else {
        await service.submitReview(
          booking: widget.booking,
          rating: _rating,
          comment: _comment.text,
          tags: tags,
          recommend: _recommend,
        );
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _editing = false;
      });
      showAppSnack(
        context,
        wasEditing
            ? 'Your review has been updated.'
            : 'Thanks! Your review has been posted.',
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppError.message(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final review = widget.review;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        _ProviderSummary(booking: b, professional: widget.professional),
        const SizedBox(height: AppSpacing.md),
        if (review != null && !_editing)
          ..._saved(review)
        else ...[
          if (review != null) ...[
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.primaryTint,
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.pencil,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      "Editing your review. Saving updates the provider's "
                      'overall rating.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ..._form(),
        ],
      ],
    );
  }

  /// The customer's saved review with the actions only they have.
  List<Widget> _saved(Review review) => [
    AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.circleCheck,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'You reviewed this job',
                  style: AppTypography.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ReviewBody(review: review),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    SecondaryButton(
      label: 'Edit Review',
      icon: LucideIcons.pencil,
      onPressed: () => _startEdit(review),
    ),
    const SizedBox(height: AppSpacing.xs),
    TextButton.icon(
      onPressed: _delete,
      icon: const Icon(LucideIcons.trash2, size: 18),
      label: const Text('Delete Review'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.danger,
        minimumSize: const Size.fromHeight(48),
        textStyle: AppTypography.button,
      ),
    ),
  ];

  void _startEdit(Review review) => setState(() {
    _editing = true;
    _error = null;
    _rating = review.rating;
    _tags
      ..clear()
      ..addAll(review.tags);
    _comment.text = review.comment;
    _recommend = review.recommend;
  });

  Future<void> _delete() async {
    final service = CustomerScope.of(context).bookings;
    final b = widget.booking;
    final deleted = await ConfirmationBottomSheet.show(
      context,
      ConfirmationBottomSheet(
        icon: LucideIcons.trash2,
        title: 'Delete your review?',
        message: TextSpan(
          text:
              'Your review of ${b.serviceName} will be removed and no '
              "longer counts towards the provider's overall rating.",
        ),
        keepIsPrimary: false,
        keepLabel: 'Cancel & Keep Review',
        keepIcon: LucideIcons.x,
        confirmLabel: 'Yes, Delete Review',
        confirmIcon: LucideIcons.trash2,
        onConfirm: () => service.deleteReview(b),
      ),
    );
    if (deleted && mounted) {
      showAppSnack(context, 'Your review has been deleted.');
      Navigator.of(context).maybePop();
    }
  }

  List<Widget> _form() => [
    AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text('How was your experience?', style: AppTypography.title),
          const SizedBox(height: 4),
          Text(
            'Your rating helps keep the care high-standard.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  iconSize: 38,
                  onPressed: _busy ? null : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i <= _rating ? AppColors.star : AppColors.subtle,
                  ),
                ),
            ],
          ),
          Text(
            _rating == 0
                ? Review.ratingLabel(0)
                : '$_rating.0 · ${Review.ratingLabel(_rating)}',
            style: AppTypography.bodyStrong.copyWith(
              color: _rating == 0 ? AppColors.muted : AppColors.star,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('What stood out about the work?'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in Review.tagOptions)
                _HighlightChip(
                  label: tag,
                  selected: _tags.contains(tag),
                  onTap: _busy
                      ? null
                      : () => setState(
                          () => _tags.contains(tag)
                              ? _tags.remove(tag)
                              : _tags.add(tag),
                        ),
                ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Written feedback'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            maxLines: 5,
            maxLength: Review.maxComment,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Tell others about the work (optional)',
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Would you recommend this specialist?'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _RecommendButton(
                  label: 'Yes, definitely',
                  icon: LucideIcons.thumbsUp,
                  selected: _recommend == true,
                  onTap: _busy ? null : () => setState(() => _recommend = true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RecommendButton(
                  label: 'No',
                  icon: LucideIcons.thumbsDown,
                  selected: _recommend == false,
                  onTap: _busy
                      ? null
                      : () => setState(() => _recommend = false),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    if (_error != null) ...[
      const SizedBox(height: AppSpacing.sm),
      Text(
        _error!,
        style: AppTypography.caption.copyWith(color: AppColors.danger),
      ),
    ],
    const SizedBox(height: AppSpacing.lg),
    PrimaryButton(
      label: _editing ? 'Save Changes' : 'Submit Review',
      icon: LucideIcons.send,
      busy: _busy,
      onPressed: _rating == 0 ? null : _submit,
    ),
    if (_editing) ...[
      const SizedBox(height: AppSpacing.xs),
      TextButton(
        onPressed: _busy ? null : () => setState(() => _editing = false),
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: AppTypography.button,
        ),
        child: const Text('Cancel'),
      ),
    ],
  ];
}

class _ProviderSummary extends StatelessWidget {
  const _ProviderSummary({required this.booking, required this.professional});
  final Booking booking;
  final Professional? professional;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final name = professional?.name ?? b.providerName ?? 'Your professional';
    final detail = [
      if (professional != null && professional!.specialty.isNotEmpty)
        professional!.specialty
      else
        b.serviceName,
    ].join(' · ');
    final done = b.completedAt;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PersonAvatar(
            name: name,
            photoUrl: professional?.photoUrl,
            size: 56,
            verified: professional?.verified ?? false,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title,
                      ),
                    ),
                    if (professional?.verified == true) ...[
                      const SizedBox(width: 6),
                      const StatusPill(
                        label: 'Verified Pro',
                        icon: LucideIcons.badgeCheck,
                        background: AppColors.primaryTint,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ],
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                Text(
                  'Completed${done == null ? '' : ' ${Formatters.shortDate(done)}'}'
                  ' · ${Formatters.lkr(b.chargeTotal)}',
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

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: selected ? Colors.white : AppColors.body,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecommendButton extends StatelessWidget {
  const _RecommendButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Material(
      color: selected ? AppColors.primaryTint : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.button,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.button,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: selected ? AppColors.primaryDark : AppColors.body,
                    ),
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
