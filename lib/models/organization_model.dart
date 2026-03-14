class OrganizationModel {
  final String id;
  final String name;
  final String plan;
  final String? ownerId;
  final DateTime createdAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    this.plan = 'free',
    this.ownerId,
    required this.createdAt,
  });

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? plan,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      plan: plan ?? this.plan,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      plan: json['plan'] ?? 'free',
      ownerId: json['owner_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'plan': plan,
      'owner_id': ownerId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
