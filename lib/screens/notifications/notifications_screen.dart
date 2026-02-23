import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications right now.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.isRead 
                      ? Colors.grey.withOpacity(0.2) 
                      : Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    _getIconForType(notification.relatedEntityType),
                    color: notification.isRead 
                        ? Colors.grey 
                        : Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.message),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: !notification.isRead 
                    ? const Icon(Icons.circle, color: Colors.blue, size: 12)
                    : null,
                onTap: () {
                  if (!notification.isRead) {
                    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                  }
                  // Optionally navigate based on relatedEntityType and ID
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => Center(child: Text('Error: $error')),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    if (type == 'task') return Icons.check_circle_outline;
    if (type == 'deal') return Icons.monetization_on_outlined;
    if (type == 'lead') return Icons.person_add_alt_1_outlined;
    return Icons.notifications_none;
  }
}
