import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/dispute.dart';
import '../../services/admin_service.dart';
import '../../services/app_error.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_search_bar.dart';
import '../../widgets/common/app_widgets.dart';
import '../customer/disputes/dispute_widgets.dart';

/// The safety desk's list of disputes: Pending, Under Review and Resolved.
class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({
    super.key,
    required this.service,
    this.onSelectTab,
  });
  final AdminService service;
  final ValueChanged<int>? onSelectTab;

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  // Segmented filtering - listens to stream of disputes matching current tab (Pending / Under Review / Resolved).
  DisputeStatus _filter = DisputeStatus.pending;
  final _search = TextEditingController();
  String _selectedReason = 'All';

  late Stream<List<Dispute>> _items = widget.service.watchDisputes(_filter);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(DisputeStatus status) => setState(() {
    _filter = status;
    _items = widget.service.watchDisputes(status);
  });

  List<Dispute> _filterList(List<Dispute> list) {
    final query = _search.text.trim().toLowerCase();
    return list.where((d) {
      if (_selectedReason != 'All' &&
          d.reason.toLowerCase() != _selectedReason.toLowerCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      if (d.bookingRef.toLowerCase().contains(query)) return true;
      if (d.customerName.toLowerCase().contains(query)) return true;
      if (d.providerName.toLowerCase().contains(query)) return true;
      if (d.serviceName.toLowerCase().contains(query)) return true;
      if (d.reason.toLowerCase().contains(query)) return true;
      if (d.description.toLowerCase().contains(query)) return true;
      return false;
    }).toList();
  }

  List<String> _extractReasons(List<Dispute> list) {
    final set = <String>{'All'};
    for (final d in list) {
      if (d.reason.isNotEmpty) set.add(d.reason);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xs,
        ),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<DisputeStatus>(
            key: const ValueKey('dispute-filter'),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              selectedBackgroundColor: AppColors.brand900,
              selectedForegroundColor: Colors.white,
              foregroundColor: AppColors.ink2,
              side: const BorderSide(color: AppColors.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            segments: [
              for (final status in DisputeStatus.values)
                ButtonSegment(value: status, label: Text(status.label)),
            ],
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _select(s.first),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.xs,
        ),
        child: AppSearchBar(
          controller: _search,
          hintText: 'Search ref (#1024), customer, provider…',
          onChanged: (_) => setState(() {}),
          onClear: () => setState(() {}),
        ),
      ),
      Expanded(
        child: StreamBuilder<List<Dispute>>(
          stream: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(
                error: snapshot.error!,
                onRetry: () => _select(_filter),
              );
            }
            if (!snapshot.hasData) return const LoadingState();
            final allItems = snapshot.data!;
            final reasons = _extractReasons(allItems);
            final filteredItems = _filterList(allItems);

            if (allItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.brand100,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          LucideIcons.triangleAlert,
                          size: 28,
                          color: AppColors.brand700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        switch (_filter) {
                          DisputeStatus.pending => 'No disputes are waiting.',
                          DisputeStatus.underReview =>
                            'No disputes are under review.',
                          DisputeStatus.resolved => 'No resolved disputes yet.',
                        },
                        key: const ValueKey('admin-disputes-empty'),
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodySmall.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (reasons.length > 2) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppFilterChipBar<String>(
                    items: [
                      for (final r in reasons)
                        FilterItem(
                          value: r,
                          label: r,
                          count: r == 'All'
                              ? allItems.length
                              : allItems
                                  .where((i) => i.reason.toLowerCase() == r.toLowerCase())
                                  .length,
                        ),
                    ],
                    selected: _selectedReason,
                    onSelected: (r) => setState(() => _selectedReason = r),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.searchX,
                                  size: 40,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No disputes match your search or filter.',
                                  style: AppTypography.body,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.xs,
                            AppSpacing.screen,
                            AppSpacing.xl,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => _DisputeTile(
                            dispute: filteredItems[i],
                            onTap: () async {
                              final target =
                                  await Navigator.of(context).push<int>(
                                MaterialPageRoute<int>(
                                  builder: (_) => AdminDisputeScreen(
                                    service: widget.service,
                                    disputeId: filteredItems[i].id,
                                  ),
                                ),
                              );
                              if (target != null && target != 2) {
                                widget.onSelectTab?.call(target);
                              }
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

StatusPill _statusPill(DisputeStatus status) => switch (status) {
  DisputeStatus.pending => StatusPill(
    label: status.label,
    background: AppColors.accent100,
    color: AppColors.accent700,
    icon: LucideIcons.clock,
  ),
  DisputeStatus.underReview => StatusPill(
    label: status.label,
    background: AppColors.brand100,
    color: AppColors.brand700,
    icon: LucideIcons.search,
  ),
  DisputeStatus.resolved => StatusPill(
    label: status.label,
    background: AppColors.brand100,
    color: AppColors.success,
    icon: LucideIcons.circleCheck,
  ),
};

class _DisputeTile extends StatelessWidget {
  const _DisputeTile({required this.dispute, required this.onTap});
  final Dispute dispute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = dispute;
    return AppCard(
      key: ValueKey('dispute-tile-${d.id}'),
      onTap: onTap,
      border: Border.all(color: AppColors.borderSubtle),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              LucideIcons.triangleAlert,
              size: 22,
              color: AppColors.accent700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.serviceName.isEmpty
                      ? 'Booking #${d.bookingRef}'
                      : d.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall.copyWith(
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (d.bookingRef.isNotEmpty) '#${d.bookingRef}',
                    if (d.customerName.isNotEmpty) d.customerName,
                    if (d.amount != null) Formatters.lkr(d.amount),
                    if (d.photoCount > 0) '${d.photoCount} photos',
                    if (d.createdAt != null)
                      Formatters.shortDate(d.createdAt!.toLocal()),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.caption.copyWith(
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _statusPill(d.status),
          const SizedBox(width: 4),
          const Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.ink3,
          ),
        ],
      ),
    );
  }
}

/// One dispute for the safety desk: what was reported, the provider's answer
/// and the actions (start the review, then decide).
class AdminDisputeScreen extends StatelessWidget {
  const AdminDisputeScreen({
    super.key,
    required this.service,
    required this.disputeId,
  });
  final AdminService service;
  final String disputeId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: AppColors.ink),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Dispute',
        style: TextStyle(
          color: AppColors.brand900,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.borderSubtle,
          height: 1,
        ),
      ),
    ),
    body: SafeArea(
      child: StreamBuilder<Dispute?>(
        stream: service.watchDispute(disputeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          final dispute = snapshot.data;
          if (dispute == null) {
            return ErrorState(
              error: StateError('This dispute no longer exists.'),
            );
          }
          return _DisputeBody(service: service, dispute: dispute);
        },
      ),
    ),
    bottomNavigationBar: AppBottomNav(
      items: AppBottomNav.localizedAdminItems(context),
      selectedIndex: 2,
      onSelected: (index) => Navigator.of(context).pop(index),
    ),
  );
}

class _DisputeBody extends StatefulWidget {
  const _DisputeBody({required this.service, required this.dispute});
  final AdminService service;
  final Dispute dispute;

  @override
  State<_DisputeBody> createState() => _DisputeBodyState();
}

class _DisputeBodyState extends State<_DisputeBody> {
  late final Stream<List<DisputePhoto>> _photos = widget.service
      .watchDisputePhotos(widget.dispute.id);
  final _note = TextEditingController();
  final _refund = TextEditingController();
  String? _decision;
  bool _busy = false;

  Dispute get d => widget.dispute;

  @override
  void dispose() {
    _note.dispose();
    _refund.dispose();
    super.dispose();
  }

  bool get _refunds =>
      _decision == DisputeDecisions.fullRefund ||
      _decision == DisputeDecisions.partialRefund;

  double? get _refundValue => double.tryParse(_refund.text.trim());

  /// What is still missing before the decision can be saved (null = ready).
  String? get _problem {
    if (_decision == null) return 'Choose a decision.';
    if (_refunds) {
      final value = _refundValue;
      if (value == null || value <= 0) return 'Enter the refund amount.';
      if (d.amount != null && value > d.amount!) {
        return 'The refund cannot be more than ${Formatters.lkr(d.amount)}.';
      }
      if (_decision == DisputeDecisions.fullRefund &&
          d.amount != null &&
          value != d.amount) {
        return 'A full refund must equal ${Formatters.lkr(d.amount)}.';
      }
    }
    if (_note.text.trim().length < 5) {
      return 'Write a note for the customer (at least 5 characters).';
    }
    return null;
  }

  void _chooseDecision(String decision) => setState(() {
    _decision = decision;
    if (decision == DisputeDecisions.fullRefund && d.amount != null) {
      _refund.text = d.amount!.round().toString();
    } else if (decision == DisputeDecisions.rejected) {
      _refund.clear();
    }
  });

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-dispute-action'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnack(context, done);
    } catch (error) {
      if (mounted) showAppSnack(context, AppError.message(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Admin begins investigation - transitions state to 'underReview', locking customer from edits.
  Future<void> _startReview() async {
    if (!await _confirm(
      'Start the review?',
      'The dispute moves to Under Review and the provider is told. The '
          'customer can no longer edit or withdraw it.',
      'Start review',
    )) {
      return;
    }
    await _run(
      () => widget.service.startDisputeReview(d),
      'The dispute is now under review.',
    );
  }

  // Admin concludes dispute - applies decision (Full/Partial Refund, Rejected),
  // records optional refund amount and note, and alerts both parties.
  Future<void> _resolve() async {
    final decision = _decision!;
    if (!await _confirm(
      'Resolve this dispute?',
      decision == DisputeDecisions.rejected
          ? 'The claim is rejected and the customer sees your note.'
          : '$decision: ${Formatters.lkr(_refundValue)}. The customer sees '
                'the decision and your note.',
      'Resolve',
    )) {
      return;
    }
    await _run(
      () => widget.service.resolveDispute(
        dispute: d,
        decision: decision,
        refundAmount: _refunds ? _refundValue : null,
        note: _note.text,
      ),
      'The dispute was resolved.',
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screen,
      AppSpacing.xs,
      AppSpacing.screen,
      AppSpacing.xl,
    ),
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.serviceName.isEmpty ? 'Booking' : d.serviceName,
                    style: AppTypography.title,
                  ),
                ),
                _statusPill(d.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Booking #${d.bookingRef}', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            _Line(label: 'Customer', value: d.customerName),
            _Line(label: 'Provider', value: d.providerName),
            _Line(
              label: 'Job total',
              value: d.amount == null ? '' : Formatters.lkr(d.amount),
            ),
            if (d.createdAt != null)
              _Line(
                label: 'Filed',
                value:
                    '${Formatters.shortDate(d.createdAt!.toLocal())}, '
                    '${Formatters.clock(d.createdAt!.toLocal())}',
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      DisputeTracker(status: d.status),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Reason'),
            const SizedBox(height: 4),
            Text(
              d.tag == null ? d.reason : '${d.reason} · ${d.tag}',
              style: AppTypography.bodyStrong,
            ),
            const SizedBox(height: AppSpacing.sm),
            const SectionLabel('Customer description'),
            const SizedBox(height: 4),
            Text(d.description, style: AppTypography.body),
            StreamBuilder<List<DisputePhoto>>(
              stream: _photos,
              builder: (context, snapshot) {
                final photos = snapshot.data ?? const <DisputePhoto>[];
                if (photos.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Photos'),
                      const SizedBox(height: AppSpacing.xs),
                      DisputePhotoGrid(photos: photos),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Provider response'),
            const SizedBox(height: 4),
            Text(
              d.providerResponse ??
                  (d.respondDeadline != null &&
                          !d.canProviderRespond(DateTime.now())
                      ? 'The provider did not respond in time.'
                      : 'No response yet.'),
              key: const ValueKey('provider-response'),
              style: AppTypography.body,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      ..._actions(),
    ],
  );

  List<Widget> _actions() {
    switch (d.status) {
      case DisputeStatus.pending:
        return [
          PrimaryButton(
            key: const ValueKey('start-review'),
            label: 'Start review',
            icon: LucideIcons.searchCheck,
            busy: _busy,
            onPressed: _startReview,
          ),
        ];
      case DisputeStatus.underReview:
        final problem = _problem;
        return [
          Text('Decision', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          for (final decision in DisputeDecisions.all)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _DecisionTile(
                decision: decision,
                selected: _decision == decision,
                onTap: _busy ? null : () => _chooseDecision(decision),
              ),
            ),
          if (_refunds) ...[
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const ValueKey('refund-amount'),
              controller: _refund,
              enabled: !_busy && _decision != DisputeDecisions.fullRefund,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Refund amount (LKR)',
                hintText: 'e.g. 1500',
                helperText: d.amount == null
                    ? null
                    : 'Job total ${Formatters.lkr(d.amount)}',
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('decision-note'),
            controller: _note,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Note for the customer',
              hintText: 'Explain the decision',
            ),
          ),
          if (problem != null && (_decision != null || _note.text.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                problem,
                key: const ValueKey('resolve-problem'),
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
            ),
          PrimaryButton(
            key: const ValueKey('resolve-dispute'),
            label: 'Resolve dispute',
            icon: LucideIcons.check,
            busy: _busy,
            onPressed: problem == null ? _resolve : null,
          ),
        ];
      case DisputeStatus.resolved:
        return [
          AppCard(
            color: AppColors.successSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decision', style: AppTypography.title),
                const SizedBox(height: 4),
                Text(
                  d.decision ?? 'Resolved',
                  key: const ValueKey('dispute-decision'),
                  style: AppTypography.bodyStrong,
                ),
                if (d.refundAmount != null)
                  Text(
                    'Refund: ${Formatters.lkr(d.refundAmount)}',
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                if (d.adminNote != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(d.adminNote!, style: AppTypography.body),
                ],
              ],
            ),
          ),
        ];
    }
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => value.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Text(label, style: AppTypography.caption),
              ),
              Expanded(child: Text(value, style: AppTypography.body)),
            ],
          ),
        );
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.decision,
    required this.selected,
    required this.onTap,
  });
  final String decision;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: decision,
    child: AppCard(
      key: ValueKey('decision-$decision'),
      onTap: onTap,
      color: selected ? AppColors.brand100 : AppColors.surface,
      border: Border.all(
        color: selected ? AppColors.brand700 : AppColors.borderSubtle,
        width: selected ? 1.6 : 1,
      ),
      child: Row(
        children: [
          Icon(
            selected ? LucideIcons.circleCheck : LucideIcons.circle,
            color: selected ? AppColors.brand700 : AppColors.ink3,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(decision, style: AppTypography.bodyStrong)),
        ],
      ),
    ),
  );
}
