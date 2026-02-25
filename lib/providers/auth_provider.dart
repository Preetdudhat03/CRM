
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
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

// Tracks whether the initial auth check is still in progress
final authInitializingProvider = StateProvider<bool>((ref) => true);

// Derived Providers for Role and Permissions
final userRoleProvider = Provider<Role?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

final userPermissionsProvider = Provider<List<Permission>>((ref) {
  return ref.watch(currentUserProvider)?.role.permissions ?? [];
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      state = await _repository.getCurrentUser();
    } catch (_) {
      state = null;
    } finally {
      _ref.read(authInitializingProvider.notifier).state = false;
    }
  }

  Future<void> login(String email, String password) async {
    state = await _repository.login(email, password);
    // Register FCM token after login
    if (state != null) {
      PushNotificationService.registerAfterLogin();
    }
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
