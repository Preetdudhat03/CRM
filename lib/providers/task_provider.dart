
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../services/task_service.dart';

// Service Provider
final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(taskServiceProvider));
});


// State Provider for Search Query and Filters
final taskSearchQueryProvider = StateProvider<String>((ref) => '');
final taskStatusFilterProvider = StateProvider<TaskStatus?>((ref) => null);

// State Notifier for Task List management
class TaskNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;

  TaskNotifier(this._repository) : super(const AsyncValue.loading()) {
    getTasks();
  }

  Future<void> getTasks() async {
    try {
      state = const AsyncValue.loading();
      final tasks = await _repository.getTasks();
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      final newTask = await _repository.addTask(task);
      state.whenData((tasks) {
        state = AsyncValue.data([...tasks, newTask]);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      final updatedTask = await _repository.updateTask(task);
      state.whenData((tasks) {
        state = AsyncValue.data([
          for (final t in tasks)
            if (t.id == task.id) updatedTask else t
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      state.whenData((tasks) {
        state = AsyncValue.data([
          for (final t in tasks)
            if (t.id != id) t
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }
}

// Tasks List Provider
final tasksProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<TaskModel>>>((ref) {
  return TaskNotifier(ref.watch(taskRepositoryProvider));
});

// Filtered Tasks Provider
final filteredTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final query = ref.watch(taskSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(taskStatusFilterProvider);

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      final matchesQuery = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          (task.relatedEntityName?.toLowerCase().contains(query) ?? false);
          
      final matchesStatus = statusFilter == null || task.status == statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  });
});
