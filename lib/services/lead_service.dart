import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';

class LeadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<LeadModel>> getLeads() async {
    final response = await _supabase
        .from('leads')
        .select()
        .order('created_at', ascending: false);
    
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => LeadModel.fromJson(json)).toList();
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
