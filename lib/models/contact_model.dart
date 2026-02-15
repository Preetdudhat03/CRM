
enum ContactStatus {
  lead,
  customer,
  churned,
}

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

  const ContactModel({
    required this.id,
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
  });

  ContactModel copyWith({
    String? id,
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
  }) {
    return ContactModel(
      id: id ?? this.id,
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
    );
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      address: json['address'],
      notes: json['notes'],
      status: ContactStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'lead'),
        orElse: () => ContactStatus.lead,
      ),
      createdAt: DateTime.parse(json['created_at']),
      lastContacted: json['last_contacted'] != null
          ? DateTime.parse(json['last_contacted'])
          : DateTime.now(),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'position': position,
      'address': address,
      'notes': notes,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'last_contacted': lastContacted.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
}
