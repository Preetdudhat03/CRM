import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's ID from Supabase auth session
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = _currentUserId;

      // Fetch ALL notifications, ordered by newest first
      final response = await _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      
      final List<dynamic> data = response as List<dynamic>;
      
      final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      // Filter out self-notifications (where sender_id == current user)
      final filtered = notifications.where((n) {
        // Don't show notifications created by the current user
        if (n.senderId != null && n.senderId == userId) return false;
        return true;
      }).toList();
      
      
      // Cache to local for offline access
      await _saveLocally(filtered);
      return filtered;
    } catch (e) {
      print('[NotificationService] ERROR fetching: $e');
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
      print('[NotificationService] Error reading local: $e');
    }
    return [];
  }

  Future<void> _saveLocally(List<NotificationModel> notifications) async {
     try {
       final prefs = await SharedPreferences.getInstance();
       final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
       await prefs.setString('local_notifications', encoded);
     } catch(e) {
       print('[NotificationService] Error saving local: $e');
     }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      final data = notification.toJson();
      
      // Set sender_id so we can filter out self-notifications on read
      data['sender_id'] = _currentUserId;


      await _supabase.from('notifications').insert(data);
      
    } catch (e) {
      print('[NotificationService] INSERT ERROR: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      print('[NotificationService] Error marking read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Mark all unread as read
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      print('[NotificationService] Error marking all read: $e');
    }
  }
}
