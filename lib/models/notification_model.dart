class NotificationModel {
  final String id;
  final String? organizationId;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String type;
  final String? senderId;

  const NotificationModel({
    required this.id,
    this.organizationId,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.type = 'general',
    this.relatedEntityId,
    this.relatedEntityType,
    this.senderId,
  });

  NotificationModel copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    String? relatedEntityType,
    String? type,
    String? senderId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      type: json['type'] ?? 'general',
      relatedEntityId: (json['related_id'] ?? json['related_entity_id'])
          ?.toString(),
      relatedEntityType: json['related_type'] ?? json['related_entity_type'],
      senderId: json['sender_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'organization_id': (organizationId != null && organizationId!.isEmpty) ? null : organizationId,
      'title': title,
      'message': message,
      'is_read': isRead,
      'type': type,
    };

    if (relatedEntityId != null) {
      json['related_id'] = relatedEntityId;
      json['related_entity_id'] = relatedEntityId;
    }
    if (relatedEntityType != null) {
      json['related_type'] = relatedEntityType;
      json['related_entity_type'] = relatedEntityType;
    }
    if (senderId != null) json['sender_id'] = senderId;

    return json;
  }
}
