import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';

class LeadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<LeadModel>> getLeads() async {
    // 1. Fetch from 'leads' table
    final leadsResponse = await _supabase
        .from('leads')
        .select()
        .order('created_at', ascending: false);
    
    final List<LeadModel> leads = (leadsResponse as List)
        .map((json) => LeadModel.fromJson(json))
        .toList();

    // 2. Fetch from 'contacts' table where status is 'lead'
    final contactsResponse = await _supabase
        .from('contacts')
        .select()
        .eq('status', 'lead')
        .order('created_at', ascending: false);

    final List<LeadModel> contactLeads = (contactsResponse as List).map((json) {
      // Map Contact JSON to LeadModel
      return LeadModel(
        id: json['id'],
        name: json['name'],
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        source: 'Contact List', // Indicate it came from contacts
        status: LeadStatus.newLead, // Default status mapping
        assignedTo: '', // Unknown
        createdAt: DateTime.parse(json['created_at']),
        estimatedValue: 0,
      );
    }).toList();

    // Merge and sort
    final allLeads = [...leads, ...contactLeads];
    // Remove duplicates based on ID just in case
    final uniqueLeads = {for (var l in allLeads) l.id: l}.values.toList();
    uniqueLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return uniqueLeads;
  }

  Future<LeadModel> addLead(LeadModel lead) async {
    final json = lead.toJson();
    // ID is not included in toJson, so no need to fail unless I add logic later
    
    final response = await _supabase
        .from('leads')
        .insert(json)
        .select()
        .single();
    
    return LeadModel.fromJson(response);
  }

  Future<LeadModel> updateLead(LeadModel lead) async {
    final response = await _supabase
        .from('leads')
        .update(lead.toJson())
        .eq('id', lead.id)
        .select()
        .single();

    return LeadModel.fromJson(response);
  }

  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }
}
