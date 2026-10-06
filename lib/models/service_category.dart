import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'professional.dart';

/// A kind of home service shown on the customer home screen. A provider
/// belongs to every category whose keywords appear in what they do (their
/// profession and listed services), so no extra data entry is needed.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.keywords,
  });

  final String id, label;
  final IconData icon;
  final List<String> keywords;

  static const all = [
    ServiceCategory(
      id: 'plumbing',
      label: 'Plumbing',
      icon: LucideIcons.wrench,
      keywords: ['plumb', 'pipe', 'sanit', 'drain', 'leak'],
    ),
    ServiceCategory(
      id: 'electrical',
      label: 'Electrical',
      icon: LucideIcons.zap,
      keywords: ['electric', 'wiring', 'wireman'],
    ),
    ServiceCategory(
      id: 'ac',
      label: 'AC & Cooling',
      icon: LucideIcons.snowflake,
      keywords: ['air cond', 'a/c', 'cooling', 'refrigerat', ' ac ', 'ac '],
    ),
    ServiceCategory(
      id: 'cleaning',
      label: 'Cleaning',
      icon: LucideIcons.sparkles,
      keywords: ['clean', 'disinfect', 'housekeep', 'maid'],
    ),
    ServiceCategory(
      id: 'painting',
      label: 'Painting',
      icon: LucideIcons.paintbrush,
      keywords: ['paint'],
    ),
    ServiceCategory(
      id: 'carpentry',
      label: 'Carpentry',
      icon: LucideIcons.hammer,
      keywords: ['carpent', 'furniture', 'wood'],
    ),
    ServiceCategory(
      id: 'appliance',
      label: 'Appliances',
      icon: LucideIcons.plug,
      keywords: ['appliance', 'washing machine', 'fridge', 'microwave'],
    ),
    ServiceCategory(
      id: 'gardening',
      label: 'Gardening',
      icon: LucideIcons.sprout,
      keywords: ['garden', 'landscap', 'lawn'],
    ),
  ];

  static String _haystack(Professional p) =>
      ' ${p.specialty} ${p.services.join(' ')} '.toLowerCase();

  bool matches(Professional p) {
    final text = _haystack(p);
    return keywords.any(text.contains);
  }

  /// How many of [professionals] belong to this category.
  int count(List<Professional> professionals) =>
      professionals.where(matches).length;
}
