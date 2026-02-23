import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final NotificationService _service;

  NotificationRepository(this._service);

  Future<List<NotificationModel>> getNotifications() async {
    return _service.getNotifications();
  }

  Future<void> addNotification(NotificationModel notification) async {
    return _service.addNotification(notification);
  }

  Future<void> markAsRead(String id) async {
    return _service.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    return _service.markAllAsRead();
  }
}
