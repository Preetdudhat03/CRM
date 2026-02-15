import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/activity_provider.dart';
import '../../../../models/activity_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider);

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
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
          itemCount: activities.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = activities[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorForType(item.type).withOpacity(0.1),
                child: Icon(_getIconForType(item.type), color: _getColorForType(item.type), size: 20),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(item.description),
              trailing: Text(
                timeago.format(item.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Color _getColorForType(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Colors.green;
      case ActivityType.updated:
        return Colors.blue;
      case ActivityType.deleted:
        return Colors.red;
      case ActivityType.completed:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Icons.add_circle_outline;
      case ActivityType.updated:
        return Icons.edit;
      case ActivityType.deleted:
        return Icons.delete_outline;
      case ActivityType.completed:
        return Icons.check_circle_outline;
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
