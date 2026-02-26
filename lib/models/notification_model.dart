class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String? relatedEntityId;
  final String? relatedEntityType; // 'task', 'deal', 'lead'
  final List<String>? targetRoles;
  final String? senderId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.relatedEntityId,
    this.relatedEntityType,
    this.targetRoles,
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
    List<String>? targetRoles,
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
      targetRoles: targetRoles ?? this.targetRoles,
      senderId: senderId ?? this.senderId,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String? rawType = json['related_entity_type'];
    String? type;
    List<String>? roles;
    String? sender;

    if (rawType != null) {
      String remaining = rawType;
      
      // Extract sender
      if (remaining.contains('||sender:')) {
        final parts = remaining.split('||sender:');
        sender = parts[1];
        remaining = parts[0];
      }
      
      // Extract roles
      if (remaining.contains('||roles:')) {
        final parts = remaining.split('||roles:');
        roles = parts[1].split(',');
        remaining = parts[0];
      }
      
      type = (remaining == 'none' || remaining.isEmpty) ? null : remaining;
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
      senderId: sender,
    );
  }

  Map<String, dynamic> toJson() {
    String? rawType = relatedEntityType;
    String rolesStr = targetRoles != null && targetRoles!.isNotEmpty ? '||roles:${targetRoles!.join(',')}' : '';
    String senderStr = senderId != null ? '||sender:$senderId' : '';
    
    if (rawType == null && (rolesStr.isNotEmpty || senderStr.isNotEmpty)) {
      rawType = 'none$rolesStr$senderStr';
    } else if (rawType != null) {
      rawType = '$rawType$rolesStr$senderStr';
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
