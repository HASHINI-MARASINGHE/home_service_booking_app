import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/customer_home_theme.dart';
import '../customer_scope.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  Future<void> _openReportProblemDialog() async {
    final formKey = GlobalKey<FormState>();
    final issueDescCtrl = TextEditingController();
    String category = 'Service Quality';
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                      'Report a Problem',
                      style: TextStyle(
                        color: CustomerHomeTheme.primaryDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: 'Issue Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Service Quality',
                      child: Text('Service Quality'),
                    ),
                    DropdownMenuItem(
                      value: 'Billing & Payment',
                      child: Text('Billing & Payment'),
                    ),
                    DropdownMenuItem(
                      value: 'Provider Late / No-Show',
                      child: Text('Provider Late / No-Show'),
                    ),
                    DropdownMenuItem(
                      value: 'App Technical Issue',
                      child: Text('App Technical Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other Inquiry'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => category = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: issueDescCtrl,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Describe the issue',
                    hintText: 'Provide details so our team can help you promptly...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 10) {
                      return 'Please provide at least 10 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomerHomeTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setSheetState(() => submitting = true);
                            await Future<void>.delayed(
                              const Duration(milliseconds: 600),
                            );
                            if (sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Problem reported successfully. Ticket #HC-8921 opened.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: AppSpacing.lg,
          ),
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(
                color: CustomerHomeTheme.primaryDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browse FAQs or reach out directly to our dedicated customer care team.',
              style: TextStyle(
                color: CustomerHomeTheme.mutedText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Quick action cards
            Row(
              children: [
                Expanded(
                  child: _HelpActionCard(
                    icon: Icons.phone_in_talk_outlined,
                    title: 'Call Hotline',
                    subtitle: '1344 (Toll-Free)',
                    onTap: () => launchContact(
                      context,
                      'tel',
                      homeCareHotline,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HelpActionCard(
                    icon: Icons.mail_outline,
                    title: 'Email Us',
                    subtitle: 'support@homecare.app',
                    onTap: () => launchContact(
                      context,
                      'mailto',
                      'support@homecare.app',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HelpBannerCard(
              icon: Icons.report_problem_outlined,
              title: 'Report a Problem',
              subtitle: 'Having an issue with a booking, provider, or payment? Let us know.',
              buttonLabel: 'File Ticket',
              onTap: _openReportProblemDialog,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: CustomerHomeTheme.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _FaqCard(
              title: 'How do I book a home service?',
              answer:
                  'Choose a category from the Home tab, browse verified professionals, choose your desired date and time, and confirm your request. You will receive real-time notifications as soon as the provider accepts.',
            ),
            _FaqCard(
              title: 'How are service providers verified?',
              answer:
                  'All professionals on HomeCare undergo mandatory government ID verification, background checks, trade certification, and skill validation before they receive a verified badge.',
            ),
            _FaqCard(
              title: 'Can I cancel or reschedule a booking?',
              answer:
                  'Yes. Go to the Bookings tab, select your upcoming job, and tap "Reschedule" or "Cancel Booking". Cancellations made more than 2 hours before the scheduled time incur no penalty.',
            ),
            _FaqCard(
              title: 'What payment options are available?',
              answer:
                  'We support credit/debit cards (Visa, Mastercard) securely in-app, as well as Cash on Service directly to your provider after work is completed.',
            ),
            _FaqCard(
              title: 'What should I do if a provider is delayed?',
              answer:
                  'You can call or message the provider directly from your booking details screen. If you cannot reach them, call our support hotline (1344) and we will assist right away.',
            ),
            _FaqCard(
              title: 'How do refunds and disputes work?',
              answer:
                  'If you are unsatisfied with a completed job or believe a charge was incorrect, you can open a dispute from your booking receipt within 48 hours. Our resolution team reviews disputes within 24 hours.',
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                'Customer Care Operating Hours:\n8:00 AM – 8:00 PM (Daily)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpActionCard extends StatelessWidget {
  const _HelpActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CustomerHomeTheme.border),
            boxShadow: const [
              BoxShadow(
                color: CustomerHomeTheme.shadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: CustomerHomeTheme.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: CustomerHomeTheme.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: CustomerHomeTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: CustomerHomeTheme.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpBannerCard extends StatelessWidget {
  const _HelpBannerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand700.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CustomerHomeTheme.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CustomerHomeTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand700,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            onPressed: onTap,
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.title, required this.answer});

  final String title;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CustomerHomeTheme.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          title: Text(
            title,
            style: const TextStyle(
              color: CustomerHomeTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: CustomerHomeTheme.mutedText,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
