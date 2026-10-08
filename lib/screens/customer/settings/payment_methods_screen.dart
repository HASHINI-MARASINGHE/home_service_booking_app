import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';

class PaymentMethodItem {
  PaymentMethodItem({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expiry,
    this.isDefault = false,
  });

  final String id;
  final String brand;
  final String last4;
  final String holderName;
  final String expiry;
  bool isDefault;

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'last4': last4,
    'holderName': holderName,
    'expiry': expiry,
    'isDefault': isDefault,
  };

  factory PaymentMethodItem.fromJson(Map<String, dynamic> json) =>
      PaymentMethodItem(
        id: json['id'] as String,
        brand: json['brand'] as String,
        last4: json['last4'] as String,
        holderName: json['holderName'] as String,
        expiry: json['expiry'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  static const _kCardsKey = 'saved_payment_cards_v1';

  List<PaymentMethodItem> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCardsKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => PaymentMethodItem.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _cards = list;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    // Default sample cards for immediate real-world experience
    final initial = [
      PaymentMethodItem(
        id: 'card_1',
        brand: 'Visa',
        last4: '4521',
        holderName: 'Dilshan Perera',
        expiry: '08/28',
        isDefault: true,
      ),
      PaymentMethodItem(
        id: 'card_2',
        brand: 'Mastercard',
        last4: '8820',
        holderName: 'Dilshan Perera',
        expiry: '11/27',
        isDefault: false,
      ),
    ];
    setState(() {
      _cards = initial;
      _loading = false;
    });
    _persistCards(initial);
  }

  Future<void> _persistCards(List<PaymentMethodItem> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCardsKey,
        jsonEncode(cards.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _setDefault(PaymentMethodItem target) {
    setState(() {
      for (final card in _cards) {
        card.isDefault = card.id == target.id;
      }
    });
    _persistCards(_cards);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${target.brand} •••• ${target.last4} set as default payment method.'),
      ),
    );
  }

  Future<void> _deleteCard(PaymentMethodItem card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove payment card?'),
        content: Text(
          'Are you sure you want to remove ${card.brand} ending in ${card.last4}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _cards.removeWhere((c) => c.id == card.id);
      if (card.isDefault && _cards.isNotEmpty) {
        _cards.first.isDefault = true;
      }
    });
    _persistCards(_cards);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment card removed.')),
      );
    }
  }

  Future<void> _openAddCardDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();

    final added = await showModalBottomSheet<PaymentMethodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Payment Card',
                    style: TextStyle(
                      color: CustomerHomeTheme.primaryDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Cardholder name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (val) {
                  final clean = (val ?? '').replaceAll(' ', '');
                  if (clean.length < 15 || clean.length > 19) {
                    return 'Enter a valid 16-digit card number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: expiryCtrl,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        hintText: '09/28',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || !RegExp(r'^\d{2}\/\d{2}$').hasMatch(val.trim())) {
                          return 'Format MM/YY';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: cvvCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        final clean = (val ?? '').trim();
                        if (clean.length < 3 || clean.length > 4) {
                          return '3-4 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: CustomerHomeTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final cleanNum = numberCtrl.text.replaceAll(' ', '');
                    final last4 = cleanNum.substring(cleanNum.length - 4);
                    final brand = cleanNum.startsWith('4') ? 'Visa' : 'Mastercard';
                    final item = PaymentMethodItem(
                      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                      brand: brand,
                      last4: last4,
                      holderName: nameCtrl.text.trim(),
                      expiry: expiryCtrl.text.trim(),
                      isDefault: _cards.isEmpty,
                    );
                    Navigator.pop(context, item);
                  }
                },
                child: const Text(
                  'Save Card',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (added != null && mounted) {
      setState(() => _cards.add(added));
      _persistCards(_cards);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card added successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerHomeTheme.background,
      appBar: AppBar(
        backgroundColor: CustomerHomeTheme.background,
        foregroundColor: CustomerHomeTheme.primaryDark,
        elevation: 0,
        title: const Text(
          'Payment Methods',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  const Text(
                    'Your Payment Options',
                    style: TextStyle(
                      color: CustomerHomeTheme.primaryDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage your saved cards and preferred payment options for home bookings.',
                    style: TextStyle(
                      color: CustomerHomeTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Cards',
                        style: TextStyle(
                          color: CustomerHomeTheme.primaryDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddCardDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Card'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_cards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: CustomerHomeTheme.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No saved cards yet. Tap Add Card to add one.',
                          style: TextStyle(color: CustomerHomeTheme.mutedText),
                        ),
                      ),
                    )
                  else
                    ..._cards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CardItemWidget(
                          card: card,
                          onSetDefault: () => _setDefault(card),
                          onDelete: () => _deleteCard(card),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Service Payment',
                    style: TextStyle(
                      color: CustomerHomeTheme.primaryDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CustomerHomeTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: CustomerHomeTheme.shadow,
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: CustomerHomeTheme.mint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: CustomerHomeTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Cash on Service',
                                    style: TextStyle(
                                      color: CustomerHomeTheme.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brand100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Available',
                                      style: TextStyle(
                                        color: CustomerHomeTheme.primaryDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pay in cash directly to your service provider after job completion and satisfaction.',
                                style: TextStyle(
                                  color: CustomerHomeTheme.mutedText,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: CustomerHomeTheme.mutedText,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '256-bit encrypted • PCI-DSS compliant',
                        style: TextStyle(
                          color: CustomerHomeTheme.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _CardItemWidget extends StatelessWidget {
  const _CardItemWidget({
    required this.card,
    required this.onSetDefault,
    required this.onDelete,
  });

  final PaymentMethodItem card;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isDefault ? AppColors.brand700 : CustomerHomeTheme.border,
          width: card.isDefault ? 1.8 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: CustomerHomeTheme.shadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: card.isDefault ? AppColors.brand100 : CustomerHomeTheme.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    card.brand == 'Visa'
                        ? Icons.credit_card_rounded
                        : Icons.credit_card_outlined,
                    color: AppColors.brand700,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${card.brand} •••• ${card.last4}',
                          style: const TextStyle(
                            color: CustomerHomeTheme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (card.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brand700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${card.holderName} • Expires ${card.expiry}',
                      style: const TextStyle(
                        color: CustomerHomeTheme.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: CustomerHomeTheme.mutedText),
                onSelected: (value) {
                  if (value == 'default') onSetDefault();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (!card.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as default'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Remove card',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
