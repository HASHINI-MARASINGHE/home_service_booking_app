import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/provider_notification_service.dart';
import '../../widgets/provider/provider_widgets.dart';
import 'provider_theme.dart';

/// The provider's notification list. Tapping a review notification marks it
/// read and hands its booking to [onOpen] (the job page showing the review).
class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({
    super.key,
    required this.service,
    required this.onOpen,
  });
  final ProviderNotificationService service;
  final ValueChanged<AppNotification> onOpen;

  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen> {
  late Stream<List<AppNotification>> _items = widget.service
      .watchNotifications();

  Future<void> _tap(AppNotification item) async {
    if (!item.read) {
      try {
        await widget.service.markRead(item.id);
      } catch (_) {
        // Opening the job matters more than the read marker.
      }
    }
    if (mounted) widget.onOpen(item);
  }

  Future<void> _markRead(List<AppNotification> items) async {
    try {
      await widget.service.markAllRead(items.map((n) => n.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark as read. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<AppNotification>>(
    stream: _items,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ProviderFailure(
          error: snapshot.error,
          onRetry: () =>
              setState(() => _items = widget.service.watchNotifications()),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      final unread = items.where((n) => !n.read).toList();
      return ProviderPage(
        children: [
          if (items.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    unread.isEmpty ? 'All caught up' : '${unread.length} unread',
                    style: const TextStyle(color: ProviderTheme.muted),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('mark-all-read'),
                  onPressed: unread.isEmpty ? null : () => _markRead(unread),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark all as read'),
                ),
              ],
            ),
          if (items.isEmpty)
            const ProviderEmpty(
              title: 'No notifications yet',
              message:
                  'Quotes, reviews and updates about your jobs will show here.',
            ),
          for (final item in items)
            _NotificationTile(
              item: item,
              onTap: () => _tap(item),
              onMarkRead: () => _markRead([item]),
            ),
        ],
      );
    },
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.onMarkRead,
  });
  final AppNotification item;
  final VoidCallback onTap, onMarkRead;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${item.read ? '' : 'Unread. '}${item.title}. ${item.body}',
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ProviderCard(
        color: item.read ? ProviderTheme.surface : ProviderTheme.tealLight,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ProviderTheme.surface,
                child: item.type == AppNotification.reviewType
                    ? const Icon(
                        Icons.star_rounded,
                        color: ProviderTheme.orange,
                        size: 22,
                      )
                    : item.type == AppNotification.quoteType
                    ? const Icon(
                        Icons.request_quote_outlined,
                        color: ProviderTheme.teal,
                        size: 22,
                      )
                    : item.type == AppNotification.disputeType
                    ? const Icon(
                        Icons.report_problem_outlined,
                        color: ProviderTheme.red,
                        size: 22,
                      )
                    : const Icon(
                        Icons.verified_user_outlined,
                        color: ProviderTheme.teal,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.read
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: ProviderTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(color: ProviderTheme.body),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel(context, item.createdAt),
                      style: const TextStyle(
                        color: ProviderTheme.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.read)
                Column(
                  children: [
                    Container(
                      key: const ValueKey('unread-dot'),
                      margin: const EdgeInsets.only(top: 6, left: 8, bottom: 2),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: ProviderTheme.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('mark-read'),
                      tooltip: 'Mark as read',
                      onPressed: onMarkRead,
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: ProviderTheme.teal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
