import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../services/app_error.dart';
import '../../../services/customer_booking_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/address/address_widgets.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';

Future<void> showReviewSheet(
  BuildContext context,
  Booking booking,
  String? proName,
) async {
  final service = CustomerScope.of(context).bookings;
  bool reviewed;
  try {
    reviewed = await service.hasReview(booking.id);
  } catch (error) {
    if (context.mounted) {
      showAppSnack(context, AppError.message(error), error: true);
    }
    return;
  }
  if (!context.mounted) return;
  if (reviewed) {
    showAppSnack(context, 'You have already reviewed this job. Thank you!');
    return;
  }
  final sent = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReviewSheet(
      service: service,
      booking: booking,
      proName: proName ?? booking.providerName ?? 'your professional',
    ),
  );
  if (sent == true && context.mounted) {
    showAppSnack(context, 'Thanks! Your review has been posted.');
  }
}

Future<void> showDisputeSheet(BuildContext context, Booking booking) async {
  final service = CustomerScope.of(context).bookings;
  final reference = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DisputeSheet(service: service, booking: booking),
  );
  if (reference != null && context.mounted) {
    showAppSnack(
      context,
      'Report received (ref ${reference.substring(0, 6).toUpperCase()}). '
      'Our team will contact you within 24 hours.',
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.service,
    required this.booking,
    required this.proName,
  });

  final CustomerBookingService service;
  final Booking booking;
  final String proName;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.submitReview(
        booking: widget.booking,
        rating: _rating,
        comment: _comment.text,
      );
      if (mounted) Navigator.of(context).pop(true);
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Text('Rate ${widget.proName}', style: AppTypography.headline),
          const SizedBox(height: 4),
          Text(
            'How was your ${widget.booking.serviceName}?',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  iconSize: 36,
                  onPressed: _busy ? null : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.star,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 500,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Tell others about the work (optional)',
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: AppTypography.caption.copyWith(color: AppColors.danger),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Submit Review',
            icon: LucideIcons.send,
            busy: _busy,
            onPressed: _rating == 0 ? null : _submit,
          ),
        ],
      ),
    ),
  );
}

class _DisputeSheet extends StatefulWidget {
  const _DisputeSheet({required this.service, required this.booking});
  final CustomerBookingService service;
  final Booking booking;

  @override
  State<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<_DisputeSheet> {
  String _category = CustomerBookingService.disputeCategories.first;
  final _details = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.service.reportProblem(
        booking: widget.booking,
        category: _category,
        description: _details.text,
      );
      if (mounted) Navigator.of(context).pop(id);
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Text('Report a Problem', style: AppTypography.headline),
          const SizedBox(height: 4),
          Text(
            'Booking #${widget.booking.displayReference}. Our disputes desk '
            'reviews every report.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionLabel('What went wrong?'),
          const SizedBox(height: AppSpacing.xs),
          ChoiceChips<String>(
            values: CustomerBookingService.disputeCategories,
            selected: _category,
            labelOf: (c) => c,
            onSelected: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _details,
            maxLines: 5,
            maxLength: 1000,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Describe what happened (at least 10 characters)',
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: AppTypography.caption.copyWith(color: AppColors.danger),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Submit Report',
            icon: LucideIcons.alertTriangle,
            color: AppColors.danger,
            busy: _busy,
            onPressed: _details.text.trim().length < 10 ? null : _submit,
          ),
        ],
      ),
    ),
  );
}
