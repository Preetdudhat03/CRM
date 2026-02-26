import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';

class LeadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<LeadModel>> getLeads({int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    // 1. Fetch from 'leads' table with limits
    final leadsResponse = await _supabase
        .from('leads')
        .select()
        .order('created_at', ascending: false)
        .range(start, end);
    
    final List<LeadModel> leads = (leadsResponse as List)
        .map((json) => LeadModel.fromJson(json))
        .toList();

    return leads;
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

  /// Converts a Lead to a Contact using the Supabase RPC function.
  Future<String> convertLead(String leadId) async {
    final response = await _supabase.rpc('convert_lead', params: {
      'lead_uuid': leadId,
    });
    // The RPC returns the new contact UUID as a string
    return response as String;
  }
}
