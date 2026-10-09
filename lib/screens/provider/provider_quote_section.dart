import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/booking.dart';
import '../../models/quote.dart';
import '../../services/provider_booking_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_theme.dart';

/// Everything a provider does about a job's price, on the job details page:
/// enter and send a quote on a new request, see that it is waiting for the
/// customer, and revise the price of a confirmed job.
///
/// The service re-checks every rule in a transaction and the security rules
/// check them again, so this widget only has to be clear, not to be trusted.
class ProviderQuoteSection extends StatefulWidget {
  const ProviderQuoteSection({
    super.key,
    required this.booking,
    required this.service,
  });

  final Booking booking;
  final ProviderBookingService service;

  @override
  State<ProviderQuoteSection> createState() => _ProviderQuoteSectionState();
}

class _ProviderQuoteSectionState extends State<ProviderQuoteSection> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  bool _revising = false;
  String? _error;

  Booking get _b => widget.booking;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  static String _message(Object error) => error is ArgumentError
      ? (error.message?.toString() ?? 'Please check the price.')
      : providerError(error);

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = QuoteInput.parseAmount(_amount.text).amount;
    if (amount == null) return;
    final revising = _b.status == BookingStatus.confirmed;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (revising) {
        await widget.service.reviseQuote(
          _b.id,
          amount,
          reason: _reason.text,
          note: _note.text,
        );
      } else {
        await widget.service.sendQuote(_b.id, amount, note: _note.text);
      }
      if (!mounted) return;
      _amount.clear();
      _note.clear();
      _reason.clear();
      setState(() => _revising = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            revising
                ? 'Revised quote sent. The customer will review it.'
                : 'Quote sent. The customer will review it.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    final expired =
        b.status == BookingStatus.pending && b.isExpired(DateTime.now());
    final children = <Widget>[];

    if (b.awaitingCustomer) {
      children.add(_awaiting(context, b));
    } else if (b.status == BookingStatus.pending) {
      children.add(
        expired
            ? _info(
                context,
                icon: Icons.schedule,
                title: 'This request has expired',
                message: 'You can no longer send a quote for it.',
              )
            : _form(context, revising: false),
      );
    } else if (b.status == BookingStatus.confirmed) {
      children.add(_approved(context, b));
      if (_revising) children.add(_form(context, revising: true));
    }

    if (b.quoteHistory.isNotEmpty) children.add(_history(context, b));
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('quote-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _info(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Color color = ProviderTheme.tealLight,
  }) => ProviderCard(
    color: color,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ProviderTheme.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: ProviderTheme.body)),
            ],
          ),
        ),
      ],
    ),
  );

  /// The quote was sent and the customer has not answered. No re-sending.
  Widget _awaiting(BuildContext context, Booking b) => ProviderCard(
    key: const ValueKey('quote-awaiting'),
    color: ProviderTheme.warningBackground,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hourglass_top, color: ProviderTheme.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                b.isRevision
                    ? 'Revision awaiting customer approval'
                    : 'Awaiting customer approval',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          Formatters.lkr(b.quotedAmount),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (b.quoteNote != null) ...[
          const SizedBox(height: 4),
          Text(b.quoteNote!, style: const TextStyle(color: ProviderTheme.body)),
        ],
        const SizedBox(height: 8),
        Text(
          b.isRevision
              ? 'The price the customer already accepted '
                    '(${Formatters.lkr(b.acceptedAmount)}) stays valid until they answer.'
              : 'You can send a new quote after the customer answers.',
          style: const TextStyle(color: ProviderTheme.muted),
        ),
      ],
    ),
  );

  /// A confirmed job: the locked price and the way to change it.
  Widget _approved(BuildContext context, Booking b) {
    final approved = b.approvedAmount;
    return ProviderCard(
      key: const ValueKey('quote-approved'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approved == null
                    ? Icons.request_quote_outlined
                    : Icons.lock_outline,
                color: ProviderTheme.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  approved == null ? 'No approved price yet' : 'Approved price',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (approved != null) ...[
            const SizedBox(height: 8),
            Text(
              Formatters.lkr(approved),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
          if (b.revisionDeclined) ...[
            const SizedBox(height: 8),
            Text(
              'The customer declined your revised price, so '
              '${Formatters.lkr(approved)} still applies.',
              style: const TextStyle(color: ProviderTheme.orange),
            ),
          ],
          if (approved == null) ...[
            const SizedBox(height: 8),
            const Text(
              'Send a price so the job can be completed and paid.',
              style: TextStyle(color: ProviderTheme.body),
            ),
          ],
          if (!_revising) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('revise-quote'),
              onPressed: () => setState(() => _revising = true),
              icon: const Icon(Icons.edit_outlined),
              label: Text(approved == null ? 'Send quote' : 'Revise quote'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _form(BuildContext context, {required bool revising}) {
    final declined = _b.quoteStatus == QuoteStatus.declined && !revising;
    return ProviderCard(
      key: ValueKey(revising ? 'revise-form' : 'quote-form'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              revising ? 'Revise your quote' : 'Enter your quote',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              revising
                  ? 'The customer must approve the new price. Until then the '
                        'current price stays.'
                  : 'The job is confirmed when the customer accepts your price.',
              style: const TextStyle(color: ProviderTheme.muted),
            ),
            if (declined) ...[
              const SizedBox(height: 10),
              Text(
                'The customer declined ${Formatters.lkr(_b.quotedAmount)}. '
                'Send a new quote or decline the request.',
                style: const TextStyle(color: ProviderTheme.orange),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('quote-amount'),
              controller: _amount,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Amount (LKR)',
                prefixText: 'LKR ',
                hintText: 'e.g. 3500',
              ),
              validator: (value) {
                final error = QuoteInput.parseAmount(value).error;
                if (error != null) return error;
                if (revising &&
                    QuoteInput.parseAmount(value).amount == _b.approvedAmount) {
                  return 'Enter a price different from the current one.';
                }
                return null;
              },
            ),
            if (revising) ...[
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('quote-reason'),
                controller: _reason,
                enabled: !_busy,
                maxLines: 2,
                maxLength: QuoteInput.maxReason,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Why is the price changing?',
                  hintText: 'e.g. Extra pipework was needed',
                ),
                validator: QuoteInput.validateReason,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('quote-note'),
              controller: _note,
              enabled: !_busy,
              maxLines: 3,
              maxLength: QuoteInput.maxNote,
              decoration: const InputDecoration(
                labelText: "What's included (optional)",
                hintText: 'e.g. Parts and labour, 1 hour',
              ),
              validator: QuoteInput.validateNote,
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Container(
                key: const ValueKey('quote-error'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ProviderTheme.warningBackground,
                  border: Border.all(color: ProviderTheme.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: ProviderTheme.red),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _submit,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppPrimaryButton(
              key: const ValueKey('send-quote'),
              label: _busy
                  ? 'Sending…'
                  : revising
                  ? 'Send revised quote'
                  : 'Send quote',
              icon: Icons.send_outlined,
              onPressed: _busy ? null : _submit,
            ),
            if (revising && !_busy)
              TextButton(
                onPressed: () => setState(() {
                  _revising = false;
                  _error = null;
                }),
                child: const Text('Cancel'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _history(BuildContext context, Booking b) {
    final entries = b.quoteHistory.reversed.toList();
    return ProviderCard(
      key: const ValueKey('quote-history'),
      // The tile paints its ink on the nearest Material; the card around it
      // has a background, so give it a clear one of its own.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Price history (${entries.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_entryLabel(e)}: ${Formatters.lkr(e.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (e.reason != null)
                        Text(
                          'Reason: ${e.reason}',
                          style: const TextStyle(color: ProviderTheme.body),
                        ),
                      if (e.note != null)
                        Text(
                          e.note!,
                          style: const TextStyle(color: ProviderTheme.body),
                        ),
                      Text(
                        dateLabel(context, e.createdAt),
                        style: const TextStyle(color: ProviderTheme.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _entryLabel(QuoteEntry e) => switch (e.status) {
    QuoteStatus.quoted =>
      e.reason != null ? 'Revised quote sent' : 'Quote sent',
    QuoteStatus.accepted => 'Customer accepted',
    QuoteStatus.declined => 'Customer declined',
    QuoteStatus.pending => 'Quote requested',
  };
}
