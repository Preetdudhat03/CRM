
import '../models/user_model.dart';
import '../models/permission_model.dart';

class PermissionService {
  /// Check if a user has a specific permission
  static bool hasPermission(UserModel? user, Permission permission) {
    if (user == null) return false;
    return user.hasPermission(permission);
  }

  /// Check if a user has ANY of the required permissions
  static bool hasAnyPermission(UserModel? user, List<Permission> permissions) {
    if (user == null) return false;
    for (var permission in permissions) {
      if (user.hasPermission(permission)) return true;
    }
    return false;
  }
}
