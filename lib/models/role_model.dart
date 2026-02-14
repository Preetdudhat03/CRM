
import 'permission_model.dart';

enum Role {
  superAdmin,
  admin,
  manager,
  employee,
  viewer,
}

extension RoleExtension on Role {
  String get displayName {
    switch (this) {
      case Role.superAdmin:
        return 'Super Admin';
      case Role.admin:
        return 'Admin';
      case Role.manager:
        return 'Manager';
      case Role.employee:
        return 'Employee';
      case Role.viewer:
        return 'Viewer';
    }
  }

  List<Permission> get permissions {
    switch (this) {
      case Role.superAdmin:
        return Permission.values; // All permissions
      case Role.admin:
        return [
          Permission.viewContacts,
          Permission.createContacts,
          Permission.editContacts,
          Permission.deleteContacts,
          Permission.viewDeals,
          Permission.createDeals,
          Permission.editDeals,
          Permission.deleteDeals,
          Permission.viewAnalytics,
          Permission.manageUsers,
        ];
      case Role.manager:
        return [
          Permission.viewContacts,
          Permission.createContacts,
          Permission.editContacts, // Can edit but not delete
          Permission.viewDeals,
          Permission.createDeals,
          Permission.editDeals,
          Permission.viewAnalytics,
        ];
      case Role.employee:
        return [
          Permission.viewContacts,
          Permission.createContacts,
          Permission.editContacts,
          Permission.viewDeals,
          Permission.createDeals,
          Permission.editDeals,
        ];
      case Role.viewer:
        return [
          Permission.viewContacts,
          Permission.viewDeals,
        ];
    }
  }
}
