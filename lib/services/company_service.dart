import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_model.dart';

class CompanyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch paginated companies, ordered by name
  Future<List<CompanyModel>> getCompanies({
    int page = 0,
    int pageSize = 20,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('companies')
        .select()
        .order('name', ascending: true)
        .range(start, end);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => CompanyModel.fromJson(json)).toList();
  }

  /// Get a single company by ID
  Future<CompanyModel> getCompanyById(String id) async {
    final response = await _supabase
        .from('companies')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) throw Exception('Company not found');

    return CompanyModel.fromJson(response);
  }

  /// Search companies by name or industry
  Future<List<CompanyModel>> searchCompanies(
    String query, {
    int page = 0,
    int pageSize = 20,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('companies')
        .select()
        .or('name.ilike.%$query%,industry.ilike.%$query%')
        .order('name', ascending: true)
        .range(start, end);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => CompanyModel.fromJson(json)).toList();
  }

  /// Create a new company
  Future<CompanyModel> addCompany(CompanyModel company) async {
    final json = company.toJson();
    if (json['id'] == null || json['id'].toString().isEmpty) {
      json.remove('id');
    }

    final response = await _supabase
        .from('companies')
        .insert(json)
        .select()
        .maybeSingle();

    if (response == null) throw Exception('Failed to create company');

    return CompanyModel.fromJson(response);
  }

  /// Update an existing company
  Future<CompanyModel> updateCompany(CompanyModel company) async {
    final json = company.toJson();
    json['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('companies')
        .update(json)
        .eq('id', company.id)
        .select()
        .maybeSingle();

    if (response == null) throw Exception('Company not found or access denied');

    return CompanyModel.fromJson(response);
  }

  /// Delete a company by ID
  Future<void> deleteCompany(String id) async {
    await _supabase.from('companies').delete().eq('id', id);
  }

  /// Get company statistics (e.g., total companies, total revenue)
  Future<Map<String, dynamic>> getStats() async {
    final response = await _supabase
        .from('companies')
        .select('id, revenue, created_at');
    final List<dynamic> data = response as List<dynamic>;

    double totalRevenue = 0;
    for (var item in data) {
      totalRevenue += (item['revenue'] as num?)?.toDouble() ?? 0.0;
    }

    return {'total': data.length, 'totalRevenue': totalRevenue};
  }
}
