
import '../../models/task_model.dart';

final List<TaskModel> mockTasks = [
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
