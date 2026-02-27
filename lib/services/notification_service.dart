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

      // Fetch notifications. RLS should handle user isolation if configured.
      // If RLS is not fully isolating, we might need a .eq('user_id', userId) filter here.
      var query = _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      
      final response = await query.timeout(const Duration(seconds: 15));
      
      final List<dynamic> data = response as List<dynamic>;
      
      final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      // Filter out self-notifications (where sender_id == current user)
      final filtered = notifications.where((n) {
        if (n.senderId != null && n.senderId == userId) return false;
        return true;
      }).toList();
      
      // Cache locally
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
      
      // Ensure sender_id is set
      data['sender_id'] = _currentUserId;

      // If no explicit recipient (user_id) is set, it stays NULL (effectively a broadcast)
      // Note: If RLS is strict, you may need a policy to allow viewing NULL user_id records.

      await _supabase.from('notifications').insert(data);
      
    } catch (e) {
      print('[NotificationService] INSERT ERROR: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      // In a multi-user shared notification system, we should ideally mark as read
      // in a junction table. For now, and to satisfy the "vanish" requirement,
      // we handle it locally in the Notifier. 
      // We only update the DB if the notification is private to this user.
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', _currentUserId ?? ''); // Only if it's mine
    } catch (e) {
      print('[NotificationService] Error marking read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Similarly, only mark my own as read to avoid affecting others.
      final userId = _currentUserId;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('[NotificationService] Error marking all read: $e');
    }
  }
}
