import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';

class LeadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch paginated leads, ordered by created_at descending
  Future<List<LeadModel>> getLeads({int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

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

  /// Get a single lead by ID
  Future<LeadModel> getLeadById(String id) async {
    final response = await _supabase
        .from('leads')
        .select()
        .eq('id', id)
        .single();

    return LeadModel.fromJson(response);
  }

  /// Search leads by name, email, or source
  Future<List<LeadModel>> searchLeads(String query, {int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('leads')
        .select()
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%,email.ilike.%$query%,lead_source.ilike.%$query%')
        .order('created_at', ascending: false)
        .range(start, end);

    return (response as List).map((json) => LeadModel.fromJson(json)).toList();
  }

  /// Filter leads by status
  Future<List<LeadModel>> getLeadsByStatus(String status, {int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('leads')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false)
        .range(start, end);

    return (response as List).map((json) => LeadModel.fromJson(json)).toList();
  }

  /// Get leads assigned to a specific user
  Future<List<LeadModel>> getLeadsByAssignee(String userId, {int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('leads')
        .select()
        .eq('assigned_to', userId)
        .order('created_at', ascending: false)
        .range(start, end);

    return (response as List).map((json) => LeadModel.fromJson(json)).toList();
  }

  /// Create a new lead
  Future<LeadModel> addLead(LeadModel lead) async {
    final json = lead.toJson();

    final response = await _supabase
        .from('leads')
        .insert(json)
        .select()
        .single();

    return LeadModel.fromJson(response);
  }

  /// Update an existing lead
  Future<LeadModel> updateLead(LeadModel lead) async {
    final json = lead.toJson();
    json['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('leads')
        .update(json)
        .eq('id', lead.id)
        .select()
        .single();

    return LeadModel.fromJson(response);
  }

  /// Delete a lead by ID
  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }

  /// Converts a Lead to a Contact using the Supabase RPC function, with a fallback if missing.
  Future<String> convertLead(String leadId) async {
    try {
      final response = await _supabase.rpc('convert_lead', params: {
        'lead_uuid': leadId,
      });
      return response as String;
    } catch (e) {
      if (e.toString().contains('Could not find the function') || e.toString().contains('convert_lead')) {
        // Fallback: Perform manual conversion client-side if RPC doesn't exist

        // 1. Fetch lead
        final leadMap = await _supabase.from('leads').select().eq('id', leadId).single();

        // 2. Insert into contacts
        final contactData = {
          'first_name': leadMap['first_name'],
          'last_name': leadMap['last_name'],
          'email': leadMap['email'],
          'phone': leadMap['phone'],
          'company_name': leadMap['company'],
          'is_customer': false,
          'assigned_to': leadMap['assigned_to'],
          'notes': leadMap['notes'],
          'created_from_lead': true,
          'source_lead_id': leadId,
        };

        final contactRes = await _supabase.from('contacts').insert(contactData).select('id').single();
        final contactId = contactRes['id'] as String;

        // 3. Update lead
        await _supabase.from('leads').update({
          'status': 'converted',
          'converted_contact_id': contactId,
          'converted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', leadId);

        return contactId;
      }
      rethrow;
    }
  }

  /// Get lead pipeline statistics
  Future<Map<String, dynamic>> getStats() async {
    final response = await _supabase.from('leads').select('id, status, estimated_value, created_at');
    final List<dynamic> data = response as List<dynamic>;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    int total = data.length;
    int newLeads = data.where((l) => l['status'] == 'new_lead').length;
    int contacted = data.where((l) => l['status'] == 'contacted').length;
    int interested = data.where((l) => l['status'] == 'interested').length;
    int qualified = data.where((l) => l['status'] == 'qualified').length;
    int lost = data.where((l) => l['status'] == 'lost').length;
    int converted = data.where((l) => l['status'] == 'converted').length;
    int newThisMonth = data.where((l) {
      final createdAt = DateTime.tryParse(l['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(thirtyDaysAgo);
    }).length;

    double pipelineValue = data
        .where((l) => l['status'] != 'lost' && l['status'] != 'converted')
        .fold(0.0, (sum, l) => sum + ((l['estimated_value'] as num?)?.toDouble() ?? 0.0));

    return {
      'total': total,
      'new_leads': newLeads,
      'contacted': contacted,
      'interested': interested,
      'qualified': qualified,
      'lost': lost,
      'converted': converted,
      'pipeline_value': pipelineValue,
      'new_this_month': newThisMonth,
    };
  }
}
