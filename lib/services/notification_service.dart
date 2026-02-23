import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_notifications');
      
      if (localData != null) {
         final List<dynamic> decoded = jsonDecode(localData);
         return decoded.map((json) => NotificationModel.fromJson(json)).toList();
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .order('date', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching notifications (fallback to local if available): $e');
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_notifications');
      if (localData != null) {
         final List<dynamic> decoded = jsonDecode(localData);
         return decoded.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    }
  }

  Future<void> _saveLocally(List<NotificationModel> notifications) async {
     try {
       final prefs = await SharedPreferences.getInstance();
       final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
       await prefs.setString('local_notifications', encoded);
     } catch(e) {
       print('Error saving local notifications: $e');
     }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      final data = notification.toJson();
      if (data['id'] == null || data['id'].isEmpty) {
        data['id'] = _uuid.v4();
      }

      // Add to local cache first
      final current = await getNotifications();
      current.insert(0, notification);
      await _saveLocally(current);

      await _supabase.from('notifications').insert(data);
    } catch (e) {
      print('Error adding notification to remote: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final current = await getNotifications();
      final updated = current.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
      }).toList();
      await _saveLocally(updated);

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
      final current = await getNotifications();
      final updated = current.map((n) => n.copyWith(isRead: true)).toList();
      await _saveLocally(updated);

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false); // Updates all unread to read
    } catch (e) {
      print('Error marking all notifications read: $e');
    }
  }
}
