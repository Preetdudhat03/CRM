
import '../models/lead_model.dart';

class LeadService {
  // Mock data for initial lead list
  static final List<LeadModel> _mockLeads = [
    LeadModel(
      id: 'l1',
      name: 'Rahul Patel',
      email: 'rahul.patel@gmail.com',
      phone: '+91 9876543210',
      source: 'Instagram',
      status: LeadStatus.newLead,
      assignedTo: 'Preet Dudhat',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      estimatedValue: 50000,
    ),
    LeadModel(
      id: 'l2',
      name: 'Tesla Inc (Solar Project)',
      email: 'procurement@tesla.com',
      phone: '+1 650-681-5000',
      source: 'Website',
      status: LeadStatus.interested,
      assignedTo: 'Sarah Connor',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      estimatedValue: 1200000,
    ),
    LeadModel(
      id: 'l3',
      name: 'Infosys Training',
      email: 'training@infosys.com',
      phone: '+91 80 2852 0261',
      source: 'Referral',
      status: LeadStatus.qualified,
      assignedTo: 'Preet Dudhat',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      estimatedValue: 75000,
    ),
    LeadModel(
      id: 'l4',
      name: 'Local Cafe Chain',
      email: 'owner@cafe.com',
      phone: '+1 555-0987',
      source: 'Cold Call',
      status: LeadStatus.contacted,
      assignedTo: 'Mike Ross',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      estimatedValue: 15000,
    ),
  ];

  Future<List<LeadModel>> getLeads() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    return List.from(_mockLeads);
  }

  Future<LeadModel> addLead(LeadModel lead) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newLead = lead.copyWith(id: 'l${_mockLeads.length + 1}');
    _mockLeads.add(newLead);
    return newLead;
  }

  Future<LeadModel> updateLead(LeadModel lead) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == lead.id);
    if (index != -1) {
      _mockLeads[index] = lead;
      return lead;
    }
    throw Exception('Lead not found');
  }

  Future<void> deleteLead(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockLeads.removeWhere((l) => l.id == id);
  }
}
