import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  // Fetch notifications for current user
  static Future<List<AppNotification>> fetchNotifications({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      print('📱 Fetching notifications for user: ${user?.id}');
      if (user == null) {
        print('❌ No authenticated user found');
        return [];
      }

      print('🔍 Querying notifications table...');
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      print('📊 Raw response: $response');
      print('📊 Response type: ${response.runtimeType}');
      print('📊 Response length: ${(response as List).length}');

      final notifications = (response as List).map((r) => AppNotification.fromJson(r)).toList();
      print('✅ Parsed ${notifications.length} notifications');
      
      return notifications;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      print('❌ Error type: ${e.runtimeType}');
      return [];
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      print('📱 Getting unread count for user: ${user?.id}');
      if (user == null) {
        print('❌ No authenticated user found for unread count');
        return 0;
      }

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      final count = (response as List).length;
      print('📊 Unread count: $count');
      return count;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read for current user
  static Future<bool> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Create a notification (used by admin or system)
  static Future<bool> createNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📝 Creating notification for user: $userId');
      print('📝 Title: $title, Type: $type');
      
      final response = await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'is_read': false,
      }).select();

      print('📝 Create response: $response');
      final success = response.isNotEmpty;
      print(success ? '✅ Notification created successfully' : '❌ Failed to create notification');
      return success;
    } catch (e) {
      print('❌ Error creating notification: $e');
      return false;
    }
  }

  // Test method to create a sample notification for current user
  static Future<bool> createTestNotification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for test notification');
        return false;
      }

      return await createNotification(
        userId: user.id,
        type: 'test',
        title: 'Test Notification',
        body: 'This is a test notification created at ${DateTime.now()}',
        data: {'test': true, 'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      print('❌ Error creating test notification: $e');
      return false;
    }
  }

  // Subscribe to real-time notifications
  static RealtimeChannel? subscribeToNotifications({
    required void Function(AppNotification) onNotification,
  }) {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final channel = _supabase
          .channel('notifications:user_id=eq.${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              final notification = AppNotification.fromJson(payload.newRecord);
              onNotification(notification);
            },
          )
          .subscribe();

      return channel;
    } catch (e) {
      print('Error subscribing to notifications: $e');
      return null;
    }
  }

  // Notification types constants
  static const String TYPE_BORROW_APPROVED = 'borrow_approved';
  static const String TYPE_BORROW_REJECTED = 'borrow_rejected';
  static const String TYPE_BORROW_DUE_REMINDER = 'borrow_due_reminder';
  static const String TYPE_BORROW_OVERDUE = 'borrow_overdue';
  static const String TYPE_GENERAL = 'general';
}
