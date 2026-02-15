
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
}
