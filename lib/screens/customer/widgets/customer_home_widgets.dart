import 'package:flutter/material.dart';

import '../../../l10n/l10n_context.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../widgets/common/app_bottom_nav.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.photoUrl, this.radius = 28});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: CustomerHomeTheme.mint,
      child: url.isEmpty
          ? Icon(
              Icons.person,
              color: CustomerHomeTheme.primary,
              size: radius * 1.05,
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: CustomerHomeTheme.primary,
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
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('provider-search'),
    controller: _controller,
    onChanged: (text) {
      setState(() {});
      widget.onChanged?.call(text);
    },
    textInputAction: TextInputAction.search,
    style: const TextStyle(fontSize: 16),
    decoration: InputDecoration(
      hintText: context.l10n.searchHint,
      hintStyle: const TextStyle(
        color: CustomerHomeTheme.mutedText,
        fontSize: 15,
      ),
      prefixIcon: const Icon(Icons.search, color: CustomerHomeTheme.primary),
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              key: const ValueKey('clear-search'),
              tooltip: context.l10n.clearSearch,
              icon: const Icon(Icons.close_rounded),
              onPressed: _clear,
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: CustomerHomeTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: CustomerHomeTheme.primary),
      ),
    ),
  );
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
