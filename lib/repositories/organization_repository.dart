import '../services/organization_service.dart';
import '../models/organization_model.dart';
import '../models/organization_member_model.dart';

class OrganizationRepository {
  final OrganizationService _service;

  OrganizationRepository(this._service);

  Future<OrganizationModel?> getCurrentOrganization() async {
    return _service.getCurrentOrganization();
  }

  Future<OrganizationModel> createOrganization(String name) async {
    return _service.createOrganization(name);
  }

  Future<OrganizationModel> updateOrganization(OrganizationModel org) async {
    return _service.updateOrganization(org);
  }

  Future<List<OrganizationModel>> getUserOrganizations() async {
    return _service.getUserOrganizations();
  }

  Future<void> switchOrganization(String orgId) async {
    return _service.switchOrganization(orgId);
  }

  Future<List<Map<String, dynamic>>> getInvitations(String orgId) async {
    return _service.getInvitations(orgId);
  }

  Future<void> createInvitation({
    required String orgId,
    required String email,
    String role = 'employee',
  }) async {
    return _service.createInvitation(
      orgId: orgId,
      email: email,
      role: role,
    );
  }

  Future<void> deleteInvitation(String inviteId) async {
    return _service.deleteInvitation(inviteId);
  }

  Future<List<OrganizationMemberModel>> listMembers(String orgId) async {
    return _service.listMembers(orgId);
  }

  Future<OrganizationMemberModel> inviteMember({
    required String orgId,
    required String email,
    String role = 'employee',
  }) async {
    return _service.inviteMember(orgId: orgId, email: email, role: role);
  }

  Future<List<Map<String, dynamic>>> getUserInvitations() async {
    return _service.getUserInvitations();
  }

  Future<void> acceptInvitation(String inviteId) async {
    return _service.acceptInvitation(inviteId);
  }

  Future<void> removeMember(String memberId) async {
    return _service.removeMember(memberId);
  }

  Future<void> updateMemberRole(String memberId, String newRole) async {
    return _service.updateMemberRole(memberId, newRole);
  }

  Future<void> deleteOrganization(String orgId) async {
    return _service.deleteOrganization(orgId);
  }

  Future<void> leaveOrganization(String orgId) async {
    return _service.leaveOrganization(orgId);
  }
}
