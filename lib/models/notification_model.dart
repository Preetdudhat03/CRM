class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType; // 'task', 'deal', 'lead'
  final List<String>? targetRoles;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.targetRoles,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    String? relatedEntityId,
    String? relatedEntityType,
    List<String>? targetRoles,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      targetRoles: targetRoles ?? this.targetRoles,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String? rawType = json['related_entity_type'];
    String? type;
    List<String>? roles;
    if (rawType != null && rawType.contains('||roles:')) {
      final parts = rawType.split('||roles:');
      type = parts[0] == 'none' ? null : parts[0];
      roles = parts[1].split(',');
    } else {
      type = rawType;
    }

    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isRead: json['is_read'] ?? false,
      relatedEntityId: json['related_entity_id'],
      relatedEntityType: type,
      targetRoles: roles,
    );
  }

  Map<String, dynamic> toJson() {
    String? rawType = relatedEntityType;
    if (rawType != null && targetRoles != null && targetRoles!.isNotEmpty) {
      rawType = '$rawType||roles:${targetRoles!.join(',')}';
    } else if (rawType == null && targetRoles != null && targetRoles!.isNotEmpty) {
      rawType = 'none||roles:${targetRoles!.join(',')}';
    }

    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'is_read': isRead,
      'related_entity_id': relatedEntityId,
      'related_entity_type': rawType,
    };
  }
}
