import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_model.dart';
import '../models/organization_member_model.dart';

class OrganizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Get the current user's organization
  Future<OrganizationModel?> getCurrentOrganization() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      // Find the user's membership, then fetch the org
      final membershipResponse = await _supabase
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (membershipResponse == null) return null;

      final orgId = membershipResponse['organization_id'];
      final orgResponse = await _supabase
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();

      return OrganizationModel.fromJson(orgResponse);
    } catch (e) {
      print('[OrganizationService] Error fetching org: $e');
      return null;
    }
  }

  /// Create a new organization and add the current user as owner
  Future<OrganizationModel> createOrganization(String name) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    try {
      // Use the RPC function for atomic creation
      final orgId = await _supabase.rpc(
        'create_organization_for_user',
        params: {'org_name': name, 'p_user_id': userId},
      );

      final orgResponse = await _supabase
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();

      return OrganizationModel.fromJson(orgResponse);
    } catch (e) {
      // Fallback: manual creation if RPC doesn't exist
      if (e.toString().contains('Could not find the function')) {
        final orgResponse = await _supabase
            .from('organizations')
            .insert({'name': name, 'owner_id': userId})
            .select()
            .single();

        final org = OrganizationModel.fromJson(orgResponse);

        await _supabase.from('organization_members').insert({
          'organization_id': org.id,
          'user_id': userId,
          'role': 'owner',
        });

        // Update profile
        await _supabase
            .from('profiles')
            .update({'organization_id': org.id})
            .eq('id', userId);

        return org;
      }
      rethrow;
    }
  }

  /// Update organization details
  Future<OrganizationModel> updateOrganization(OrganizationModel org) async {
    final response = await _supabase
        .from('organizations')
        .update({'name': org.name, 'plan': org.plan})
        .eq('id', org.id)
        .select()
        .single();

    return OrganizationModel.fromJson(response);
  }

  /// List all members of an organization (with profile data)
  Future<List<OrganizationMemberModel>> listMembers(String orgId) async {
    final response = await _supabase
        .from('organization_members')
        .select('*, profiles:user_id(name, email)')
        .eq('organization_id', orgId)
        .order('joined_at', ascending: true);

    return (response as List)
        .map((json) => OrganizationMemberModel.fromJson(json))
        .toList();
  }

  /// Invite a user to the organization by email
  /// Returns the created membership or throws if user not found
  Future<OrganizationMemberModel> inviteMember({
    required String orgId,
    required String email,
    String role = 'member',
  }) async {
    // Look up the user by email in profiles
    final profileResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception(
        'No user found with email $email. They must register first.',
      );
    }

    final userId = profileResponse['id'] as String;

    // Check if already a member
    final existing = await _supabase
        .from('organization_members')
        .select('id')
        .eq('organization_id', orgId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('User is already a member of this organization.');
    }

    // Add membership
    final response = await _supabase
        .from('organization_members')
        .insert({
          'organization_id': orgId,
          'user_id': userId,
          'role': role,
        })
        .select('*, profiles:user_id(name, email)')
        .single();

    // Update the user's profile with this org
    await _supabase
        .from('profiles')
        .update({'organization_id': orgId})
        .eq('id', userId);

    return OrganizationMemberModel.fromJson(response);
  }

  /// Remove a member from the organization
  Future<void> removeMember(String memberId) async {
    // Get the member info first to update their profile
    final member = await _supabase
        .from('organization_members')
        .select('user_id')
        .eq('id', memberId)
        .single();

    await _supabase.from('organization_members').delete().eq('id', memberId);

    // Clear org from their profile
    await _supabase
        .from('profiles')
        .update({'organization_id': null})
        .eq('id', member['user_id']);
  }

  /// Update a member's role
  Future<void> updateMemberRole(String memberId, String newRole) async {
    await _supabase
        .from('organization_members')
        .update({'role': newRole})
        .eq('id', memberId);
  }
}
