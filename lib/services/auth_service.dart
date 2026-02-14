
import '../models/user_model.dart';
import '../models/role_model.dart';

class AuthService {
  // Mock user for initial setup
  static const UserModel _mockUser = UserModel(
    id: 'u123',
    name: 'Preet Dudhat',
    email: 'preet.dudhat@crm.app',
    role: Role.admin, // User requested Admin role
  );

  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return _mockUser;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> refreshToken() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<UserModel?> getCurrentUser() async {
    // Return mock user for now, as we don't have persistence yet
    return _mockUser;
  }
}
