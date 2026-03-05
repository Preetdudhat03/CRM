import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/activity_model.dart';
import '../providers/activity_provider.dart';
import 'animations/fade_in_slide.dart';

class ActivityTimeline extends ConsumerWidget {
  final String relatedType;
  final String relatedId;

  const ActivityTimeline({
    super.key,
    required this.relatedType,
    required this.relatedId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(
      entityActivitiesProvider((type: relatedType, id: relatedId)),
    );

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No activities found for this entity.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ActivityTimelineItem(
              activity: activity,
              isLast: index == activities.length - 1,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class ActivityTimelineItem extends StatelessWidget {
  final ActivityModel activity;
  final bool isLast;

  const ActivityTimelineItem({
    super.key,
    required this.activity,
    required this.isLast,
  });

  IconData _getIcon(String type) {
    switch (type) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.mail;
      case 'note_added':
        return Icons.note;
      case 'stage_changed':
        return Icons.sync;
      case 'file_uploaded':
        return Icons.attachment;
      case 'task_completed':
        return Icons.check_circle;
      case 'task_created':
        return Icons.add_task;
      case 'converted':
        return Icons.swap_horiz;
      case 'created':
        return Icons.add;
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'call':
        return Colors.green;
      case 'email':
        return Colors.blue;
      case 'stage_changed':
        return Colors.orange;
      case 'task_completed':
        return Colors.purple;
      case 'converted':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      delay: 0,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 16),
            // Timeline line and icon
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getIconColor(
                      activity.activityType,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(activity.activityType),
                    size: 18,
                    color: _getIconColor(activity.activityType),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(activity.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    if (activity.performerName != null && activity.performerName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${activity.performerName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (activity.metadata.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildMetadataView(activity.metadata),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataView(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.key.replaceAll('_', ' ')}: ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${e.value}',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
