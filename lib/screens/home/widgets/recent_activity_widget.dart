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
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Activities will appear here when you create contacts, leads, deals, or tasks',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: recentActivities.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 56,
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final item = recentActivities[index];
              final typeStr = item['type'] ?? 'other';
              final title = item['title'] ?? 'Activity';
              final createdBy = item['created_by'] ?? '';
              final dateStr = item['date'] ?? item['created_at'];
              final date = dateStr != null
                  ? DateTime.tryParse(dateStr.toString()) ?? DateTime.now()
                  : DateTime.now();

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: _getColorForType(typeStr).withOpacity(0.1),
                  child: Icon(_getIconForType(typeStr), color: _getColorForType(typeStr), size: 18),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: createdBy.isNotEmpty
                    ? Text(
                        'by $createdBy',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
                trailing: Text(
                  timeago.format(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              );
            },
          ),
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
