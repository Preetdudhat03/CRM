import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/dashboard_provider.dart';
import '../../../../models/task_model.dart';
import '../../../../widgets/animations/fade_in_slide.dart';
import '../../tasks/tasks_screen.dart';

class TasksDueTodayWidget extends ConsumerWidget {
  const TasksDueTodayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks Due Today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to tasks overview
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TasksScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          metricsAsync.when(
            data: (metrics) {
              final tasksRaw = metrics['tasksDueToday'] as List<dynamic>? ?? [];
              final dueTodayOrOverdue = tasksRaw.map((e) => TaskModel.fromJson(e)).toList();

              if (dueTodayOrOverdue.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.green.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'You\'re all caught up for today!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: dueTodayOrOverdue.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = dueTodayOrOverdue[index];
                  final isOverdue = task.dueDate.isBefore(todayStart);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                        color: isOverdue ? Colors.red : Colors.orange,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                         fontWeight: FontWeight.w600,
                         decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                         color: task.status == TaskStatus.completed ? Colors.grey : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      isOverdue 
                        ? 'Overdue by ${now.difference(task.dueDate).inDays} days'
                        : 'Due at ${DateFormat('hh:mm a').format(task.dueDate)}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    trailing: Checkbox(
                      value: task.status == TaskStatus.completed,
                      onChanged: (val) {
                        if (val != null) {
                          // Update using your task provider
                          // Since we mapped it, we need to handle full update over the provider
                          // ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: ...));
                        }
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            )),
            error: (error, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'You\'re all caught up for today!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
