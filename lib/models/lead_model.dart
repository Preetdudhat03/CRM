
enum LeadStatus {
  newLead,
  contacted,
  interested,
  qualified,
  lost,
  converted,
}

extension LeadStatusExtension on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.interested:
        return 'Interested';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.lost:
        return 'Lost';
      case LeadStatus.converted:
        return 'Converted';
    }
  }
}

class LeadModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String source;
  final LeadStatus status;
  final String assignedTo;
  final DateTime createdAt;
  final double? estimatedValue;

  const LeadModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.source,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
    this.estimatedValue,
  });

  LeadModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? source,
    LeadStatus? status,
    String? assignedTo,
    DateTime? createdAt,
    double? estimatedValue,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      source: source ?? this.source,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      estimatedValue: estimatedValue ?? this.estimatedValue,
    );
  }


  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // Schema stores status as snake_case (e.g. 'new_lead'), enum is camelCase (newLead)
    final rawStatus = (json['status'] ?? 'new_lead') as String;
    final statusName = rawStatus.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
    return LeadModel(
      id: json['id'],
      name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      source: json['lead_source'] ?? '',
      status: LeadStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => LeadStatus.newLead,
      ),
      assignedTo: json['assigned_to'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      estimatedValue: (json['estimated_value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert camelCase enum name back to snake_case for DB
    final statusSnake = status.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'lead_source': source,
      'status': statusSnake,
      'assigned_to': assignedTo.isEmpty ? null : assignedTo,
      'estimated_value': estimatedValue,
    };
  }
}
