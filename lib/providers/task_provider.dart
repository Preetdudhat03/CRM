
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/role_model.dart';
import '../repositories/task_repository.dart';
import '../services/task_service.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

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
  final Ref _ref;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  TaskNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      state = const AsyncValue.loading();
      final tasks = await _repository.getTasks(page: _currentPage, pageSize: _pageSize);
      if (tasks.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(tasks);

      // Check for Task Due Reminders
      final now = DateTime.now();
      for (final t in tasks) {
         if (t.status != TaskStatus.completed && t.dueDate.isAfter(now) && t.dueDate.difference(now).inHours < 24) {
            _ref.read(notificationsProvider.notifier).pushNotificationLocally(
               'Task Due Soon',
               'Task "${t.title}" is due in less than 24 hours!',
               relatedEntityId: t.id,
               relatedEntityType: 'task',
               deduplicate: true,
            );
         }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    _isLoadingMore = true;
    try {
      _currentPage++;
      final newTasks = await _repository.getTasks(page: _currentPage, pageSize: _pageSize);
      if (newTasks.length < _pageSize) _hasMore = false;
      state.whenData((currentTasks) {
        state = AsyncValue.data([...currentTasks, ...newTasks]);
      });
    } catch (e) {
      _currentPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      // Don't set state to loading — keep the list visible during refresh
      final tasks = await _repository.getTasks(page: _currentPage, pageSize: _pageSize);
      if (tasks.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      // On refresh error, keep existing data rather than showing error
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      final newTask = await _repository.addTask(task);
      state.whenData((tasks) {
        state = AsyncValue.data([...tasks, newTask]);
      });

      ActivityService.log(title: 'Created task: ${newTask.title}', type: 'task', relatedEntityId: newTask.id);

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      final role = currentUser?.role ?? Role.viewer;
      _ref.read(notificationsProvider.notifier).pushNotificationLocally(
        'New Task Created',
        '$userName added a new task: ${newTask.title}',
        relatedEntityId: newTask.id,
        relatedEntityType: 'task',
        targetRoles: getUpperRanks(role),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      final updatedTask = await _repository.updateTask(task);
      state.whenData((tasks) {
        final existingTask = tasks.firstWhere((t) => t.id == task.id, orElse: () => task);

        state = AsyncValue.data([
          for (final t in tasks)
            if (t.id == task.id) updatedTask else t
        ]);

        if (existingTask.status != task.status) {
          final currentUser = _ref.read(currentUserProvider);
          final userName = currentUser?.name ?? 'Someone';
          final role = currentUser?.role ?? Role.viewer;
          _ref.read(notificationsProvider.notifier).pushNotificationLocally(
            'Task Status Updated',
            '$userName marked the task ${task.title} as ${task.status.name}',
            relatedEntityId: task.id,
            relatedEntityType: 'task',
            targetRoles: getUpperRanks(role),
          );
        }
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
      ActivityService.log(title: 'Deleted a task', type: 'task', relatedEntityId: id);
    } catch (e) {
      // Handle error
    }
  }
}

// Tasks List Provider
final tasksProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<TaskModel>>>((ref) {
  return TaskNotifier(ref.watch(taskRepositoryProvider), ref);
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
