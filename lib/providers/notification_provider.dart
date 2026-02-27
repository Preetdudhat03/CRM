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
  Set<String> _localReadIds = {};

  NotificationNotifier(this._repository, this._currentUser) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _loadReadIds();
    await getNotifications();
    _subscribeToRealtime();
  }

  Future<void> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'read_notifications_${_currentUser?.id ?? 'guest'}';
      _localReadIds = Set.from(prefs.getStringList(key) ?? []);
    } catch (e) {
      print('Error loading read IDs: $e');
    }
  }

  Future<void> _saveReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'read_notifications_${_currentUser?.id ?? 'guest'}';
      await prefs.setStringList(key, _localReadIds.toList());
    } catch (e) {
      print('Error saving read IDs: $e');
    }
  }

  /// Subscribe to Supabase Realtime to get push notifications
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
            final recipientId = newRecord['user_id']?.toString(); // Targeted recipient
            
            // Show push notification if:
            // 1. It's targeted at THIS user OR it's a broadcast (recipientId is null)
            // 2. AND it's not from THIS user themselves
            bool isForMe = recipientId == null || recipientId == currentUserId;
            bool isNotFromMe = senderId == null || senderId != currentUserId;

            if (isForMe && isNotFromMe) {
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
      // Don't show loading on every refresh if we already have data
      if (state.value == null) {
        state = const AsyncValue.loading();
      }
      
      final notifications = await _repository.getNotifications();
      
      // Filter out notifications that have been read LOCALLY on this device
      // This is what makes them "vanish" for this user.
      final unreadOnly = notifications.where((n) => !_localReadIds.contains(n.id)).toList();
      
      state = AsyncValue.data(unreadOnly);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      await _repository.addNotification(notification);
      // Refresh list to see any new targeted notifications
      await getNotifications();
    } catch (e) {
      print('Failed to add notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      _localReadIds.add(id);
      await _saveReadIds();
      
      // UI Update: Remove from list immediately so they "vanish"
      state.whenData((notifications) {
        state = AsyncValue.data(notifications.where((n) => n.id != id).toList());
      });
      
      // Optionally update DB if it's a private notification
      // await _repository.markAsRead(id); 
    } catch (e) {
      print('Failed to mark notification $id as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      state.whenData((notifications) {
        for (var n in notifications) {
          _localReadIds.add(n.id);
        }
      });
      await _saveReadIds();
      
      // UI Update: Clear everything so they "vanish"
      state = const AsyncValue.data([]);
      
      // await _repository.markAllAsRead();
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
    data: (notifications) => notifications.length,
    orElse: () => 0,
  );
});

List<String> getUpperRanks(Role role) {
  return Role.values.map((e) => e.name).toList();
}
