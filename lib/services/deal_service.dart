import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deal_model.dart';

class DealService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<DealModel>> getDeals() async {
    final response = await _supabase
        .from('deals')
        .select('*, contacts(name, company)');
    
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) {
      // Flatten the nested contacts object
      final contact = json['contacts'];
      if (contact != null) {
        json['contact_name'] = contact['name'];
        // If company_name is null in deal, fall back to contact's company
        if (json['company_name'] == null) {
          json['company_name'] = contact['company'];
        }
      }
      return DealModel.fromJson(json);
    }).toList();
  }

  Future<DealModel> addDeal(DealModel deal) async {
    final json = deal.toJson();
    // Remove denormalized fields if we don't want to store them in deals table
    // But schema.sql has company_name, so we keep it. 
    // contact_name is NOT in schema, so we should remove it to avoid error?
    // Supabase ignores unknown columns usually? No, it throws error.
    json.remove('contact_name'); 
    
    final response = await _supabase
        .from('deals')
        .insert(json)
        .select('*, contacts(name, company)')
        .single();
    
    final contact = response['contacts'];
    if (contact != null) {
      response['contact_name'] = contact['name'];
    }

    return DealModel.fromJson(response);
  }

  Future<DealModel> updateDeal(DealModel deal) async {
    final json = deal.toJson();
    json.remove('contact_name');

    final response = await _supabase
        .from('deals')
        .update(json)
        .eq('id', deal.id)
        .select('*, contacts(name, company)')
        .single();

    final contact = response['contacts'];
    if (contact != null) {
      response['contact_name'] = contact['name'];
    }

    return DealModel.fromJson(response);
  }

  Future<void> deleteDeal(String id) async {
    await _supabase.from('deals').delete().eq('id', id);
  }
}
