import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';

/// Reusable search input component styled to match the HomeCare design system.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search…',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.prefixIcon = LucideIcons.search,
    this.trailing,
    this.fieldKey,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final IconData prefixIcon;
  final Widget? trailing;
  final Key? fieldKey;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _internalController = true;
    } else {
      _controller = widget.controller!;
    }
    _controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller.removeListener(_onTextChange);
      if (_internalController) _controller.dispose();
      _controller = widget.controller!;
      _internalController = false;
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChange() {
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Icon(widget.prefixIcon, size: 18, color: AppColors.ink3),
          ),
          Expanded(
            child: TextField(
              key: widget.fieldKey,
              controller: _controller,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              style: AppTypography.body.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.body.copyWith(color: AppColors.ink3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.ink3),
              tooltip: 'Clear',
              onPressed: _clear,
            ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

/// A filter option item used in [AppFilterChipBar].
class FilterItem<T> {
  const FilterItem({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? count;
}

/// A horizontal scrolling filter chip bar for selection.
class AppFilterChipBar<T> extends StatelessWidget {
  const AppFilterChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
  });

  final List<FilterItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          _FilterChipItem<T>(
            item: items[i],
            isSelected: items[i].value == selected,
            onTap: () => onSelected(items[i].value),
          ),
        ],
      ],
    ),
  );
}

class _FilterChipItem<T> extends StatelessWidget {
  const _FilterChipItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final FilterItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppColors.brand700 : AppColors.surface;
    final fg = isSelected ? Colors.white : AppColors.ink2;
    final border = isSelected ? AppColors.brand700 : AppColors.borderSubtle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chip,
          side: BorderSide(color: border, width: isSelected ? 1.5 : 1.0),
        ),
        elevation: isSelected ? 1 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.chip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 14, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(
                  item.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (item.count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.brand50,
                      borderRadius: AppRadius.chip,
                    ),
                    child: Text(
                      '${item.count}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.brand700,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
