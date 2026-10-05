import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/booking.dart';
import '../../../models/receipt.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';
import 'feedback_sheets.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Future<(Booking?, Receipt?)>? _data;
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
  }

  Future<(Booking?, Receipt?)> _load() async {
    final service = CustomerScope.of(context).bookings;
    final results = await Future.wait([
      service.watchBooking(widget.bookingId).first,
      service.getReceipt(widget.bookingId),
    ]);
    return (results[0] as Booking?, results[1] as Receipt?);
  }

  Future<void> _export(Receipt receipt, {required bool share}) async {
    final pdf = CustomerScope.of(context).receipts;
    setState(() => _exporting = true);
    try {
      share ? await pdf.share(receipt) : await pdf.download(receipt);
    } catch (_) {
      if (mounted) {
        showAppSnack(
          context,
          'Could not create the PDF. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: FutureBuilder<(Booking?, Receipt?)>(
        future: _data,
        builder: (context, snapshot) {
          final receipt = snapshot.data?.$2;
          final header = ScreenHeader(
            title: 'Receipt',
            trailing: receipt == null
                ? null
                : CircleIconButton(
                    icon: LucideIcons.share2,
                    tooltip: 'Share receipt',
                    onPressed: _exporting
                        ? null
                        : () => _export(receipt, share: true),
                  ),
          );
          Widget body;
          if (snapshot.hasError) {
            body = ErrorState(
              error: snapshot.error!,
              onRetry: () => setState(() => _data = _load()),
            );
          } else if (snapshot.connectionState != ConnectionState.done) {
            body = const LoadingState(message: 'Fetching your receipt…');
          } else if (snapshot.data!.$1 == null) {
            body = ErrorState(
              error: StateError('This booking could not be found.'),
            );
          } else if (receipt == null) {
            body = _NotIssued(onRetry: () => setState(() => _data = _load()));
          } else {
            body = _ReceiptBody(
              booking: snapshot.data!.$1!,
              receipt: receipt,
              exporting: _exporting,
              onDownload: () => _export(receipt, share: false),
              onShare: () => _export(receipt, share: true),
            );
          }
          return Column(
            children: [
              header,
              Expanded(child: body),
            ],
          );
        },
      ),
    ),
  );
}

class _NotIssued extends StatelessWidget {
  const _NotIssued({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconTile(icon: LucideIcons.receipt, circle: true, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text('Receipt not issued yet', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your receipt appears here once the professional completes the '
            'job and you sign off.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 180,
            child: SecondaryButton(
              label: 'Check again',
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({
    required this.booking,
    required this.receipt,
    required this.exporting,
    required this.onDownload,
    required this.onShare,
  });

  final Booking booking;
  final Receipt receipt;
  final bool exporting;
  final VoidCallback onDownload, onShare;

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    final date = r.serviceDate ?? booking.scheduledAt;
    final start = r.startTime.isNotEmpty ? r.startTime : booking.startTime;
    final end = r.endTime.isNotEmpty ? r.endTime : booking.endTime;
    final firstName = r.providerName.trim().split(' ').first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        if (r.signedOffAt != null) ...[
          AppCard(
            color: AppColors.successSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(
                  icon: LucideIcons.shieldCheck,
                  circle: true,
                  size: 34,
                  color: Colors.white,
                  background: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Job Completed & Signed Off '),
                            TextSpan(
                              text: '• VERIFIED',
                              style: AppTypography.overline.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        style: AppTypography.subtitle.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'Customer digital sign-off completed on '
                        '${Formatters.shortDate(r.signedOffAt!.toLocal())}, '
                        '${Formatters.clock(r.signedOffAt!.toLocal())}.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECEIPT NO.', style: AppTypography.overline),
                        SelectableText(
                          r.receiptNumber,
                          style: AppTypography.title,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('BOOKING REF', style: AppTypography.overline),
                      const SizedBox(height: 2),
                      StatusPill(
                        label: '#${r.bookingReference}',
                        color: AppColors.primary,
                        background: AppColors.successSoft,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLavender,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.md,
                  runSpacing: 4,
                  children: [
                    if (date != null)
                      _Meta(
                        icon: LucideIcons.calendar,
                        text: Formatters.shortDate(date.toLocal()),
                      ),
                    if (start != null && end != null)
                      _Meta(
                        icon: LucideIcons.clock,
                        text: Formatters.timeRange(start, end),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonAvatar(
                    name: r.providerName,
                    photoUrl: r.providerPhotoUrl,
                    size: 50,
                    verified: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              'SERVICE PROVIDER',
                              style: AppTypography.overline,
                            ),
                            if (r.licenseNumber.isNotEmpty)
                              StatusPill(
                                label: 'Lic #${r.licenseNumber}',
                                color: AppColors.warning,
                                background: AppColors.warningSoft,
                              ),
                          ],
                        ),
                        Text(r.providerName, style: AppTypography.title),
                        if (r.providerTitle.isNotEmpty)
                          Text(r.providerTitle, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLavender,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconTile(
                      icon: LucideIcons.mapPin,
                      circle: true,
                      size: 34,
                      background: AppColors.surface,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BILLED & SERVICED AT',
                            style: AppTypography.overline,
                          ),
                          Text(r.customerName, style: AppTypography.subtitle),
                          Text(r.serviceAddress, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Itemized Breakdown',
                      style: AppTypography.title,
                    ),
                  ),
                  StatusPill(
                    label:
                        '${r.lineItems.length} Item'
                        '${r.lineItems.length == 1 ? '' : 's'}',
                    color: AppColors.primary,
                    background: AppColors.successSoft,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final item in r.lineItems)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: AppTypography.bodyStrong),
                            if (item.detail.isNotEmpty)
                              Text(item.detail, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        Formatters.lkr(item.amount),
                        style: AppTypography.bodyStrong,
                      ),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL PAID',
                            style: AppTypography.overline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Net paid incl. all taxes & fees',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Formatters.lkr(r.totalAmount),
                            style: AppTypography.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  if (r.cardLast4 != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLavenderDeep,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VISA',
                        style: AppTypography.label.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.cardLast4 == null
                              ? _titleCase(r.paymentMethod)
                              : 'Visa ending in •• ${r.cardLast4}',
                          style: AppTypography.subtitle,
                        ),
                        Text(
                          r.paymentStatus == 'paid'
                              ? 'Escrow settlement complete'
                              : _titleCase(r.paymentStatus),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.lock, color: AppColors.primary),
                ],
              ),
              if (r.paymentNote.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLavender,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.banknote,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          r.paymentNote,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.soft,
                ),
                child: QrImageView(
                  data: r.verificationPayload,
                  size: 130,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.navy,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.navy,
                  ),
                  semanticsLabel: 'Receipt verification QR code',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Receipt Verification Code', style: AppTypography.subtitle),
              const SizedBox(height: 2),
              Text(
                'Scan to verify this HomeCare receipt, its booking reference '
                'and the amount paid.',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Download PDF',
                icon: LucideIcons.fileDown,
                busy: exporting,
                onPressed: onDownload,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PrimaryButton(
                label: 'Share Receipt',
                icon: LucideIcons.send,
                busy: exporting,
                onPressed: onShare,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.star_rounded, color: AppColors.star),
                title: Text(
                  'Rate & Review ${firstName.isEmpty ? 'your pro' : firstName}',
                  style: AppTypography.subtitle,
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () => showReviewSheet(context, booking, firstName),
              ),
              const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
              ListTile(
                leading: const Icon(
                  LucideIcons.alertTriangle,
                  color: AppColors.danger,
                ),
                title: Text(
                  'Report a Problem / Dispute',
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.danger,
                  ),
                ),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.danger,
                ),
                onTap: () => showDisputeSheet(context, booking),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const InfoBanner(
          title: 'HomeCare 30-Day Workmanship Cover',
          message:
              'All parts and labor include 30-day free recall protection '
              'across Colombo & Gampaha districts.',
          icon: LucideIcons.badgeCheck,
          iconFilled: false,
          background: AppColors.surfaceLavender,
        ),
      ],
    );
  }

  static String _titleCase(String text) => text.isEmpty
      ? ''
      : text
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.body),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: AppTypography.bodyStrong)),
    ],
  );
}
