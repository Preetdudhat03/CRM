
import '../models/user_model.dart';
import '../models/role_model.dart';
import 'dart:math';

class UserService {
  // Mock data for users
  static final List<UserModel> _mockUsers = [
    UserModel(
      id: 'u1',
      name: 'Preet Dudhat',
      email: 'preet@crm.com',
      role: Role.admin,
    ),
    UserModel(
      id: 'u2',
      name: 'Rahul Patel',
      email: 'rahul@crm.com',
      role: Role.manager,
    ),
    UserModel(
      id: 'u3',
      name: 'John Smith',
      email: 'john@crm.com',
      role: Role.employee,
    ),
    UserModel(
      id: 'u4',
      name: 'Guest Viewer',
      email: 'guest@crm.com',
      role: Role.viewer,
    ),
  ];

  Future<List<UserModel>> getUsers() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    return List.from(_mockUsers);
  }

  Future<UserModel> addUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newUser = UserModel(
      id: 'u${_mockUsers.length + 1 + Random().nextInt(1000)}',
      name: user.name,
      email: user.email,
      role: user.role,
    );
    _mockUsers.add(newUser);
    return newUser;
  }

  Future<UserModel> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _mockUsers[index] = user;
      return user;
    }
    throw Exception('User not found');
  }

  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUsers.removeWhere((u) => u.id == id);
  }
}
