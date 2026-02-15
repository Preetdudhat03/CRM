
import '../../models/user_model.dart';
import '../../models/role_model.dart';

const UserModel mockUser = UserModel(
  id: 'u123',
  name: 'Preet Dudhat',
  email: 'preet.dudhat@crm.app',
  role: Role.admin, // User requested Admin role
);

final List<UserModel> mockUsers = [
  mockUser,
  const UserModel(
    id: 'u124',
    name: 'Rahul Patel',
    email: 'rahul@crm.app',
    role: Role.manager,
  ),
  const UserModel(
    id: 'u125',
    name: 'Sarah Connor',
    email: 'sarah@crm.app',
    role: Role.employee,
  ),
];
