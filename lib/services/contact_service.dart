import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_model.dart';

class ContactService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch paginated contacts, ordered by created_at descending
  Future<List<ContactModel>> getContacts({int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('contacts')
        .select()
        .order('created_at', ascending: false)
        .range(start, end);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ContactModel.fromJson(json)).toList();
  }

  /// Get a single contact by ID
  Future<ContactModel> getContactById(String id) async {
    final response = await _supabase
        .from('contacts')
        .select()
        .eq('id', id)
        .single();

    return ContactModel.fromJson(response);
  }

  /// Search contacts by name, email, or company
  Future<List<ContactModel>> searchContacts(String query, {int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('contacts')
        .select()
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%,email.ilike.%$query%,company_name.ilike.%$query%')
        .order('created_at', ascending: false)
        .range(start, end);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ContactModel.fromJson(json)).toList();
  }

  /// Create a new contact
  Future<ContactModel> addContact(ContactModel contact) async {
    final json = contact.toJson();
    // Remove empty ID so the DB generates one via uuid_generate_v4()
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

  /// Update an existing contact
  Future<ContactModel> updateContact(ContactModel contact) async {
    final json = contact.toJson();
    json['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('contacts')
        .update(json)
        .eq('id', contact.id)
        .select()
        .single();

    return ContactModel.fromJson(response);
  }

  /// Delete a contact by ID
  Future<void> deleteContact(String id) async {
    await _supabase.from('contacts').delete().eq('id', id);
  }

  /// Toggle the favorite status of a contact
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    await _supabase
        .from('contacts')
        .update({
          'is_favorite': !currentStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Get basic contact statistics
  Future<Map<String, dynamic>> getStats() async {
    final response = await _supabase.from('contacts').select('id, is_customer, is_favorite, created_at');
    final List<dynamic> data = response as List<dynamic>;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    int total = data.length;
    int customers = data.where((c) => c['is_customer'] == true).length;
    int leads = total - customers;
    int favorites = data.where((c) => c['is_favorite'] == true).length;
    int newThisMonth = data.where((c) {
      final createdAt = DateTime.tryParse(c['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(thirtyDaysAgo);
    }).length;

    return {
      'total': total,
      'leads': leads,
      'customers': customers,
      'favorites': favorites,
      'new_this_month': newThisMonth,
    };
  }
}
