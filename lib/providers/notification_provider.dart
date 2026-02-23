import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(notificationServiceProvider));
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.loading()) {
    getNotifications();
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
      state.whenData((notifications) {
        state = AsyncValue.data([notification, ...notifications]);
      });
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

    addNotification(notification);
  }
}

final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref.watch(notificationRepositoryProvider));
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
