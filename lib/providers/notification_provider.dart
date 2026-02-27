import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../services/local_notification_service.dart';
import 'auth_provider.dart';
import 'package:uuid/uuid.dart';

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, bool>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<bool> {
  NotificationSettingsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationServiceProvider));
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  final UserModel? _currentUser;
  RealtimeChannel? _realtimeChannel;

  NotificationNotifier(this._repository, this._currentUser) : super(const AsyncValue.loading()) {
    getNotifications();
    _subscribeToRealtime();
  }

  /// Subscribe to Supabase Realtime to get push notifications from OTHER users
  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;
    final currentUserId = _currentUser?.id;
    
    _realtimeChannel = supabase
        .channel('notifications_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id']?.toString();
            
            // Only show push notification if it's from ANOTHER user
            if (senderId != null && senderId != currentUserId) {
              final title = newRecord['title'] ?? 'New Notification';
              final message = newRecord['message'] ?? '';
              
              // Show local push notification on this phone
              _showPushNotification(title, message);
              
              // Refresh the in-app notification list
              getNotifications();
            }
          },
        )
        .subscribe();
  }

  Future<void> _showPushNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (enabled) {
      LocalNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
      );
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
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
    try {
      await _repository.addNotification(notification);
      // Realtime will auto-refresh for other users
      // But we still refresh our own list (to not show self-notifications)
      await getNotifications();
    } catch (e) {
      print('Failed to add notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      state.whenData((notifications) {
        // Remove the notification from the state so it "vanishes" immediately
        state = AsyncValue.data(
          notifications.where((n) => n.id != id).toList()
        );
      });
    } catch (e) {
      print('Failed to mark notification $id as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      // After marking all as read, we set the state to an empty list
      // This makes them "vanish" from the current user's screen
      state = const AsyncValue.data([]);
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  /// Create and broadcast a notification (saved to Supabase, Realtime pushes to others)
  void pushNotificationLocally(String title, String message, {
    String? relatedEntityId, 
    String? relatedEntityType, 
    bool deduplicate = false,
    bool showOnDevice = false,
  }) async {
    if (deduplicate) {
      bool exists = false;
      state.whenData((notifications) {
        exists = notifications.any((n) => n.title == title && n.relatedEntityId == relatedEntityId);
      });
      if (exists) return;
    }
    
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: message,
      date: DateTime.now(),
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      senderId: _currentUser?.id,
    );

    // Insert into Supabase — Realtime will push to OTHER users' phones
    await addNotification(notification);
  }
}

final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final user = ref.watch(currentUserProvider);
  return NotificationNotifier(ref.watch(notificationRepositoryProvider), user);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

List<String> getUpperRanks(Role role) {
  return Role.values.map((e) => e.name).toList();
}
