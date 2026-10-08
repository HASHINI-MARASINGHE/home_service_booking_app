import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/booking.dart';
import '../../models/quote.dart';
import '../../screens/customer/customer_scope.dart';
import '../../services/app_error.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../common/app_widgets.dart';

/// The price of a booking, from the customer's side: waiting for a quote,
/// a quote to accept or decline, or the locked price.
///
/// Answering sends the amount that is on screen. If the provider changed the
/// quote in the meantime the answer is refused, so nobody agrees to a price
/// they have not seen.
class QuoteCard extends StatefulWidget {
  const QuoteCard({super.key, required this.booking});

  final Booking booking;

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

enum _Answer { accept, decline }

class _QuoteCardState extends State<QuoteCard> {
  _Answer? _busy;
  String? _error;
  _Answer? _failed;

  Booking get _b => widget.booking;

  Future<void> _answer(_Answer answer) async {
    if (_busy != null) return;
    final amount = _b.quotedAmount;
    if (amount == null) return;
    if (answer == _Answer.decline) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Decline this quote?'),
          content: Text(
            _b.isRevision
                ? 'The price you already accepted '
                      '(${Formatters.lkr(_b.acceptedAmount)}) will still apply.'
                : 'Your provider can send you a new price, or you can cancel '
                      'the booking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep quote'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Decline quote'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final service = CustomerScope.of(context).bookings;
    setState(() {
      _busy = answer;
      _error = null;
      _failed = null;
    });
    try {
      if (answer == _Answer.accept) {
        await service.acceptQuote(_b.id, amount);
      } else {
        await service.declineQuote(_b.id, amount);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        answer == _Answer.accept
            ? (_b.isRevision
                  ? 'New price accepted.'
                  : 'Quote accepted. Your booking is confirmed.')
            : 'Quote declined.',
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = AppError.message(error);
          _failed = answer;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    return AppCard(
      key: const ValueKey('quote-card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Price quote'),
          const SizedBox(height: AppSpacing.md),
          if (b.canAnswerQuote)
            ..._offer(b)
          else if (b.approvedAmount != null)
            ..._locked(b)
          else if (b.status.isHistory)
            ..._closed(b)
          else
            ..._waiting(b),
          if (b.quoteHistory.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _History(entries: b.quoteHistory),
          ],
        ],
      ),
    );
  }

  List<Widget> _waiting(Booking b) {
    final declined = b.quoteStatus == QuoteStatus.declined;
    return [
      _Banner(
        key: const ValueKey('quote-pending'),
        icon: declined ? LucideIcons.refreshCw : LucideIcons.hourglass,
        title: declined ? 'Waiting for a new quote' : 'Quote pending',
        message: declined
            ? 'You declined ${Formatters.lkr(b.quotedAmount)}. Your provider '
                  'can send a new price, or you can cancel this booking.'
            : 'Your provider will send a price after reviewing your request. '
                  'Nothing is charged now.',
      ),
    ];
  }

  List<Widget> _closed(Booking b) => [
    _Banner(
      icon: LucideIcons.circleSlash,
      title: 'No price was agreed',
      message: b.status == BookingStatus.cancelled
          ? 'This booking was cancelled before a quote was accepted.'
          : 'This request ended before a quote was accepted.',
    ),
  ];

  List<Widget> _locked(Booking b) => [
    Row(
      key: const ValueKey('quote-locked'),
      children: [
        const Icon(LucideIcons.lock, size: 20, color: AppColors.success),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            b.status == BookingStatus.completed
                ? 'Final price'
                : 'Price confirmed',
            style: AppTypography.subtitle.copyWith(color: AppColors.success),
          ),
        ),
      ],
    ),
    const SizedBox(height: AppSpacing.xs),
    Text(Formatters.lkr(b.approvedAmount), style: AppTypography.display),
    if (b.revisionDeclined) ...[
      const SizedBox(height: AppSpacing.xs),
      Text(
        'You declined the revised price, so this amount still applies.',
        style: AppTypography.caption,
      ),
    ],
  ];

  List<Widget> _offer(Booking b) {
    final latest = b.quoteHistory.isEmpty ? null : b.quoteHistory.last;
    return [
      Text(
        b.isRevision ? 'Revised quote' : 'Quote received',
        key: const ValueKey('quote-received'),
        style: AppTypography.subtitle.copyWith(color: AppColors.primary),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(Formatters.lkr(b.quotedAmount), style: AppTypography.display),
      if (b.isRevision) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your approved price is ${Formatters.lkr(b.acceptedAmount)} until '
          'you accept this change.',
          style: AppTypography.caption,
        ),
        if (latest?.reason != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Reason: ${latest!.reason}', style: AppTypography.body),
          ),
      ],
      if (b.quoteNote != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text("What's included", style: AppTypography.label),
        Text(b.quoteNote!, style: AppTypography.body),
      ],
      const SizedBox(height: AppSpacing.md),
      if (_error != null) ...[
        Container(
          key: const ValueKey('quote-error'),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
              if (_failed != null)
                TextButton(
                  onPressed: () => _answer(_failed!),
                  child: const Text('Try again'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      PrimaryButton(
        key: const ValueKey('accept-quote'),
        label: 'Accept quote',
        icon: LucideIcons.check,
        busy: _busy == _Answer.accept,
        onPressed: _busy == null ? () => _answer(_Answer.accept) : null,
      ),
      const SizedBox(height: AppSpacing.xs),
      SecondaryButton(
        key: const ValueKey('decline-quote'),
        label: 'Decline quote',
        icon: LucideIcons.x,
        foreground: AppColors.danger,
        busy: _busy == _Answer.decline,
        onPressed: _busy == null ? () => _answer(_Answer.decline) : null,
      ),
    ];
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: AppColors.primary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.subtitle),
            const SizedBox(height: 2),
            Text(message, style: AppTypography.body),
          ],
        ),
      ),
    ],
  );
}

class _History extends StatelessWidget {
  const _History({required this.entries});

  final List<QuoteEntry> entries;

  static String _label(QuoteEntry e) => switch (e.status) {
    QuoteStatus.quoted => e.reason != null ? 'Revised quote' : 'Quote sent',
    QuoteStatus.accepted => 'You accepted',
    QuoteStatus.declined => 'You declined',
    QuoteStatus.pending => 'Requested',
  };

  @override
  Widget build(BuildContext context) {
    final items = entries.reversed.toList();
    // The tile paints its ink on the nearest Material; the card around it
    // has a background, so give it a clear one of its own.
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('quote-history'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(
            'Price history (${items.length})',
            style: AppTypography.label,
          ),
          children: [
            for (final e in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_label(e)}: ${Formatters.lkr(e.amount)}',
                            style: AppTypography.bodyStrong,
                          ),
                          if (e.reason != null)
                            Text(
                              'Reason: ${e.reason}',
                              style: AppTypography.caption,
                            ),
                          if (e.note != null)
                            Text(e.note!, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.shortDate(e.createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
