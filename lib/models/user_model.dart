
import 'role_model.dart';
import 'permission_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  // Check if user has a specific permission based on their role
  bool hasPermission(Permission permission) {
    return role.permissions.contains(permission);
  }

  // Factory constructor for creating a copy
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    Role? role,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
