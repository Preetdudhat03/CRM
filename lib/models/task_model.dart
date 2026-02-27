
import 'package:flutter/material.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
}

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String assignedTo;
  final String? relatedEntityId; // ID of Contact, Lead, or Deal
  final String? relatedEntityType; // 'Contact', 'Lead', 'Deal'
  final String? relatedEntityName; // Denormalized name for UI
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.assignedTo,
    this.relatedEntityId,
    this.relatedEntityType,
    this.relatedEntityName,
    required this.createdAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? assignedTo,
    String? relatedEntityId,
    String? relatedEntityType,
    String? relatedEntityName,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityName: relatedEntityName ?? this.relatedEntityName,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date']).toLocal()
          : DateTime.now(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == (json['priority'] ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      assignedTo: json['assigned_to'] ?? '',
      relatedEntityId: json['related_entity_id'],
      relatedEntityType: json['related_entity_type'],
      relatedEntityName: json['related_entity_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'assigned_to': assignedTo.isEmpty ? null : assignedTo,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
    };
  }
}
