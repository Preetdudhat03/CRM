class OrganizationMemberModel {
  final String id;
  final String organizationId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  // Denormalized from profiles join
  final String? userName;
  final String? userEmail;

  const OrganizationMemberModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    this.role = 'employee',
    required this.joinedAt,
    this.userName,
    this.userEmail,
  });

  OrganizationMemberModel copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? userName,
    String? userEmail,
  }) {
    return OrganizationMemberModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  factory OrganizationMemberModel.fromJson(Map<String, dynamic> json) {
    // Handle the joined profiles data
    String? name;
    String? email;
    if (json['profiles'] is Map) {
      name = json['profiles']['name'];
      email = json['profiles']['email'];
    }

    return OrganizationMemberModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['role'] ?? 'employee',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      userName: name ?? json['user_name'],
      userEmail: email ?? json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'role': role,
    };
  }

  /// Display-friendly role label
  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'employee':
        return 'Employee';
      case 'viewer':
        return 'Viewer';
      default:
        return role.substring(0, 1).toUpperCase() + role.substring(1);
    }
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
}
