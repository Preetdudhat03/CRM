class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType; 
  final String? senderId;
  final String? recipientId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.senderId,
    this.recipientId,
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
    String? recipientId,
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
      recipientId: recipientId ?? this.recipientId,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : DateTime.now(),
      isRead: json['is_read'] ?? false,
      relatedEntityId: json['related_id']?.toString(), // Match schema: related_id
      relatedEntityType: json['related_type'],         // Match schema: related_type
      senderId: json['sender_id']?.toString(),
      recipientId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'message': message,
      'is_read': isRead,
      'type': relatedEntityType ?? 'general', // Schema requires 'type' NOT NULL
    };

    // Only include non-null optional fields to avoid DB type errors
    if (relatedEntityId != null) json['related_id'] = relatedEntityId; // Match schema: related_id
    if (relatedEntityType != null) json['related_type'] = relatedEntityType; // Match schema: related_type
    if (senderId != null) json['sender_id'] = senderId;
    if (recipientId != null) json['user_id'] = recipientId;
    
    // Don't send 'id' — let the DB auto-generate with gen_random_uuid()
    // Don't send 'created_at' — let the DB use DEFAULT NOW()

    return json;
  }
}
