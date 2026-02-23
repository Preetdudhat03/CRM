import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .order('date', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      final data = notification.toJson();
      if (data['id'] == null || data['id'].isEmpty) {
        data['id'] = _uuid.v4();
      }
      await _supabase.from('notifications').insert(data);
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false); // Updates all unread to read
    } catch (e) {
      print('Error marking all notifications read: $e');
    }
  }
}
