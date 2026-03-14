import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log_model.dart';

class AuditLogService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch paginated audit logs for admin investigations
  Future<List<AuditLogModel>> getAuditLogs({
    int page = 0,
    int pageSize = 20,
    String? userId,
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    var query = _supabase.from('audit_logs').select().order('created_at', ascending: false);

    if (userId != null && userId.isNotEmpty) query = query.eq('user_id', userId);
    if (action != null && action.isNotEmpty && action != 'all') query = query.eq('action', action);
    if (entityType != null && entityType.isNotEmpty && entityType != 'all') query = query.eq('entity_type', entityType);
    if (startDate != null) query = query.gte('created_at', startDate.toIso8601String());
    if (endDate != null) query = query.lte('created_at', endDate.toIso8601String());

    final response = await query.range(start, end);
    return (response as List).map((json) => AuditLogModel.fromJson(json)).toList();
  }

  /// Fire-and-forget logging utility for the service layer
  static Future<void> log({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? organizationId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      // Attempt resolving missing organization id if user is available
      String? actualOrgId = organizationId;
      if (actualOrgId == null || actualOrgId.isEmpty) {
        if (user != null) {
          final profileData = await supabase.from('profiles').select('organization_id').eq('id', user.id).maybeSingle();
          if (profileData != null) {
             actualOrgId = profileData['organization_id'];
          }
        }
      }

      await supabase.from('audit_logs').insert({
        'organization_id': (actualOrgId != null && actualOrgId.isEmpty) ? null : actualOrgId,
        'user_id': user?.id,
        'user_email': user?.email,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_values': oldValues,
        'new_values': newValues,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[AuditLogService] Log failure: $e');
    }
  }
}
