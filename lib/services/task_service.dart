import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import 'activity_service.dart';
import 'activity_service.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TaskModel>> getTasks({int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('tasks')
        .select()
        .order('due_date', ascending: true)
        .range(start, end);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  Future<TaskModel> addTask(TaskModel task) async {
    final json = task.toJson();

    final response = await _supabase
        .from('tasks')
        .insert(json)
        .select()
        .single();

    final newTask = TaskModel.fromJson(response);

    // Log Activity: Task Created
    if (newTask.relatedEntityId != null) {
      ActivityService.log(
        relatedType: newTask.relatedEntityType ?? 'task',
        relatedId: newTask.relatedEntityId!,
        activityType: 'task_created',
        title: 'Task Created',
        description: 'New task: ${newTask.title}',
        metadata: {
          'task_id': newTask.id,
          'due_date': newTask.dueDate.toIso8601String(),
        },
        organizationId: newTask.organizationId,
      );
    }

    return newTask;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final response = await _supabase
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();

    final updatedTask = TaskModel.fromJson(response);

    // Log Activity if completed
    if (updatedTask.isCompleted && updatedTask.relatedEntityId != null) {
      ActivityService.log(
        relatedType: updatedTask.relatedEntityType ?? 'task',
        relatedId: updatedTask.relatedEntityId!,
        activityType: 'task_completed',
        title: 'Task Completed',
        description: 'Task "${updatedTask.title}" marked as done.',
        metadata: {'task_id': updatedTask.id},
        organizationId: updatedTask.organizationId,
      );
    }

    return updatedTask;
  }

  Future<void> deleteTask(String id) async {
    await _supabase.from('tasks').delete().eq('id', id);
  }
}
