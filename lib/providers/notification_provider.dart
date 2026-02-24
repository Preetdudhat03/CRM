import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/role_model.dart';
import '../services/local_notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';
import 'notification_settings_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationServiceProvider));
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  final Ref _ref;
  RealtimeChannel? _realtimeChannel;

  NotificationNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    getNotifications();
    _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    final supabase = Supabase.instance.client;
    
    _realtimeChannel = supabase.channel('remote-notifications')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'contacts',
        callback: (payload) => _handleRemoteInsert(payload, 'Contact'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'leads',
        callback: (payload) => _handleRemoteInsert(payload, 'Lead'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'deals',
        callback: (payload) => _handleRemoteInsert(payload, 'Deal'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'tasks',
        callback: (payload) => _handleRemoteInsert(payload, 'Task'),
      )
      ..subscribe();
  }

  void _handleRemoteInsert(PostgresChangePayload payload, String entityName) {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    // Only Admin or Super Admin receive these global broadcast alerts
    if (currentUser.role != Role.admin && currentUser.role != Role.superAdmin) return;

    // Check if the current user is the one who created it (don't alert yourself)
    final newRow = payload.newRecord;
    final assignedTo = newRow['assigned_to'];
    if (assignedTo == currentUser.id) return; 

    // Extract basic title if available
    final titleField = newRow['title'] ?? newRow['name'] ?? 'New Item';
    
    final enableNativePushes = _ref.read(notificationSettingsProvider);

    final String msg = 'A new $entityName was created: $titleField';

    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: 'New $entityName (Global)',
      message: msg,
      date: DateTime.now(),
      relatedEntityId: newRow['id'],
      relatedEntityType: entityName.toLowerCase(),
    );

    addNotification(notification);

    if (enableNativePushes) {
      LocalNotificationService.showNotification(
         id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
         title: 'Team Update',
         body: msg,
      );
    }
  }

  Future<void> getNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    // Optimistically update local state so the feeds work real-time even if Supabase isn't synced yet
    if (state.hasValue) {
      state.whenData((notifications) {
        state = AsyncValue.data([notification, ...notifications]);
      });
    } else {
      state = AsyncValue.data([notification]);
    }

    try {
      await _repository.addNotification(notification);
    } catch (e) {
      print('Failed to add notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) {
            if (n.id == id) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList()
        );
      });
    } catch (e) {
      print('Failed to mark notification $id as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) => n.copyWith(isRead: true)).toList()
        );
      });
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  void pushNotificationLocally(String title, String message, {String? relatedEntityId, String? relatedEntityType, bool deduplicate = false}) {
    if (deduplicate) {
      bool exists = false;
      state.whenData((notifications) {
        exists = notifications.any((n) => n.title == title && n.relatedEntityId == relatedEntityId);
      });
      if (exists) return; // Don't add duplicate
    }
    
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: message,
      date: DateTime.now(),
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
    );

    // Check device notification preferences
    final enableNativePushes = _ref.read(notificationSettingsProvider);

    addNotification(notification);
    
    // Trigger actual device push notification if toggled ON
    if (enableNativePushes) {
      LocalNotificationService.showNotification(
         id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
         title: title,
         body: message,
      );
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider), ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
