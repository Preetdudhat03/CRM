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
      // Always try Supabase first — this gets notifications from ALL users
      final response = await _supabase
          .from('notifications')
          .select()
          .order('date', ascending: false)
          .limit(50);
      
      final List<dynamic> data = response as List<dynamic>;
      final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      // Cache to local for offline access
      await _saveLocally(notifications);
      return notifications;
    } catch (e) {
      print('Error fetching notifications from Supabase, falling back to local: $e');
      // Fallback to local cache if Supabase is unreachable
      return _getLocalNotifications();
    }
  }

  Future<List<NotificationModel>> _getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_notifications');
      if (localData != null) {
        final List<dynamic> decoded = jsonDecode(localData);
        return decoded.map((json) => NotificationModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error reading local notifications: $e');
    }
    return [];
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

      // Save to Supabase first — this makes it visible to ALL users
      await _supabase.from('notifications').insert(data);
      
      // Also update local cache
      final current = await _getLocalNotifications();
      current.insert(0, notification);
      await _saveLocally(current);
    } catch (e) {
      print('Error adding notification: $e');
      // Still save locally even if Supabase fails
      final current = await _getLocalNotifications();
      current.insert(0, notification);
      await _saveLocally(current);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);

      // Update local cache too
      final current = await _getLocalNotifications();
      final updated = current.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
      }).toList();
      await _saveLocally(updated);
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false);

      final current = await _getLocalNotifications();
      final updated = current.map((n) => n.copyWith(isRead: true)).toList();
      await _saveLocally(updated);
    } catch (e) {
      print('Error marking all notifications read: $e');
    }
  }
}
