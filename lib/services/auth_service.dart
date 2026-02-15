
import '../models/user_model.dart';
import '../models/role_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel> login(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    final User? user = res.user;
    if (user == null) {
      throw Exception('Login failed: User is null');
    }

    // Fetch user role from metadata or profiles table
    // For now, defaulting to Admin if not set, or fetching from metadata
    final roleString = user.userMetadata?['role'] as String? ?? 'admin';
    final role = Role.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => Role.viewer,
    );

    return UserModel(
      id: user.id,
      name: user.userMetadata?['name'] ?? email.split('@')[0],
      email: email,
      role: role,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> refreshToken() async {
    // Supabase handles token refresh automatically
  }

  Future<UserModel?> getCurrentUser() async {
    final User? user = _supabase.auth.currentUser;
    if (user == null) return null;

    final roleString = user.userMetadata?['role'] as String? ?? 'admin';
    final role = Role.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => Role.viewer,
    );

    return UserModel(
      id: user.id,
      name: user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      role: role,
    );
  }

  // Helper to register a new user (optional, good to have)
  Future<UserModel> register(String email, String password, String name, Role role) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
      },
    );
    
    final User? user = res.user;
    if (user == null) {
      throw Exception('Registration failed');
    }

    return UserModel(
      id: user.id,
      name: name,
      email: email,
      role: role,
    );
  }
}
