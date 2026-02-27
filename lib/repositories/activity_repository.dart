import '../services/activity_service.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  final ActivityService _service;

  ActivityRepository(this._service);

  Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    final activities = await _service.getRecentActivities(limit: limit);
    return activities.map((json) => ActivityModel.fromJson(json)).toList();
  }

  Future<void> logActivity(ActivityModel activity) async {
    return ActivityService.log(
      title: activity.title,
      description: activity.description ?? '',
      type: activity.type.name,
      relatedEntityId: activity.relatedEntityId,
      relatedEntityType: activity.relatedEntityType,
    );
  }
}
