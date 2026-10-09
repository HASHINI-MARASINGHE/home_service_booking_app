import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/service_category.dart';
import '../../theme/app_theme.dart';
import 'motion_widgets.dart';

/// The photo behind each service card, by [ServiceCategory.id]. Add the
/// pictures to `assets/services/`; until one exists the card shows a dark
/// blue gradient with the service icon instead.
const serviceCategoryPhotos = <String, String>{
  'plumbing': 'assets/services/plumbing.jpg',
  'electrical': 'assets/services/electrical.jpg',
  'ac': 'assets/services/ac_cooling.jpg',
  'cleaning': 'assets/services/cleaning.jpg',
  'painting': 'assets/services/painting.jpg',
  'carpentry': 'assets/services/carpentry.jpg',
  'appliance': 'assets/services/appliances.jpg',
  'gardening': 'assets/services/gardening.jpg',
};

/// A photo card for one kind of service: the name and provider count over a
/// dark fade at the bottom, the icon in a frosted circle at the top left.
/// The chosen card gets a white ring, a glow and a check badge.
class ServiceCategoryCard extends StatelessWidget {
  const ServiceCategoryCard({
    super.key,
    required this.category,
    required this.label,
    required this.detail,
    required this.onTap,
    this.selected = false,
    this.semanticsLabel,
  });

  static const width = 150.0;
  static const height = 190.0;
  static const _radius = 20.0;
  static const _fade = Duration(milliseconds: 250);

  final ServiceCategory category;

  /// The service name in the current language.
  final String label;

  /// The line under the name, such as "3 providers".
  final String detail;
  final VoidCallback onTap;
  final bool selected;

  /// What a screen reader says; defaults to [label].
  final String? semanticsLabel;

  Widget _fallback(Color color) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brand700, AppColors.brand900],
      ),
    ),
    child: Center(
      child: Icon(category.icon, size: 56, color: color.withValues(alpha: .35)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final primary = Theme.of(context).colorScheme.primary;
    final photo = serviceCategoryPhotos[category.id];
    final borderRadius = BorderRadius.circular(_radius);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: AppPressable(
        child: AnimatedContainer(
          duration: _fade,
          curve: Curves.easeOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: selected
                    ? primary.withValues(alpha: .45)
                    : Colors.black.withValues(alpha: .12),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // The ring sits on top of the photo so nothing shifts when chosen.
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photo == null)
                      _fallback(Colors.white)
                    else
                      Image.asset(
                        photo,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => _fallback(Colors.white),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              category.icon,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: _fade,
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: styles.label.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: styles.caption.copyWith(
                              color: Colors.white.withValues(alpha: .7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
