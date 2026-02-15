import '../../models/role_model.dart';
import '../../models/permission_model.dart';

class PermissionService {
  /// Checks if a given [role] has the specified [permission].
  static bool hasPermission(Role role, Permission permission) {
    // The logic is delegated to the Role extension for cleaner code
    return role.permissions.contains(permission);
  }

  /// Checks if a given [role] has ANY of the specified [permissions].
  static bool hasAnyPermission(Role role, List<Permission> permissions) {
    return permissions.any((p) => hasPermission(role, p));
  }

  /// Checks if a given [role] has ALL of the specified [permissions].
  static bool hasAllPermissions(Role role, List<Permission> permissions) {
    return permissions.every((p) => hasPermission(role, p));
  }
}
