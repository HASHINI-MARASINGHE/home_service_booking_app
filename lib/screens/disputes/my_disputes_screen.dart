import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/dispute.dart';
import '../../services/dispute_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../customer/disputes/dispute_screen.dart';
import '../provider/provider_dispute_screen.dart';
import '../provider/provider_theme.dart';

/// Every dispute the signed-in customer filed (or, with [asProvider], every
/// dispute about the provider's jobs), with its status. Tapping one opens the
/// same tracking screen the notifications open.
class MyDisputesScreen extends StatefulWidget {
  const MyDisputesScreen({super.key, this.asProvider = false, this.service});
  final bool asProvider;

  /// Injected by tests; the real service is used otherwise.
  final DisputeService? service;

  @override
  State<MyDisputesScreen> createState() => _MyDisputesScreenState();
}

class _MyDisputesScreenState extends State<MyDisputesScreen> {
  late final DisputeService _service = widget.service ?? DisputeService();
  late Stream<List<Dispute>> _disputes = _service.watchMyDisputes(
    asProvider: widget.asProvider,
  );

  void _open(Dispute dispute) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => widget.asProvider
          // Keep the provider look on the screen opened from here.
          ? Theme(
              data: ProviderTheme.data,
              child: ProviderDisputeScreen(bookingId: dispute.bookingId),
            )
          : DisputeScreen(bookingId: dispute.bookingId),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My disputes')),
    body: SafeArea(
      child: StreamBuilder<List<Dispute>>(
        stream: _disputes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your disputes could not be loaded.',
                      textAlign: TextAlign.center,
                    ),
                    if (snapshot.error is FirebaseException &&
                        (snapshot.error! as FirebaseException).code ==
                            'permission-denied')
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Access denied: publish the latest firestore.rules '
                          '(Firebase Console > Firestore > Rules > Publish), '
                          'then tap Try again.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(
                        () => _disputes = _service.watchMyDisputes(
                          asProvider: widget.asProvider,
                        ),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final disputes = snapshot.data!;
          if (disputes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: EmptyState(
                  icon: LucideIcons.scale,
                  title: widget.asProvider
                      ? 'No disputes filed'
                      : 'No disputes yet',
                  message: widget.asProvider
                      ? 'No disputes have been filed about your jobs.'
                      : 'You have not filed any disputes.',
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: disputes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _DisputeTile(
              dispute: disputes[index],
              asProvider: widget.asProvider,
              onTap: () => _open(disputes[index]),
            ),
          );
        },
      ),
    ),
  );
}

class _DisputeTile extends StatelessWidget {
  const _DisputeTile({
    required this.dispute,
    required this.asProvider,
    required this.onTap,
  });
  final Dispute dispute;
  final bool asProvider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final (background, color) = switch (dispute.status) {
      DisputeStatus.pending => (AppColors.warningSoft, AppColors.warningText),
      DisputeStatus.underReview => (AppColors.brand100, AppColors.brand900),
      DisputeStatus.resolved => (AppColors.successSoft, AppColors.successText),
    };
    final title = dispute.serviceName.isEmpty
        ? dispute.reason
        : dispute.serviceName;
    final who = asProvider ? dispute.customerName : dispute.providerName;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        key: ValueKey('dispute-${dispute.id}'),
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: styles.label),
                    const SizedBox(height: 2),
                    Text(
                      who.isEmpty ? dispute.reason : '$who · ${dispute.reason}',
                      style: styles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  dispute.status.label,
                  style: styles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
