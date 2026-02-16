import '../../models/user_model.dart';
import '../../models/permission_model.dart';

class PermissionService {
  // Prevent instantiation
  PermissionService._();

  // --- General Permission Checks ---

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

  // --- Contacts ---
  static bool canViewContacts(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.viewContacts);
  }

  static bool canCreateContacts(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.createContacts);
  }

  static bool canEditContacts(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.editContacts);
  }

  static bool canDeleteContacts(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.deleteContacts);
  }

  // --- Leads ---
  static bool canViewLeads(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.viewLeads);
  }

  static bool canCreateLeads(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.createLeads);
  }

  static bool canEditLeads(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.editLeads);
  }

  static bool canDeleteLeads(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.deleteLeads);
  }

  // --- Deals ---
  static bool canViewDeals(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.viewDeals);
  }

  static bool canCreateDeals(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.createDeals);
  }

  static bool canEditDeals(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.editDeals);
  }

  static bool canDeleteDeals(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.deleteDeals);
  }

  // --- Tasks ---
  static bool canViewTasks(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.viewTasks);
  }

  static bool canCreateTasks(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.createTasks);
  }

  static bool canEditTasks(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.editTasks);
  }

  static bool canDeleteTasks(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.deleteTasks);
  }

  // --- Analytics ---
  static bool canViewAnalytics(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.viewAnalytics);
  }

  // --- Admin ---
  static bool canManageUsers(UserModel? user) {
    if (user == null) return false;
    return user.hasPermission(Permission.manageUsers);
  }
}
