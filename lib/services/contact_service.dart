import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_model.dart';

class ContactService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ContactModel>> getContacts() async {
    final response = await _supabase
        .from('contacts')
        .select()
        .order('created_at', ascending: false);
    
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ContactModel.fromJson(json)).toList();
  }

  Future<ContactModel> addContact(ContactModel contact) async {
    final json = contact.toJson();
    if (json['id'] == null || json['id'].toString().isEmpty) {
      json.remove('id');
    }
    
    final response = await _supabase
        .from('contacts')
        .insert(json)
        .select()
        .single();
    
    return ContactModel.fromJson(response);
  }

  Future<ContactModel> updateContact(ContactModel contact) async {
    final response = await _supabase
        .from('contacts')
        .update(contact.toJson())
        .eq('id', contact.id)
        .select()
        .single();

    return ContactModel.fromJson(response);
  }

  Future<void> deleteContact(String id) async {
    await _supabase.from('contacts').delete().eq('id', id);
  }
}
