import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';

class AuthRepository {
  final AuthService _service;

  AuthRepository(this._service);

  Future<UserModel> login(String email, String password) async {
    return _service.login(email, password);
  }

  Future<void> logout() async {
    return _service.logout();
  }

  Future<UserModel?> getCurrentUser() async {
    return _service.getCurrentUser();
  }

  Future<UserModel> updateProfile(UserModel user) async {
    return _service.updateProfile(user);
  }

  Future<void> updatePassword(String password) async {
    return _service.updatePassword(password);
  }

  Future<bool> checkConnection() async {
    return _service.checkConnection();
  }
}
