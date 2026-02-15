
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

class UserManagementNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserService _userService;

  UserManagementNotifier(this._userService) : super(const AsyncValue.loading()) {
    getUsers();
  }

  Future<void> getUsers() async {
    try {
      state = const AsyncValue.loading();
      final users = await _userService.getUsers();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addUser(String name, String email, Role role) async {
    try {
      final newUser = UserModel(
        id: '', // ID will be generated
        name: name,
        email: email,
        role: role,
      );
      final addedUser = await _userService.addUser(newUser);
      state.whenData((users) {
        state = AsyncValue.data([...users, addedUser]);
      });
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final updatedUser = await _userService.updateUser(user);
      state.whenData((users) {
        state = AsyncValue.data([
          for (final u in users) if (u.id == user.id) updatedUser else u,
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _userService.deleteUser(id);
      state.whenData((users) {
        state = AsyncValue.data([
          for (final u in users) if (u.id != id) u,
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, AsyncValue<List<UserModel>>>((ref) {
  return UserManagementNotifier(ref.watch(userServiceProvider));
});
