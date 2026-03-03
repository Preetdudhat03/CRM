import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch activities for a specific entity (lead, contact, deal, company)
  Future<List<ActivityModel>> getEntityActivities({
    required String relatedType,
    required String relatedId,
    int page = 0,
    int pageSize = 20,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('activities')
        .select()
        .eq('related_type', relatedType)
        .eq('related_id', relatedId)
        .order('created_at', ascending: false)
        .range(start, end);

    return (response as List)
        .map((json) => ActivityModel.fromJson(json))
        .toList();
  }

  /// Global activity feed (Home Screen)
  Future<List<ActivityModel>> getGlobalActivities({int limit = 20}) async {
    final response = await _supabase
        .from('activities')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ActivityModel.fromJson(json))
        .toList();
  }

  /// Create an activity record
  Future<void> createActivity(ActivityModel activity) async {
    final json = activity.toJson();
    await _supabase.from('activities').insert(json);
  }

  /// Paginated global activities
  Future<List<ActivityModel>> getAllActivities({
    int page = 0,
    int pageSize = 20,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('activities')
        .select()
        .order('created_at', ascending: false)
        .range(start, end);

    return (response as List)
        .map((json) => ActivityModel.fromJson(json))
        .toList();
  }

  /// Static utility for easy logging from service layer
  static Future<void> log({
    String? relatedType,
    String? relatedId,
    String? activityType,
    required String title,
    String description = '',
    Map<String, dynamic> metadata = const {},
    String? organizationId,
    // Add backward compatibility fields
    String? type,
    String? relatedEntityId,
    String? relatedEntityType,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Handle parameter fallbacks
      final rType = relatedType ?? relatedEntityType ?? type ?? 'other';
      final rId = relatedId ?? relatedEntityId ?? '';
      final aType = activityType ?? type ?? 'other';

      await supabase.from('activities').insert({
        'related_type': rType,
        'related_id': rId,
        'activity_type': aType,
        'title': title,
        'description': description,
        'metadata': metadata,
        'created_by': userId,
        'organization_id': organizationId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Fire and forget
      print('[ActivityService] Log failure: $e');
    }
  }
}
