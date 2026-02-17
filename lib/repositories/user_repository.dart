import '../services/user_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final UserService _service;

  UserRepository(this._service);

  Future<List<UserModel>> getUsers() async {
    return _service.getUsers();
  }

  Future<UserModel> addUser(UserModel user) async {
    return _service.addUser(user);
  }

  Future<UserModel> updateUser(UserModel user) async {
    return _service.updateUser(user);
  }

  Future<void> deleteUser(String id) async {
    return _service.deleteUser(id);
  }
}
