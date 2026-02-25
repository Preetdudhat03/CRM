
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    final response = await _supabase
        .from('activities')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Quick fire-and-forget activity logger
  /// Call this after any CRUD operation
  static Future<void> log({
    required String title,
    String description = '',
    required String type, // 'contact', 'lead', 'deal', 'task'
    String? relatedEntityId,
    String? relatedEntityType,
  }) async {
    try {
      await Supabase.instance.client.from('activities').insert({
        'title': title,
        'description': description,
        'type': type,
        'date': DateTime.now().toIso8601String(),
        'related_entity_id': relatedEntityId,
        'related_entity_type': relatedEntityType ?? type,
      });
    } catch (e) {
      // Fire and forget — never crash the app for activity logging
      print('[ActivityService] log error: $e');
    }
  }
}
