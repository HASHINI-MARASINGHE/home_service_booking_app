import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Picks an icon for a provider's free-text service or profession.
IconData serviceIcon(String text) {
  final t = text.toLowerCase();
  if (t.contains('electric') || t.contains('wiring')) return LucideIcons.zap;
  if (t.contains('plumb') || t.contains('pipe') || t.contains('leak')) {
    return LucideIcons.droplets;
  }
  if (t.contains('clean') || t.contains('disinfect')) {
    return LucideIcons.sparkles;
  }
  if (RegExp(r'\bac\b').hasMatch(t) ||
      t.contains('air con') ||
      t.contains('cool')) {
    return LucideIcons.snowflake;
  }
  if (t.contains('carpent') || t.contains('furniture') || t.contains('wood')) {
    return LucideIcons.hammer;
  }
  if (t.contains('paint')) return LucideIcons.paintbrush;
  if (t.contains('garden') || t.contains('lawn')) return LucideIcons.leaf;
  return LucideIcons.wrench;
}
