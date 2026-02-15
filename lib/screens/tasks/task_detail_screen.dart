
import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(task.status.label),
                  backgroundColor: task.status.color.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: task.status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(task.priority.label),
                  backgroundColor: task.priority.color.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: task.priority.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(task.description),
                subtitle: const Text('Description'),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(task.dueDate.toIso8601String().split('T')[0]),
               subtitle: const Text('Due Date'),
            ),
             ListTile(
              leading: const Icon(Icons.person),
              title: Text(task.assignedTo),
              subtitle: const Text('Assigned To'),
            ),
             if (task.relatedEntityName != null)
             ListTile(
              leading: const Icon(Icons.link),
              title: Text('${task.relatedEntityName} (${task.relatedEntityType})'),
              subtitle: const Text('Related To'),
            ),
          ],
        ),
      ),
    );
  }
}
