import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/booking.dart';
import '../../models/service_category.dart';
import '../../theme/app_theme.dart';

/// Small helpers shared by the provider's job cards.

/// The icon of the service category a job belongs to (a briefcase when none
/// matches).
IconData serviceIconFor(String serviceName) {
  final text = ' $serviceName '.toLowerCase();
  for (final category in ServiceCategory.all) {
    if (category.keywords.any(text.contains)) return category.icon;
  }
  return LucideIcons.briefcase;
}

/// "Neshan Perera" becomes "NP"; one name gives one letter.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// What the customer pays: the job total, else the estimate (null = not set).
double? jobAmount(Booking b) => b.totalAmount ?? b.estimatedPrice;

/// "Est. 1h 30m" from the booked slot (null when the slot has no end).
String? estimatedDuration(Booking b) {
  final start = b.scheduledAt, end = b.endAt;
  if (start == null || end == null || !end.isAfter(start)) return null;
  final length = end.difference(start);
  final hours = length.inHours;
  final minutes = length.inMinutes % 60;
  return hours == 0
      ? 'Est. ${minutes}m'
      : 'Est. ${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

/// The first line of the customer's job notes, if there are any.
String? jobNoteLine(Booking b) {
  final first = b.jobNotes.trim().split('\n').first.trim();
  return first.isEmpty ? null : first;
}

/// Shared look of the white job cards.
BoxDecoration jobCardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: AppRadius.card,
  border: Border.all(
    color: AppColors.borderSubtle,
    width: AppSizes.borderControl,
  ),
);

/// A rounded square with an icon, like the service icon on a job card.
class JobIconTile extends StatelessWidget {
  const JobIconTile({
    super.key,
    required this.icon,
    this.color = AppColors.brand700,
    this.background = AppColors.brand100,
  });
  final IconData icon;
  final Color color, background;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Icon(icon, color: color, size: 24),
  );
}

/// A round avatar with the customer's initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.background = AppColors.brand100,
    this.color = AppColors.brand900,
  });
  final String name;
  final double size;
  final Color background, color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Text(
      initialsOf(name),
      style: context.textStyles.label.copyWith(color: color),
    ),
  );
}

/// An icon and a line of text, like the date or the address on a job card.
class JobInfoRow extends StatelessWidget {
  const JobInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.secondary,
    this.strong = false,
    this.iconColor = AppColors.brand700,
  });
  final IconData icon;
  final String text;
  final String? secondary;
  final bool strong;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: strong ? styles.label : styles.bodySmall),
              if (secondary != null && secondary!.isNotEmpty)
                Text(secondary!, style: styles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
