import '../models/user_model.dart';
import '../models/role_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Retrieve all users from the public 'users' table
  // This requires the 'users' table to be populated.
  // We should ideally have a trigger in Supabase to sync auth.users to public.users.
  Future<List<UserModel>> getUsers() async {
    try {
      // Try to fetch from 'profiles' table
      final data = await _supabase.from('profiles').select();

      return (data as List).map((json) {
        return UserModel(
          id: json['id'],
          name: json['name'] ?? 'Unknown',
          email: json['email'] ?? '',
          role: Role.values.firstWhere(
            (e) => e.name == (json['role'] ?? 'viewer'),
            orElse: () => Role.viewer,
          ),
          avatarUrl: json['avatar_url'],
        );
      }).toList();
    } catch (e) {
      // Fallback to mock if table missing, for development safety
      print('Error fetching users: $e');
      return [];
    }
  }

  // To add a user, we effectively "Invite" them or just create a profile placeholder.
  // Real user creation happens via Auth Sign Up.
  // For this IAM demo, we will creating a profile entry. 
  // NOTE: This does NOT create a login account. 
  // In a real app, you'd call an Edge Function to invite the user.
  Future<UserModel> addUser(UserModel user) async {
    // This is a placeholder for the "Invite User" flow.
    // We will insert into profiles just to show them in the list.
    // The ID would ideally come from the auth user creation.
    // Since we can't create auth user here, we'll generate a temp ID or fail.
    
    // BETTER APPROACH: Use a strictly typed "Invite" function which calls an RPC or Edge Function.
    // For now, we simulate success by adding to local state or throwing "Not Implemented" for real backend.
    
    // Let's implement a visual-only addition if backend logic is missing, 
    // BUT user wants "Impl IAM".
    // I will enable listing and updating ROLES.
    
    // 1. Create profile (assuming trigger doesn't exist or we want to pre-fill)
    // We can't create an ID. 
    // We will throw an error saying "Please use Registration screen to create users" 
    // OR valid IAM flow: Admin creates user -> Edge Function -> Auth User + Profile.
    
    // Given the constraints, I will implement 'updateUser' (Role Change) which is the most critical IAM feature.
    // 'addUser' will be "Invite" which sends an email (mocked).
    
    throw UnimplementedError('To add users, they must register or be invited via Edge Functions.');
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      // Update the profile's role
      final response = await _supabase
          .from('profiles')
          .update({
            'name': user.name,
            'role': user.role.name,
          })
          .eq('id', user.id)
          .select()
          .single();

      return UserModel(
        id: response['id'],
        name: response['name'],
        email: response['email'],
        role: Role.values.firstWhere(
          (e) => e.name == response['role'],
          orElse: () => Role.viewer,
        ),
        avatarUrl: response['avatar_url'],
      );
    } catch (e) {
      // If direct update fails (e.g. RLS), try via Admin RPC
      try {
        final response = await _supabase.rpc('admin_update_profile', params: {
          'target_user_id': user.id,
          'new_name': user.name,
          'new_role': user.role.name,
        });

        // Use the returned data or the input user if RPC is void/bool
        // The SQL function returns the updated fields
        final data = response as Map<String, dynamic>;
        
        return UserModel(
          id: data['id'] ?? user.id,
          name: data['name'] ?? user.name,
          email: user.email, // Email usually doesn't change here
          role: Role.values.firstWhere(
            (e) => e.name == (data['role'] ?? user.role.name),
            orElse: () => Role.viewer,
          ),
          avatarUrl: data['avatar_url'] ?? user.avatarUrl,
        );
      } catch (rpcError) {
        // If both fail, throw the original error
        throw e;
      }
    }
  }

  Future<void> deleteUser(String id) async {
    // Soft delete or hard delete from profiles
    await _supabase.from('profiles').delete().eq('id', id);
    // Note: This doesn't delete from auth.users without a trigger/function.
  }
}
