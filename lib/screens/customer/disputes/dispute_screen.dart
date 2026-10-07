import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/booking.dart';
import '../../../models/dispute.dart';
import '../../../services/app_error.dart';
import '../../../services/dispute_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';
import 'dispute_form.dart';
import 'dispute_widgets.dart';

/// "Report a Problem" for one booking.
///
/// * No dispute yet  -> the dispute form (Create).
/// * A dispute exists -> its status tracker (Read), with Edit and Withdraw
///   while it is still pending (Update / Delete).
class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key, required this.bookingId, this.service});
  final String bookingId;

  /// Injected by tests; the real service is used otherwise.
  final DisputeService? service;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  late final DisputeService _service = widget.service ?? DisputeService();
  Stream<Booking?>? _booking;
  Stream<Dispute?>? _dispute;
  Stream<List<DisputePhoto>>? _photos;
  bool _editing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  void _start() {
    _booking ??= CustomerScope.of(context).bookings
        .watchBooking(widget.bookingId);
    _dispute ??= _service.watchDispute(widget.bookingId);
    _photos ??= _service.watchPhotos(widget.bookingId);
  }

  void _retry() => setState(() {
    _booking = _dispute = _photos = null;
    _start();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: StreamBuilder<Booking?>(
        stream: _booking,
        builder: (context, bookingSnap) => StreamBuilder<Dispute?>(
          stream: _dispute,
          builder: (context, disputeSnap) => StreamBuilder<List<DisputePhoto>>(
            stream: _photos,
            builder: (context, photoSnap) {
              final booking = bookingSnap.data;
              final dispute = disputeSnap.data;
              final error =
                  bookingSnap.error ?? disputeSnap.error ?? photoSnap.error;
              final waiting =
                  bookingSnap.connectionState == ConnectionState.waiting ||
                  disputeSnap.connectionState == ConnectionState.waiting;
              Widget body;
              if (error != null) {
                body = ErrorState(error: error, onRetry: _retry);
              } else if (waiting) {
                body = const LoadingState();
              } else if (booking == null) {
                body = ErrorState(
                  error: StateError(
                    'This booking was not found or is not linked to your '
                    'account.',
                  ),
                );
              } else if (dispute == null &&
                  booking.status != BookingStatus.completed) {
                body = ErrorState(
                  error: StateError(
                    'You can report a problem once the job has been '
                    'completed.',
                  ),
                );
              } else if (dispute == null || _editing) {
                body = DisputeForm(
                  // A new form when switching between create and edit.
                  key: ValueKey(_editing ? 'edit-form' : 'new-form'),
                  booking: booking,
                  service: _service,
                  existing: dispute,
                  existingPhotos: photoSnap.data ?? const [],
                  onSaved: () {
                    if (_editing) setState(() => _editing = false);
                  },
                );
              } else {
                body = _DisputeStatusView(
                  booking: booking,
                  dispute: dispute,
                  photos: photoSnap.data ?? const [],
                  service: _service,
                  onEdit: () => setState(() => _editing = true),
                );
              }
              return Column(
                children: [
                  ScreenHeader(
                    title: dispute == null
                        ? 'Job Details'
                        : _editing
                        ? 'Edit Dispute'
                        : 'Your Dispute',
                    onBack: _editing
                        ? () => setState(() => _editing = false)
                        : null,
                  ),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Read view: tracker, what the customer wrote and, once decided, the outcome.
class _DisputeStatusView extends StatefulWidget {
  const _DisputeStatusView({
    required this.booking,
    required this.dispute,
    required this.photos,
    required this.service,
    required this.onEdit,
  });

  final Booking booking;
  final Dispute dispute;
  final List<DisputePhoto> photos;
  final DisputeService service;
  final VoidCallback onEdit;

  @override
  State<_DisputeStatusView> createState() => _DisputeStatusViewState();
}

class _DisputeStatusViewState extends State<_DisputeStatusView> {
  bool _busy = false;

  Future<void> _withdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw dispute?'),
        content: const Text(
          'Your claim will be removed and the provider will no longer see it. '
          'You can file a new one while the 3-day warranty is still open.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep dispute'),
          ),
          TextButton(
            key: const ValueKey('confirm-withdraw'),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Withdraw', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.service.withdraw(widget.dispute);
      if (!mounted) return;
      showAppSnack(context, 'Your dispute was withdrawn.');
      Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, AppError.message(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispute = widget.dispute;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      children: [
        DisputeJobCard(booking: widget.booking),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dispute status', style: AppTypography.title),
              const SizedBox(height: AppSpacing.md),
              DisputeTracker(status: dispute.status),
              const SizedBox(height: AppSpacing.sm),
              Text(
                disputeStatusMessage(dispute),
                key: const ValueKey('dispute-status-message'),
                style: AppTypography.body,
              ),
            ],
          ),
        ),
        if (dispute.status == DisputeStatus.resolved) ...[
          const SizedBox(height: AppSpacing.md),
          _OutcomeCard(dispute: dispute),
        ],
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Reason'),
              const SizedBox(height: 4),
              Text(
                dispute.tag == null
                    ? dispute.reason
                    : '${dispute.reason} · ${dispute.tag}',
                style: AppTypography.bodyStrong,
              ),
              const SizedBox(height: AppSpacing.sm),
              const SectionLabel('Your description'),
              const SizedBox(height: 4),
              Text(dispute.description, style: AppTypography.body),
              if (dispute.createdAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Filed ${Formatters.shortDate(dispute.createdAt!.toLocal())}, '
                  '${Formatters.clock(dispute.createdAt!.toLocal())}',
                  style: AppTypography.caption,
                ),
              ],
              if (widget.photos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const SectionLabel('Photos'),
                const SizedBox(height: AppSpacing.xs),
                DisputePhotoGrid(photos: widget.photos),
              ],
            ],
          ),
        ),
        if (dispute.providerResponse != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Provider response'),
                const SizedBox(height: 4),
                Text(dispute.providerResponse!, style: AppTypography.body),
              ],
            ),
          ),
        ],
        if (dispute.isPending) ...[
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            key: const ValueKey('edit-dispute'),
            label: 'Edit dispute',
            icon: LucideIcons.pencil,
            onPressed: _busy ? null : widget.onEdit,
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              key: const ValueKey('withdraw-dispute'),
              onPressed: _busy ? null : _withdraw,
              icon: Icon(LucideIcons.undo2, size: 18, color: AppColors.danger),
              label: Text(
                'Withdraw dispute',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'A dispute that is being reviewed or has been decided can no '
              'longer be edited or withdrawn.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ),
      ],
    );
  }
}

/// Decision, refund and the safety desk's note after a dispute is resolved.
class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.dispute});
  final Dispute dispute;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.successSoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Decision', style: AppTypography.title),
        const SizedBox(height: 4),
        Text(
          dispute.decision ?? 'Resolved',
          key: const ValueKey('dispute-decision'),
          style: AppTypography.bodyStrong,
        ),
        if (dispute.refundAmount != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Refund: ${Formatters.lkr(dispute.refundAmount)}',
            style: AppTypography.bodyStrong.copyWith(color: AppColors.success),
          ),
        ],
        if (dispute.adminNote != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(dispute.adminNote!, style: AppTypography.body),
        ],
      ],
    ),
  );
}
