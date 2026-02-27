
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/permission_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import 'widgets/task_card.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';

import '../../core/services/permission_service.dart';
import '../../utils/error_handler.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(tasksProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = PermissionService.canCreateTasks(user);
    final canEdit = PermissionService.canEditTasks(user);
    final canDelete = PermissionService.canDeleteTasks(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context, ref);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref.read(taskSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) => RefreshIndicator(
          onRefresh: () => ref.read(tasksProvider.notifier).refresh(),
          child: tasks.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tasks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == tasks.length) {
                      final notifier = ref.read(tasksProvider.notifier);
                      if (notifier.isLoadingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!notifier.hasMore && tasks.isNotEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No more tasks'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskDetailScreen(task: task),
                          ),
                        );
                      },
                      onStatusChanged: (value) {
                        final newStatus = value == true ? TaskStatus.completed : TaskStatus.pending;
                        ref.read(tasksProvider.notifier).updateTask(
                          task.copyWith(status: newStatus)
                        );
                      },
                      onEdit: canEdit
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditTaskScreen(task: task),
                                ),
                              );
                            }
                          : null,
                      onDelete: canDelete
                          ? () {
                              _showDeleteConfirmation(context, ref, task);
                            }
                          : null,
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => RefreshIndicator(
          onRefresh: () => ref.read(tasksProvider.notifier).refresh(),
          child: SingleChildScrollView(
             physics: const AlwaysScrollableScrollPhysics(),
             child: SizedBox(
               height: MediaQuery.of(context).size.height,
               child: Center(child: Text('Error: ${ErrorHandler.formatError(error ?? '')}')),
             ),
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'tasks_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditTaskScreen(),
                  ),
                );
              },
              label: const Text('Add Task'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Tasks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                onTap: () {
                  ref.read(taskStatusFilterProvider.notifier).state = null;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Pending'),
                onTap: () {
                  ref.read(taskStatusFilterProvider.notifier).state = TaskStatus.pending;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('In Progress'),
                onTap: () {
                  ref.read(taskStatusFilterProvider.notifier).state = TaskStatus.inProgress;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Completed'),
                onTap: () {
                  ref.read(taskStatusFilterProvider.notifier).state = TaskStatus.completed;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Cancelled'),
                onTap: () {
                  ref.read(taskStatusFilterProvider.notifier).state = TaskStatus.cancelled;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).deleteTask(task.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
