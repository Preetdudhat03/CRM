import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/activity_service.dart';
import '../models/activity_model.dart';

final activityServiceProvider = Provider<ActivityService>(
  (ref) => ActivityService(),
);

/// Global recent activities (Home Screen)
final recentActivitiesProvider = FutureProvider<List<ActivityModel>>((
  ref,
) async {
  final service = ref.watch(activityServiceProvider);
  return service.getGlobalActivities();
});

/// Activities for a specific entity
final entityActivitiesProvider =
    FutureProvider.family<List<ActivityModel>, ({String type, String id})>((
      ref,
      arg,
    ) async {
      final service = ref.watch(activityServiceProvider);

      // Setup Realtime subscription for this specific entity
      final supabase = Supabase.instance.client;
      final channel = supabase
          .channel('activities_${arg.type}_${arg.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'activities',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'related_id',
              value: arg.id,
            ),
            callback: (payload) {
              ref.invalidateSelf();
            },
          )
          .subscribe();

      ref.onDispose(() {
        channel.unsubscribe();
      });

      return service.getEntityActivities(
        relatedType: arg.type,
        relatedId: arg.id,
      );
    });
