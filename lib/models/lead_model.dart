
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
}
