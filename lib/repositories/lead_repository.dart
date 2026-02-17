import '../services/lead_service.dart';
import '../models/lead_model.dart';

class LeadRepository {
  final LeadService _service;

  LeadRepository(this._service);

  Future<List<LeadModel>> getLeads() async {
    return _service.getLeads();
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
}
