enum ContactStatus { lead, customer, churned }

extension ContactStatusExtension on ContactStatus {
  String get label {
    switch (this) {
      case ContactStatus.lead:
        return 'Lead';
      case ContactStatus.customer:
        return 'Customer';
      case ContactStatus.churned:
        return 'Churned';
    }
  }
}

class ContactModel {
  final String id;
  final String? organizationId;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String position;
  final String? address;
  final String? notes;
  final ContactStatus status;
  final DateTime createdAt;
  final DateTime lastContacted;
  final String? avatarUrl;
  final bool isFavorite;
  final String? assignedTo;
  final bool? createdFromLead;
  final String? sourceLeadId;

  final String? companyId;

  const ContactModel({
    required this.id,
    this.organizationId,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.position,
    this.address,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.lastContacted,
    this.avatarUrl,
    this.isFavorite = false,
    this.assignedTo,
    this.createdFromLead,
    this.sourceLeadId,
    this.companyId,
  });

  ContactModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? address,
    String? notes,
    ContactStatus? status,
    DateTime? createdAt,
    DateTime? lastContacted,
    String? avatarUrl,
    bool? isFavorite,
    String? assignedTo,
    bool? createdFromLead,
    String? sourceLeadId,
    String? companyId,
  }) {
    return ContactModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      position: position ?? this.position,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastContacted: lastContacted ?? this.lastContacted,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      assignedTo: assignedTo ?? this.assignedTo,
      createdFromLead: createdFromLead ?? this.createdFromLead,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
      companyId: companyId ?? this.companyId,
    );
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    ContactStatus parsedStatus;
    if (json['status'] != null) {
      parsedStatus = ContactStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContactStatus.lead,
      );
    } else {
      parsedStatus = (json['is_customer'] == true)
          ? ContactStatus.customer
          : ContactStatus.lead;
    }

    return ContactModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'],
      name:
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'
              .trim()
              .isNotEmpty
          ? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim()
          : (json['name'] ?? ''),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company_name'] ?? '',
      position: json['position'] ?? '',
      address: json['address'],
      notes: json['notes'],
      status: parsedStatus,
      createdAt: DateTime.parse(json['created_at']),
      lastContacted: json['last_contacted'] != null
          ? DateTime.parse(json['last_contacted'])
          : DateTime.now(),
      avatarUrl: json['avatar_url'],
      isFavorite: json['is_favorite'] ?? false,
      assignedTo: json['assigned_to'],
      createdFromLead: json['created_from_lead'],
      sourceLeadId: json['source_lead_id'],
      companyId: json['company_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return {
      'organization_id': organizationId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company_name': company,
      'position': position,
      'address': address,
      'notes': notes,
      'status': status.name,
      'is_customer':
          status == ContactStatus.customer || status == ContactStatus.churned,
      'created_at': createdAt.toIso8601String(),
      'last_contacted': lastContacted.toIso8601String(),
      'avatar_url': avatarUrl,
      'is_favorite': isFavorite,
      'assigned_to': assignedTo == null || assignedTo!.isEmpty
          ? null
          : assignedTo,
      'company_id': companyId,
    };
  }
}
