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

  Future<List<OrganizationMemberModel>> listMembers(String orgId) async {
    return _service.listMembers(orgId);
  }

  Future<OrganizationMemberModel> inviteMember({
    required String orgId,
    required String email,
    String role = 'member',
  }) async {
    return _service.inviteMember(orgId: orgId, email: email, role: role);
  }

  Future<void> removeMember(String memberId) async {
    return _service.removeMember(memberId);
  }

  Future<void> updateMemberRole(String memberId, String newRole) async {
    return _service.updateMemberRole(memberId, newRole);
  }
}
