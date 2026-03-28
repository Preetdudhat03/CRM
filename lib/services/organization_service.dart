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
      // 1. Get the active organication ID from the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) return null;

      final orgId = profileResponse['organization_id'];
      if (orgId == null) {
        // Fallback: If no active org is set, try to find any membership
        final membershipResponse = await _supabase
            .from('organization_members')
            .select('organization_id')
            .eq('user_id', userId)
            .limit(1)
            .maybeSingle();
        
        if (membershipResponse == null) return null;
        return _fetchOrgDetails(membershipResponse['organization_id']);
      }

      return _fetchOrgDetails(orgId);
    } catch (e) {
      print('[OrganizationService] Error fetching org: $e');
      return null;
    }
  }

  /// Helper to fetch organization details by ID
  Future<OrganizationModel?> _fetchOrgDetails(String orgId) async {
    try {
      final orgResponse = await _supabase
          .from('organizations')
          .select()
          .eq('id', orgId)
          .maybeSingle();

      if (orgResponse == null) return null;

      return OrganizationModel.fromJson(orgResponse);
    } catch (e) {
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
          .maybeSingle();

      if (orgResponse == null) throw Exception('Failed to fetch created organization');

      return OrganizationModel.fromJson(orgResponse);
    } catch (e) {
      // Fallback: manual creation if RPC doesn't exist
      if (e.toString().contains('Could not find the function')) {
        final orgResponse = await _supabase
            .from('organizations')
            .insert({'name': name, 'owner_id': userId})
            .select()
            .maybeSingle();

        if (orgResponse == null) throw Exception('Failed to create organization');

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
        .maybeSingle();

    if (response == null) throw Exception('Organization not found or access denied');

    return OrganizationModel.fromJson(response);
  }

  /// List all organizations the current user belongs to
  Future<List<OrganizationModel>> getUserOrganizations() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('organization_members')
          .select('organizations(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => OrganizationModel.fromJson(item['organizations']))
          .toList();
    } catch (e) {
      print('[OrganizationService] Error fetching user orgs: $e');
      return [];
    }
  }

  /// Switch the active organization for the current user
  Future<void> switchOrganization(String orgId) async {
    try {
      await _supabase.rpc('switch_active_organization', params: {'p_org_id': orgId});
    } catch (e) {
      print('[OrganizationService] Error switching org: $e');
      rethrow;
    }
  }

  /// List all pending and accepted invites for an organization
  Future<List<Map<String, dynamic>>> getInvitations(String orgId) async {
    try {
      final response = await _supabase
          .from('org_invites')
          .select('*, inviter:profiles!inviter_id(name)')
          .eq('organization_id', orgId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[OrganizationService] Error fetching invites: $e');
      return [];
    }
  }

  Future<void> createInvitation({
    required String orgId,
    required String email,
    String role = 'employee',
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final cleanEmail = email.trim().toLowerCase();

    try {
      await _supabase.from('org_invites').insert({
        'organization_id': orgId,
        'email': cleanEmail,
        'role': role,
        'inviter_id': userId,
      });
    } catch (e) {
      if (e is PostgrestException && e.code == '23505') {
        // Achievement: Re-send logic
        // Update the timestamp of the existing pending invite to 'bump' it
        await _supabase
            .from('org_invites')
            .update({'created_at': DateTime.now().toIso8601String()})
            .eq('organization_id', orgId)
            .eq('email', email)
            .eq('status', 'pending');
        return;
      }
      print('[OrganizationService] Error creating invite: $e');
      rethrow;
    }
  }

  /// Cancel/Delete an invitation
  Future<void> deleteInvitation(String inviteId) async {
    await _supabase.from('org_invites').delete().eq('id', inviteId);
  }

  /// Get invitations sent TO the current user
  Future<List<Map<String, dynamic>>> getUserInvitations() async {
    final email = _supabase.auth.currentUser?.email?.toLowerCase();
    if (email == null) return [];

    final response = await _supabase
        .from('org_invites')
        .select('*, organizations!organization_id(name)')
        .ilike('email', email)
        .eq('status', 'pending');

    return response as List<Map<String, dynamic>>;
  }

  /// Accept an invitation
  Future<void> acceptInvitation(String inviteId) async {
    // 1. Perform membership updates atomically using RPC
    // Since Supabase RLS causes issues when cross-evaluating permissions across 
    // organization_members, org_invites, and profiles simultaneously during a join,
    // we use a PostgreSQL SECURITY DEFINER function to handle this transaction safely.
    try {
      await _supabase.rpc('accept_invitation', params: {
        'p_invite_id': inviteId,
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('already a member') || e.code == '23505') {
        // Silently handle if they bypassed and already exist
      } else {
        rethrow;
      }
    }
    // 3. Optional: Notify inviter (future enhancement)
  }

  /// Legacy: Invite a user to the organization by email (requires user to exist)
  /// Note: Prefer createInvitation for SaaS flow
  Future<OrganizationMemberModel> inviteMember({
    required String orgId,
    required String email,
    String role = 'employee',
  }) async {
    // Keep for backward compatibility if needed, but redirects to the existing logic
    final profileResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (profileResponse == null) {
      // If user doesn't exist, use the new invitation system
      await createInvitation(orgId: orgId, email: email, role: role);
      throw Exception('User not found. An invitation email has been sent to $email instead.');
    }

    final userId = profileResponse['id'] as String;

    // Direct upsert (admin only)
    final response = await _supabase
        .from('organization_members')
        .upsert({
          'organization_id': orgId,
          'user_id': userId,
          'role': role,
        }, onConflict: 'organization_id, user_id')
        .select('*, profiles!user_id(name, email)')
        .maybeSingle();

    if (response == null) throw Exception('Failed to invite member');

    return OrganizationMemberModel.fromJson(response);
  }

  /// Remove a member from the organization
  Future<void> removeMember(String memberId) async {
    // Get the member info first to update their profile
    final member = await _supabase
        .from('organization_members')
        .select('user_id, organization_id')
        .eq('id', memberId)
        .maybeSingle();
    
    if (member == null) throw Exception('Member not found');

    await _supabase.from('organization_members').delete().eq('id', memberId);

    // If this was their active org, clear it (or set to another)
    final profile = await _supabase
        .from('profiles')
        .select('organization_id')
        .eq('id', member['user_id'])
        .maybeSingle();
    
    if (profile == null) throw Exception('User profile not found');

    if (profile['organization_id'] == member['organization_id']) {
      // Find another org they belong to
      final otherMember = await _supabase
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', member['user_id'])
          .limit(1)
          .maybeSingle();

      await _supabase
          .from('profiles')
          .update({'organization_id': otherMember?['organization_id']})
          .eq('id', member['user_id']);
    }
  }

  /// List all members of an organization (with profile data)
  Future<List<OrganizationMemberModel>> listMembers(String orgId) async {
    final response = await _supabase
        .from('organization_members')
        .select('*, profiles!user_id(name, email)')
        .eq('organization_id', orgId)
        .order('joined_at', ascending: true);

    return (response as List)
        .map((json) => OrganizationMemberModel.fromJson(json))
        .toList();
  }

  /// Update a member's role
  Future<void> updateMemberRole(String memberId, String newRole) async {
    await _supabase
        .from('organization_members')
        .update({'role': newRole})
        .eq('id', memberId);
  }

  /// Delete an entire organization (Owner only)
  Future<void> deleteOrganization(String orgId) async {
    try {
      await _supabase.rpc('delete_organization', params: {'p_org_id': orgId});
    } catch (e) {
      print('[OrganizationService] Error deleting org: $e');
      rethrow;
    }
  }

  /// Leave an organization
  Future<void> leaveOrganization(String orgId) async {
    try {
      await _supabase.rpc('leave_organization', params: {'p_org_id': orgId});
    } catch (e) {
      print('[OrganizationService] Error leaving org: $e');
      rethrow;
    }
  }
}
