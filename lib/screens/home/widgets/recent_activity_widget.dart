import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/dashboard_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../utils/error_handler.dart';

class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dashboardMetricsProvider);

    return activityAsync.when(
      data: (metrics) {
        final recentActivities = metrics['recentActivities'] as List<dynamic>? ?? [];

        if (recentActivities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent activity'),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: recentActivities.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = recentActivities[index];
            final typeStr = item['type'] ?? 'other';
            final title = item['title'] ?? 'Activity';
            final dateStr = item['date'] ?? item['created_at'];
            final date = dateStr != null ? DateTime.tryParse(dateStr.toString()) ?? DateTime.now() : DateTime.now();
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorForType(typeStr).withOpacity(0.1),
                child: Icon(_getIconForType(typeStr), color: _getColorForType(typeStr), size: 20),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(''), // Activity table doesn't have message explicitly in this simple mock
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeago.format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: ${ErrorHandler.formatError(error)}')),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'deal':
        return Colors.green;
      case 'task':
        return Colors.blue;
      case 'lead':
        return Colors.orange;
      case 'contact':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'deal':
        return Icons.attach_money;
      case 'task':
        return Icons.check_circle_outline;
      case 'lead':
        return Icons.person_add_alt_1_outlined;
      case 'contact':
        return Icons.contacts_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class _ActivityItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _ActivityItem(this.title, this.description, this.icon, this.color);
}
