
import '../../models/lead_model.dart';

final List<LeadModel> mockLeads = [
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
