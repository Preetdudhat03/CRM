import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

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
    // ID handling same as others
    
    final response = await _supabase
        .from('tasks')
        .insert(json)
        .select()
        .single();
    
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final response = await _supabase
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<void> deleteTask(String id) async {
    await _supabase.from('tasks').delete().eq('id', id);
  }
}
