
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';
import '../services/auth_service.dart';

// Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Current User State
final currentUserProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Derived Providers for Role and Permissions
final userRoleProvider = Provider<Role?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

final userPermissionsProvider = Provider<List<Permission>>((ref) {
  return ref.watch(currentUserProvider)?.role.permissions ?? [];
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await _authService.getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = await _authService.login(email, password);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }

  Future<void> refreshUser() async {
    state = await _authService.getCurrentUser();
  }
}
