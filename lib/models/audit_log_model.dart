import 'dart:convert';

class AuditLogModel {
  final String id;
  final String organizationId;
  final String? userId; // UUID
  final String? userEmail;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.organizationId,
    this.userId,
    this.userEmail,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? oldVals;
    if (json['old_values'] != null) {
      if (json['old_values'] is String) {
        oldVals = jsonDecode(json['old_values']);
      } else if (json['old_values'] is Map) {
        oldVals = Map<String, dynamic>.from(json['old_values']);
      }
    }

    Map<String, dynamic>? newVals;
    if (json['new_values'] != null) {
      if (json['new_values'] is String) {
        newVals = jsonDecode(json['new_values']);
      } else if (json['new_values'] is Map) {
        newVals = Map<String, dynamic>.from(json['new_values']);
      }
    }

    return AuditLogModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'] ?? '',
      userId: json['user_id'],
      userEmail: json['user_email'],
      action: json['action'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'],
      oldValues: oldVals,
      newValues: newVals,
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'user_email': userEmail,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionLabel {
    // Return friendly name based on raw action string
    switch (action) {
      case 'deal_created':
        return 'Deal Created';
      case 'deal_stage_changed':
        return 'Deal Stage Changed';
      case 'deal_updated':
        return 'Deal Updated';
      case 'deal_deleted':
        return 'Deal Deleted';
      case 'contact_created':
        return 'Contact Created';
      case 'contact_updated':
        return 'Contact Updated';
      case 'contact_deleted':
        return 'Contact Deleted';
      case 'lead_created':
        return 'Lead Created';
      case 'lead_updated':
        return 'Lead Updated';
      case 'lead_deleted':
        return 'Lead Deleted';
      case 'lead_converted':
        return 'Lead Converted';
      case 'user_role_updated':
        return 'User Role Updated';
      case 'user_removed':
        return 'User Removed';
      default:
        // Attempt to format snake_case to title case
        return action
            .split('_')
            .map((word) => word.isNotEmpty ? '\${word[0].toUpperCase()}\${word.substring(1)}' : '')
            .join(' ');
    }
  }
}
