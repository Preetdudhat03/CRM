import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';

final activityServiceProvider = Provider<ActivityService>((ref) => ActivityService());

final recentActivityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final service = ref.watch(activityServiceProvider);
  return service.getRecentActivities();
});
