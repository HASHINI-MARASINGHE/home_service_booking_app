import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../screens/customer/settings/payment_methods_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../common/app_widgets.dart';

class PaymentSelectionResult {
  const PaymentSelectionResult({
    required this.method,
    this.cardLast4,
    this.cardBrand,
  });

  final String method; // 'cash' or 'card'
  final String? cardLast4;
  final String? cardBrand;
}

/// A modal sheet allowing the customer to select how they want to pay for
/// the home service: Cash on Service or a Credit/Debit Card.
class PaymentMethodSelectionSheet extends StatefulWidget {
  const PaymentMethodSelectionSheet({
    super.key,
    required this.amount,
    this.initialMethod,
    this.initialCardLast4,
  });

  final double amount;
  final String? initialMethod;
  final String? initialCardLast4;

  static Future<PaymentSelectionResult?> show(
    BuildContext context, {
    required double amount,
    String? initialMethod,
    String? initialCardLast4,
  }) {
    return showModalBottomSheet<PaymentSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSelectionSheet(
        amount: amount,
        initialMethod: initialMethod,
        initialCardLast4: initialCardLast4,
      ),
    );
  }

  @override
  State<PaymentMethodSelectionSheet> createState() =>
      _PaymentMethodSelectionSheetState();
}

class _PaymentMethodSelectionSheetState
    extends State<PaymentMethodSelectionSheet> {
  String _selectedMethod = 'cash';
  List<PaymentMethodItem> _cards = [];
  PaymentMethodItem? _selectedCard;
  bool _loadingCards = true;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod == 'card' ? 'card' : 'cash';
    _loadCards();
  }

  Future<void> _loadCards() async {
    final defaultCard = await loadDefaultPaymentCard();
    // In our mock settings, we can read default card or fallback to standard ones
    PaymentMethodItem? chosen = defaultCard;
    if (widget.initialCardLast4 != null && defaultCard?.last4 != widget.initialCardLast4) {
      // Keep initial if specified
    }

    if (mounted) {
      setState(() {
        _loadingCards = false;
        _selectedCard = chosen;
      });
    }
  }

  Future<void> _openManageCards() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
    // Reload cards after returning
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetRadius)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Method',
                  style: AppTypography.title.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Amount to pay: ${Formatters.lkr(widget.amount)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Cash on Service Option
            _PaymentOptionTile(
              isSelected: _selectedMethod == 'cash',
              icon: LucideIcons.banknote,
              title: 'Cash on Service',
              subtitle: 'Pay directly in cash to your professional upon completion',
              onTap: () => setState(() => _selectedMethod = 'cash'),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Credit / Debit Card Option
            _PaymentOptionTile(
              isSelected: _selectedMethod == 'card',
              icon: LucideIcons.creditCard,
              title: 'Credit / Debit Card',
              subtitle: _selectedCard != null
                  ? '${_selectedCard!.brand} •••• ${_selectedCard!.last4} (${_selectedCard!.isDefault ? 'Default' : 'Saved'})'
                  : 'Pay securely using your saved bank card',
              trailing: _selectedMethod == 'card'
                  ? TextButton(
                      onPressed: _openManageCards,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Change Card', style: TextStyle(fontSize: 12)),
                    )
                  : null,
              onTap: () {
                setState(() => _selectedMethod = 'card');
              },
            ),

            if (_selectedMethod == 'card' && _selectedCard == null && !_loadingCards) ...[
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: _openManageCards,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add or select a card'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.controlRadius),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Confirm & Continue',
              icon: LucideIcons.check,
              onPressed: () {
                if (_selectedMethod == 'card' && _selectedCard == null) {
                  showAppSnack(
                    context,
                    'Please add a credit or debit card before continuing.',
                    error: true,
                  );
                  _openManageCards();
                  return;
                }
                Navigator.pop(
                  context,
                  PaymentSelectionResult(
                    method: _selectedMethod,
                    cardLast4: _selectedMethod == 'card' ? _selectedCard?.last4 : null,
                    cardBrand: _selectedMethod == 'card' ? _selectedCard?.brand : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final bool isSelected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand100.withValues(alpha: 0.3) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLavender,
                borderRadius: BorderRadius.circular(AppRadius.controlRadius),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.body),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ] else ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.border,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
