import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/activity_repository.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';

final activityServiceProvider = Provider<ActivityService>((ref) => ActivityService());

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(activityServiceProvider));
});

class ActivityNotifier extends StateNotifier<AsyncValue<List<ActivityModel>>> {
  final ActivityRepository _repository;
  RealtimeChannel? _realtimeChannel;

  ActivityNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadActivities();
    _subscribeToRealtime();
  }

  Future<void> loadActivities() async {
    try {
      if (!state.hasValue) state = const AsyncValue.loading();
      final activities = await _repository.getRecentActivities();
      state = AsyncValue.data(activities);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;
    _realtimeChannel = supabase
        .channel('public:activities')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          callback: (payload) {
            loadActivities();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final recentActivityProvider = StateNotifierProvider<ActivityNotifier, AsyncValue<List<ActivityModel>>>((ref) {
  return ActivityNotifier(ref.watch(activityRepositoryProvider));
});
