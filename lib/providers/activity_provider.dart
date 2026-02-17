import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/activity_repository.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';

final activityServiceProvider = Provider<ActivityService>((ref) => ActivityService());

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(activityServiceProvider));
});


final recentActivityProvider = FutureProvider<List<ActivityModel>>((ref) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getRecentActivities();
});
