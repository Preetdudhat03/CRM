
import 'package:flutter/material.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final activities = [
      _ActivityItem('Contact Created', 'Added new lead: John Doe', Icons.person_add, Colors.blue),
      _ActivityItem('Deal Updated', 'Moved "Tech Corp" to Negotiation', Icons.trending_up, Colors.green),
      _ActivityItem('Task Completed', 'Call with Sarah regarding Q3', Icons.check_circle, Colors.orange),
      _ActivityItem('Email Sent', 'Follow-up sent to Mike Ross', Icons.email, Colors.purple),
    ];

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = activities[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: item.color.withOpacity(0.1),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(item.description),
          trailing: Text(
            '${index + 1}h ago',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

class _ActivityItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _ActivityItem(this.title, this.description, this.icon, this.color);
}
