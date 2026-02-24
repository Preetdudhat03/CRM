
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authServiceProvider));
});


// Current User State
final currentUserProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// Derived Providers for Role and Permissions
final userRoleProvider = Provider<Role?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

final userPermissionsProvider = Provider<List<Permission>>((ref) {
  return ref.watch(currentUserProvider)?.role.permissions ?? [];
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(null) {
    _init();
  }

  Future<void> _init() async {
    // 1. Immediately surface cached UI data so user never stares at a load screen
    state = _repository.getCachedUser();
    
    // 2. Refresh the session stealthily in the background
    final freshUser = await _repository.getCurrentUser();
    if (freshUser != null) {
      state = freshUser;
    }
  }

  Future<void> login(String email, String password) async {
    state = await _repository.login(email, password);
    // Background refresh to catch profile avatars silently just in case
    refreshUser();
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }

  Future<void> refreshUser() async {
    state = await _repository.getCurrentUser();
  }

  Future<void> updateProfile(UserModel user) async {
    state = await _repository.updateProfile(user);
  }
  Future<void> updatePassword(String newPassword) async {
    await _repository.updatePassword(newPassword);
  }
}
