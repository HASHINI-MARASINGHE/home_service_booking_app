import 'package:flutter/material.dart';

import '../../../l10n/l10n_context.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_bottom_nav.dart';
import '../../../widgets/common/app_text_field.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.photoUrl, this.radius = 28});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brand100,
      child: url.isEmpty
          ? Icon(Icons.person, color: AppColors.brand700, size: radius * 1.05)
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Icon(
                        Icons.person,
                        color: AppColors.brand700,
                        size: radius * 1.05,
                      ),
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: AppColors.brand700,
                  size: radius * 1.05,
                ),
              ),
            ),
    );
  }
}

class CustomerSearchBar extends StatefulWidget {
  const CustomerSearchBar({super.key, this.onChanged});

  /// Called with the text as it is typed (filters the provider list).
  final ValueChanged<String>? onChanged;

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppTextField(
      fieldKey: const ValueKey('provider-search'),
      controller: _controller,
      label: l10n.searchLabel,
      hintText: l10n.searchHint,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onChanged: (text) {
        setState(() {});
        widget.onChanged?.call(text);
      },
      suffix: _controller.text.isEmpty
          ? null
          : IconButton(
              key: const ValueKey('clear-search'),
              tooltip: l10n.clearSearch,
              icon: const Icon(Icons.close_rounded),
              onPressed: _clear,
            ),
    );
  }
}

class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => AppBottomNav(
    items: AppBottomNav.localizedCustomerItems(context),
    selectedIndex: selectedIndex,
    onSelected: onSelected,
  );
}
