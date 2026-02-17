import '../services/activity_service.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  final ActivityService _service;

  ActivityRepository(this._service);

  Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    return _service.getRecentActivities(limit: limit);
  }

  Future<void> logActivity(ActivityModel activity) async {
    return _service.logActivity(activity);
  }
}
