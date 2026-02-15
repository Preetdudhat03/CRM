
import '../models/task_model.dart';
import 'dart:math';

class TaskService {
  static final List<TaskModel> _mockTasks = [
    TaskModel(
      id: 't1',
      title: 'Call Rahul about proposal',
      description: 'Follow up on the sent proposal for Tesla CRM.',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      assignedTo: 'Preet Dudhat',
      relatedEntityId: 'c2',
      relatedEntityType: 'Contact',
      relatedEntityName: 'Rahul Patel',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TaskModel(
      id: 't2',
      title: 'Prepare demo for Infosys',
      description: 'Setup demo environment with custom branding.',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: TaskStatus.inProgress,
      priority: TaskPriority.medium,
      assignedTo: 'Mike Ross',
      relatedEntityId: 'd2',
      relatedEntityType: 'Deal',
      relatedEntityName: 'Infosys Mobile App',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TaskModel(
      id: 't3',
      title: 'Send invoice to CompanyX',
      description: 'Final invoice for Q1 services.',
      dueDate: DateTime.now().subtract(const Duration(days: 1)), // Overdue
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      assignedTo: 'Sarah Connor',
      relatedEntityId: 'c1',
      relatedEntityType: 'Contact',
      relatedEntityName: 'Preet Dudhat',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TaskModel(
      id: 't4',
      title: 'Update LinkedIn profile',
      description: 'Add recent project achievements.',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      status: TaskStatus.completed,
      priority: TaskPriority.low,
      assignedTo: 'Preet Dudhat',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  Future<List<TaskModel>> getTasks() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.from(_mockTasks);
  }

  Future<TaskModel> addTask(TaskModel task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newTask = task.copyWith(
      id: 't${_mockTasks.length + 1 + Random().nextInt(1000)}',
      createdAt: DateTime.now(),
    );
    _mockTasks.add(newTask);
    return newTask;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _mockTasks[index] = task;
      return task;
    }
    throw Exception('Task not found');
  }

  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockTasks.removeWhere((t) => t.id == id);
  }
}
