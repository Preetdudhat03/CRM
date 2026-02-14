
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
  final ContactStatus status;
  final DateTime lastContacted;
  final String? avatarUrl;

  const ContactModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.position,
    required this.status,
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
    ContactStatus? status,
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
      status: status ?? this.status,
      lastContacted: lastContacted ?? this.lastContacted,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
