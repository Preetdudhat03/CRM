
import 'role_model.dart';
import 'permission_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? avatarUrl;
  final List<Permission>? customPermissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.customPermissions,
  });

  // Check if user has a specific permission based on their role or custom permissions
  bool hasPermission(Permission permission) {
    if (customPermissions != null) {
      return customPermissions!.contains(permission);
    }
    return role.permissions.contains(permission);
  }

  // Factory constructor for creating a copy
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    Role? role,
    String? avatarUrl,
    List<Permission>? customPermissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      customPermissions: customPermissions ?? this.customPermissions,
    );
  }
}
