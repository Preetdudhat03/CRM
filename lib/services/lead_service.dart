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
    try {
      final response = await _supabase
          .from('leads')
          .update(lead.toJson())
          .eq('id', lead.id)
          .select()
          .single();

      return LeadModel.fromJson(response);
    } catch (e) {
      // If update fails on 'leads' table (e.g., ID not found), it likely originated from 'contacts'.
      // PROMOTE it to a real Lead by inserting into the 'leads' table with the same ID.
      try {
        // Use upsert to handle potential race conditions or existing ID
        // Note: This effectively "forks" the contact data into a Lead record.
        // Future updates will hit the 'leads' table.
        final json = lead.toJson();
        json['id'] = lead.id; // IMPORTANT: Force use of same ID to prevent duplication
        
        final response = await _supabase
            .from('leads')
            .upsert(json)
            .select()
            .single();

        return LeadModel.fromJson(response);
      } catch (e2) {
        // As a fallback, try updating the contact details at least
        try {
           final contactResponse = await _supabase
            .from('contacts')
            .update({
              'name': lead.name,
              'email': lead.email,
              'phone': lead.phone,
            })
            .eq('id', lead.id)
            .select()
            .single();
            
           return lead.copyWith(
              name: contactResponse['name'],
              email: contactResponse['email'],
              phone: contactResponse['phone'],
           );
        } catch (e3) {
           throw e; // Throw original error if all fails
        }
      }
    }
  }

  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }
}
