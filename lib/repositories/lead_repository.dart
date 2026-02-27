import '../services/lead_service.dart';
import '../models/lead_model.dart';

class LeadRepository {
  final LeadService _service;

  LeadRepository(this._service);

  Future<List<LeadModel>> getLeads({int page = 0, int pageSize = 20}) async {
    return _service.getLeads(page: page, pageSize: pageSize);
  }

  Future<LeadModel> getLeadById(String id) async {
    return _service.getLeadById(id);
  }

  Future<List<LeadModel>> searchLeads(String query, {int page = 0, int pageSize = 20}) async {
    return _service.searchLeads(query, page: page, pageSize: pageSize);
  }

  Future<List<LeadModel>> getLeadsByStatus(String status, {int page = 0, int pageSize = 20}) async {
    return _service.getLeadsByStatus(status, page: page, pageSize: pageSize);
  }

  Future<List<LeadModel>> getLeadsByAssignee(String userId, {int page = 0, int pageSize = 20}) async {
    return _service.getLeadsByAssignee(userId, page: page, pageSize: pageSize);
  }

  Future<LeadModel> addLead(LeadModel lead) async {
    return _service.addLead(lead);
  }

  Future<LeadModel> updateLead(LeadModel lead) async {
    return _service.updateLead(lead);
  }

  Future<void> deleteLead(String id) async {
    return _service.deleteLead(id);
  }

  Future<String> convertLead(String id) async {
    return _service.convertLead(id);
  }

  Future<Map<String, dynamic>> getStats() async {
    return _service.getStats();
  }
}
