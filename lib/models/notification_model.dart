class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType; 
  final String? senderId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.senderId,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    String? relatedEntityId,
    String? relatedEntityType,
    String? senderId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      senderId: senderId ?? this.senderId,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : DateTime.now(),
      isRead: json['is_read'] ?? false,
      relatedEntityId: json['related_entity_id']?.toString(),
      relatedEntityType: json['related_entity_type'],
      senderId: json['sender_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'message': message,
      'is_read': isRead,
    };

    // Only include non-null optional fields to avoid DB type errors
    if (relatedEntityId != null) json['related_entity_id'] = relatedEntityId;
    if (relatedEntityType != null) json['related_entity_type'] = relatedEntityType;
    if (senderId != null) json['sender_id'] = senderId;
    
    // Don't send 'id' — let the DB auto-generate with gen_random_uuid()
    // Don't send 'created_at' — let the DB use DEFAULT NOW()

    return json;
  }
}
