
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    final response = await _supabase
        .from('activities')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ActivityModel.fromJson(json)).toList();
  }

  Future<void> logActivity(ActivityModel activity) async {
    await _supabase.from('activities').insert(activity.toJson());
  }
}
