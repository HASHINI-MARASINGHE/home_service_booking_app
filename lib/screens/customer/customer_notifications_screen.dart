import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/app_notification.dart';
import '../../services/provider_notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/empty_state.dart';
import 'bookings/booking_details_screen.dart';

/// The bell on the customer's Home screen, with the number of unread
/// notifications. Opens [CustomerNotificationsScreen].
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.service});

  final ProviderNotificationService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: service.watchUnreadCount(),
    builder: (context, snapshot) {
      final unread = snapshot.data ?? 0;
      return Semantics(
        button: true,
        label: unread == 0 ? 'Notifications' : 'Notifications, $unread unread',
        excludeSemantics: true,
        child: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 9 ? '9+' : '$unread'),
          backgroundColor: AppColors.danger,
          child: CircleIconButton(
            key: const ValueKey('open-notifications'),
            icon: LucideIcons.bell,
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerNotificationsScreen(service: service),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Quotes and updates for the customer. Tapping one marks it read and opens
/// the booking it is about.
class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key, required this.service});

  final ProviderNotificationService service;

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  late Stream<List<AppNotification>> _items = widget.service
      .watchNotifications();

  Future<void> _open(AppNotification item) async {
    if (!item.read) {
      try {
        await widget.service.markRead(item.id);
      } catch (_) {
        // Opening the booking matters more than the read marker.
      }
    }
    if (!mounted || item.bookingId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(bookingId: item.bookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenHeader(title: 'Notifications'),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _items,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorState(
                    error: snapshot.error!,
                    onRetry: () => setState(
                      () => _items = widget.service.watchNotifications(),
                    ),
                  );
                }
                if (!snapshot.hasData) return const LoadingState();
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.screen),
                    child: EmptyState(
                      icon: LucideIcons.bell,
                      title: 'No notifications yet',
                      message: 'Quotes from your providers will show here.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xs,
                    AppSpacing.screen,
                    AppSpacing.xxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) =>
                      _Tile(item: items[i], onTap: () => _open(items[i])),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.read ? '' : 'Unread. '}${item.title}. ${item.body}',
    excludeSemantics: true,
    child: AppCard(
      onTap: onTap,
      color: item.read ? AppColors.surface : AppColors.primaryTint,
      border: Border.all(color: AppColors.border),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: item.type == AppNotification.quoteType
                ? LucideIcons.receipt
                : LucideIcons.bell,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: item.read
                      ? AppTypography.bodyStrong
                      : AppTypography.bodyStrong.copyWith(
                          color: AppColors.primaryDark,
                        ),
                ),
                const SizedBox(height: 2),
                Text(item.body, style: AppTypography.body),
                if (item.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    Formatters.shortDate(item.createdAt!),
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),
          if (!item.read)
            Container(
              key: const ValueKey('unread-dot'),
              margin: const EdgeInsets.only(top: 6, left: AppSpacing.xs),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
  );
}
