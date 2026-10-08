import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/dispute.dart';
import '../../services/app_error.dart';
import '../../services/dispute_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/provider/provider_widgets.dart';
import '../customer/disputes/dispute_screen.dart';
import '../customer/disputes/dispute_widgets.dart';
import 'provider_theme.dart';

/// A dispute a customer filed about this provider's job. The provider reads
/// what was reported (with photos) and can answer until the 24-hour deadline.
class ProviderDisputeScreen extends StatefulWidget {
  const ProviderDisputeScreen({
    super.key,
    required this.bookingId,
    this.service,
  });
  final String bookingId;

  /// Injected by tests; the real service is used otherwise.
  final DisputeService? service;

  @override
  State<ProviderDisputeScreen> createState() => _ProviderDisputeScreenState();
}

class _ProviderDisputeScreenState extends State<ProviderDisputeScreen> {
  late final DisputeService _service =
      widget.service ?? DisputeScreen.serviceFactory();
  late Stream<Dispute?> _dispute = _service.watchDispute(widget.bookingId);
  late Stream<List<DisputePhoto>> _photos = _service.watchPhotos(
    widget.bookingId,
  );
  final _response = TextEditingController();
  bool _filled = false, _busy = false;
  late DateTime _now = _service.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keep the "time left to respond" fresh while the screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = _service.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _response.dispose();
    super.dispose();
  }

  void _retry() => setState(() {
    _dispute = _service.watchDispute(widget.bookingId);
    _photos = _service.watchPhotos(widget.bookingId);
  });

  // Submits the provider's statement or resolution offer to the safety desk.
  Future<void> _send(Dispute dispute) async {
    setState(() => _busy = true);
    try {
      await _service.respond(dispute: dispute, response: _response.text);
      if (mounted) {
        showSnack('Your response was sent.');
      }
    } catch (error) {
      if (mounted) showSnack(AppError.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void showSnack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// "Respond within 21 hours 5 minutes" / "Response window closed".
  // Dynamic countdown calculation for the provider's 24-hour response window.
  String _deadlineLabel(Dispute dispute) {
    final deadline = dispute.respondDeadline;
    if (deadline == null) return '';
    if (!_now.isBefore(deadline)) return 'Response window closed';
    final left = deadline.difference(_now);
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    return hours > 0
        ? 'Respond within $hours hour${hours == 1 ? '' : 's'} '
              '$minutes minute${minutes == 1 ? '' : 's'}'
        : 'Respond within ${minutes < 1 ? 1 : minutes} minute'
              '${minutes == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dispute')),
    body: SafeArea(
      child: StreamBuilder<Dispute?>(
        stream: _dispute,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ProviderFailure(error: snapshot.error, onRetry: _retry);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final dispute = snapshot.data;
          if (dispute == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This dispute is no longer available. The customer may '
                  'have withdrawn it.',
                  key: ValueKey('dispute-gone'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!_filled) {
            _filled = true;
            _response.text = dispute.providerResponse ?? '';
          }
          return _body(dispute);
        },
      ),
    ),
  );

  Widget _body(Dispute d) {
    final canRespond = d.canProviderRespond(_now);
    final text = _response.text.trim();
    return ProviderPage(
      children: [
        ProviderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.serviceName.isEmpty ? 'Reported job' : d.serviceName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Booking #${d.bookingRef}'
                '${d.customerName.isEmpty ? '' : ' · ${d.customerName}'}',
                style: const TextStyle(color: ProviderTheme.muted),
              ),
              if (d.amount != null) ...[
                const SizedBox(height: 4),
                Text(
                  money(d.amount),
                  style: const TextStyle(
                    color: ProviderTheme.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DisputeTracker(status: d.status),
            ],
          ),
        ),
        ProviderCard(
          color: d.status == DisputeStatus.resolved
              ? ProviderTheme.tealLight
              : ProviderTheme.warningBackground,
          child: Row(
            children: [
              Icon(
                d.status == DisputeStatus.resolved
                    ? Icons.check_circle_outline
                    : Icons.schedule,
                color: d.status == DisputeStatus.resolved
                    ? ProviderTheme.teal
                    : ProviderTheme.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.status == DisputeStatus.resolved
                      ? 'The safety desk has decided this dispute.'
                      : _deadlineLabel(d),
                  key: const ValueKey('respond-deadline'),
                  style: const TextStyle(
                    color: ProviderTheme.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ProviderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What was reported', style: _label),
              const SizedBox(height: 6),
              Text(
                d.tag == null ? d.reason : '${d.reason} · ${d.tag}',
                style: const TextStyle(
                  color: ProviderTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(d.description),
              if (d.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Filed ${Formatters.shortDate(d.createdAt!.toLocal())}, '
                  '${Formatters.clock(d.createdAt!.toLocal())}',
                  style: const TextStyle(
                    color: ProviderTheme.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
              StreamBuilder<List<DisputePhoto>>(
                stream: _photos,
                builder: (context, snapshot) {
                  final photos = snapshot.data ?? const <DisputePhoto>[];
                  if (photos.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photos', style: _label),
                        const SizedBox(height: 8),
                        DisputePhotoGrid(photos: photos),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (d.status == DisputeStatus.resolved)
          ProviderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decision', style: _label),
                const SizedBox(height: 6),
                Text(
                  d.decision ?? 'Resolved',
                  key: const ValueKey('dispute-decision'),
                  style: const TextStyle(
                    color: ProviderTheme.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (d.refundAmount != null)
                  Text('Refund to the customer: ${money(d.refundAmount)}'),
                if (d.adminNote != null) ...[
                  const SizedBox(height: 6),
                  Text(d.adminNote!),
                ],
              ],
            ),
          ),
        ProviderCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your response', style: _label),
              const SizedBox(height: 8),
              if (canRespond) ...[
                TextField(
                  key: const ValueKey('provider-response-field'),
                  controller: _response,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: DisputeService.maxDescription,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Tell the safety desk your side of the story',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('send-response'),
                    onPressed:
                        !_busy && text.length >= DisputeService.minResponse
                        ? () => _send(d)
                        : null,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            d.providerResponse == null
                                ? 'Send response'
                                : 'Update response',
                          ),
                  ),
                ),
              ] else
                Text(
                  d.providerResponse ??
                      'You did not respond before the deadline.',
                  key: const ValueKey('response-readonly'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static const _label = TextStyle(
    color: ProviderTheme.muted,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
}
