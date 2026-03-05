import 'dart:convert';

class ActivityModel {
  final String id;
  final String? organizationId;
  final String relatedType; // 'lead', 'contact', 'deal', 'company'
  final String relatedId;
  final String activityType; // 'call', 'email', 'stage_changed', etc.
  final String title;
  final String description;
  final Map<String, dynamic> metadata;
  final String? createdBy; // UUID of the user
  final String? performerName; // Readable name of the user
  final DateTime createdAt;

  const ActivityModel({
    required this.id,
    this.organizationId,
    required this.relatedType,
    required this.relatedId,
    required this.activityType,
    required this.title,
    required this.description,
    this.metadata = const {},
    this.createdBy,
    this.performerName,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    // Handle metadata parsing
    Map<String, dynamic> meta = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is String) {
        meta = jsonDecode(json['metadata']);
      } else if (json['metadata'] is Map) {
        meta = Map<String, dynamic>.from(json['metadata']);
      }
    }

    return ActivityModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'],
      relatedType:
          json['related_type'] ?? json['related_entity_type'] ?? 'other',
      relatedId: json['related_id'] ?? json['related_entity_id'] ?? '',
      activityType: json['activity_type'] ?? json['type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      metadata: meta,
      createdBy: json['created_by'],
      performerName: json['performer_name'] ?? json['performed_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'organization_id': organizationId,
      'related_type': relatedType,
      'related_id': relatedId,
      'activity_type': activityType,
      'title': title,
      'description': description,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper for UI icons
  String get iconKey {
    switch (activityType) {
      case 'call':
        return 'phone';
      case 'email':
        return 'mail';
      case 'note_added':
        return 'note';
      case 'stage_changed':
        return 'sync';
      case 'file_uploaded':
        return 'attachment';
      case 'task_completed':
        return 'check';
      case 'converted':
        return 'swap';
      case 'created':
        return 'add';
      default:
        return 'info';
    }
  }
}
