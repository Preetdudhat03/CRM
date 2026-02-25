
import '../models/user_model.dart';
import '../models/role_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel> login(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final User? user = res.user;
      if (user == null) {
        throw Exception('Login failed: User is null');
      }
  
      // Fetch user role from profiles table
      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        final roleString = profile['role'] as String? ?? 'viewer';
        final role = Role.values.firstWhere(
          (e) => e.name == roleString,
          orElse: () => Role.viewer,
        );

        return UserModel(
          id: user.id,
          name: profile['name'] ?? user.userMetadata?['name'] ?? email.split('@')[0],
          email: profile['email'] ?? email,
          role: role,
          avatarUrl: profile['avatar_url'],
        );
      } catch (e) {
        // Fallback
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
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        throw Exception('Email not confirmed. Please check your inbox or ask admin to confirm.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
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

    try {
      // Fetch latest profile data to get up-to-date role
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final roleString = profile['role'] as String? ?? 'viewer';
      final role = Role.values.firstWhere(
        (e) => e.name == roleString,
        orElse: () => Role.viewer,
      );

      return UserModel(
        id: user.id,
        name: profile['name'] ?? user.email?.split('@')[0] ?? 'User',
        email: profile['email'] ?? user.email ?? '',
        role: role,
        avatarUrl: profile['avatar_url'],
      );
    } catch (e) {
      // Fallback to metadata if profile fetch fails (e.g. table issue)
      // print('Error fetching profile: $e');
      final roleString = user.userMetadata?['role'] as String? ?? 'viewer';
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

  Future<UserModel> updateProfile(UserModel user) async {
    final response = await _supabase
        .from('profiles')
        .update({
          'name': user.name,
          'avatar_url': user.avatarUrl,
          // 'email': user.email, // Usually not updated here directly
        })
        .eq('id', user.id)
        .select()
        .single();

    final roleString = response['role'] as String? ?? 'viewer';
    return user.copyWith(
      name: response['name'],
      avatarUrl: response['avatar_url'],
      role: Role.values.firstWhere(
        (e) => e.name == roleString,
        orElse: () => Role.viewer,
      ),
    );
  }
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }

  // Check connectivity by making a lightweight request
  Future<bool> checkConnection() async {
    try {
      // Don't query a table — RLS blocks unauthenticated queries.
      // Instead, try the auth settings endpoint which is always public.
      await _supabase.auth.getUser().timeout(const Duration(seconds: 8));
      // If this returns without network error, we're connected
      return true;
    } catch (e) {
      print('[Connection Check] Error: $e');
      print('[Connection Check] Error type: ${e.runtimeType}');
      final errorStr = e.toString();
      // AuthException means we reached the server (just not authenticated)
      if (e is AuthException ||
          errorStr.contains('not authenticated') ||
          errorStr.contains('invalid') ||
          errorStr.contains('session_not_found') ||
          errorStr.contains('JWT')) {
        return true; // Server IS reachable
      }
      return false;
    }
  }
}
