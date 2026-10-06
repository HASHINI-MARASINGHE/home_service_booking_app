import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/professional.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/customer_home_theme.dart';
import '../../../widgets/common/app_widgets.dart';
import '../customer_scope.dart';
import 'provider_details_screen.dart';

/// Every published provider, opened from "See all" on the customer home.
class AllProvidersScreen extends StatefulWidget {
  const AllProvidersScreen({super.key});

  @override
  State<AllProvidersScreen> createState() => _AllProvidersScreenState();
}

class _AllProvidersScreenState extends State<AllProvidersScreen> {
  Stream<List<Professional>>? _providers;
  final _search = TextEditingController();
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providers ??= _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Stream<List<Professional>> _load() {
    try {
      return CustomerScope.of(context).bookings.watchProfessionals(limit: 200);
    } catch (error) {
      return Stream.error(error);
    }
  }

  bool _matches(Professional p) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      p.name,
      p.specialty,
      p.area,
      ...p.services,
    ].any((text) => text.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CustomerHomeTheme.background,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenHeader(title: 'Providers'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name, service or area',
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 20,
                  color: CustomerHomeTheme.primary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: CustomerHomeTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: CustomerHomeTheme.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Professional>>(
              stream: _providers,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorState(
                    error: snapshot.error!,
                    onRetry: () => setState(() => _providers = _load()),
                  );
                }
                final all = snapshot.data;
                if (all == null) return const LoadingState();
                final shown = all.where(_matches).toList();
                if (shown.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty
                          ? 'No providers have joined yet.'
                          : 'No providers match "${_query.trim()}".',
                      style: AppTypography.caption,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: shown.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      ProviderListCard(provider: shown[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class ProviderListCard extends StatelessWidget {
  const ProviderListCard({super.key, required this.provider});

  final Professional provider;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      provider.specialty.trim(),
      provider.area.trim(),
    ].where((s) => s.isNotEmpty).join(' • ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Material(
              child: ProviderDetailsScreen(
                providerId: provider.id,
                initial: provider,
              ),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CustomerHomeTheme.border),
          ),
          child: Row(
            children: [
              PersonAvatar(
                name: provider.name,
                photoUrl: provider.photoUrl,
                size: 56,
                verified: provider.verified,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CustomerHomeTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CustomerHomeTheme.mutedText,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF5A524),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            provider.rating == null
                                ? 'New'
                                : '${provider.rating!.toStringAsFixed(1)}'
                                      ' • ${provider.completedJobs} jobs',
                            style: const TextStyle(
                              color: CustomerHomeTheme.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: CustomerHomeTheme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
