class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType; // 'task', 'deal', 'lead'

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    String? relatedEntityId,
    String? relatedEntityType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isRead: json['is_read'] ?? false,
      relatedEntityId: json['related_entity_id'],
      relatedEntityType: json['related_entity_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'is_read': isRead,
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
    };
  }
}
