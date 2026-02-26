import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/role_model.dart';
import '../services/local_notification_service.dart';
import '../services/push_notification_service.dart';
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

  NotificationNotifier(this._repository, this._currentUser) : super(const AsyncValue.loading()) {
    getNotifications();
  }

  Future<void> getNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _repository.getNotifications();
      
      final filtered = notifications.where((n) {
        if (n.targetRoles == null || n.targetRoles!.isEmpty) return true;
        if (_currentUser == null) return false;
        return n.targetRoles!.contains(_currentUser!.role.name);
      }).toList();

      state = AsyncValue.data(filtered);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    // Optimistically update local state so the feeds work real-time even if Supabase isn't synced yet
    bool shouldShow = true;
    if (notification.targetRoles != null && notification.targetRoles!.isNotEmpty) {
      if (_currentUser == null || !notification.targetRoles!.contains(_currentUser!.role.name)) {
        shouldShow = false;
      }
    }

    if (shouldShow) {
      if (state.hasValue) {
        state.whenData((notifications) {
          state = AsyncValue.data([notification, ...notifications]);
        });
      } else {
        state = AsyncValue.data([notification]);
      }
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

  void pushNotificationLocally(String title, String message, {String? relatedEntityId, String? relatedEntityType, bool deduplicate = false, List<String>? targetRoles, bool showOnDevice = true}) async {
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
      targetRoles: targetRoles,
    );

    if (!showOnDevice) {
      PushNotificationService.ignoreNotificationId(notification.id);
    }

    await addNotification(notification);
    
    // Check if meant for this user before pushing to device
    bool shouldShowDevice = true;
    if (targetRoles != null && targetRoles!.isNotEmpty) {
      if (_currentUser == null || !targetRoles.contains(_currentUser!.role.name)) {
        shouldShowDevice = false;
      }
    }

    if (!shouldShowDevice || !showOnDevice) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (enabled) {
      // Trigger actual device push notification
      LocalNotificationService.showNotification(
         id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
         title: title,
         body: message,
      );
    }
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
