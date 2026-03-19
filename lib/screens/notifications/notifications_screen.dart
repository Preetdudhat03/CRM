import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../providers/organization_provider.dart';

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
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).getNotifications(),
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No notifications right now.')),
                  Center(
                    child: Text(
                      'Pull down to refresh',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).getNotifications(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  isThreeLine: true,
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
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
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
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(notification.id);
                    }
                    
                    if (notification.relatedEntityType == 'invitation') {
                      _showInvitationDialog(context, ref, notification);
                    }
                  },
                );
              },
            ),
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
    if (type == 'invitation') return Icons.group_add_outlined;
    return Icons.notifications_none;
  }

  void _showInvitationDialog(BuildContext context, WidgetRef ref, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Organization Invitation'),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final inviteId = notification.relatedEntityId;
              if (inviteId == null) return;

              Navigator.pop(ctx);
              try {
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing invitation...')),
                );

                await ref.read(userInvitationsProvider.notifier).acceptInvitation(inviteId);
                
                // Refresh both the current org and the list of user orgs
                await ref.read(currentOrganizationProvider.notifier).refresh();
                ref.invalidate(userOrganizationsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined organization successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Accept & Join'),
          ),
        ],
      ),
    );
  }
}
