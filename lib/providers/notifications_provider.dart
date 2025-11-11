import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/notification_model.dart';

class NotificationsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Load all notifications for a user
  Future<void> loadNotifications(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notificationMaps = await _dbHelper.getUserNotifications(userId);
      _notifications = notificationMaps
          .map((map) => AppNotification.fromMap(map))
          .toList();
      
      // Update unread count
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      
      print('📬 Loaded ${_notifications.length} notifications, $_unreadCount unread');
    } catch (e) {
      print('❌ Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new notification
  Future<bool> createNotification({
    required int userId,
    required int fromUserId,
    required String type,
    required String message,
    int? postId,
    int? commentId,
  }) async {
    try {
      final notification = AppNotification(
        userId: userId,
        fromUserId: fromUserId,
        type: type,
        message: message,
        postId: postId,
        commentId: commentId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final success = await _dbHelper.createNotification(notification.toMap());
      
      if (success) {
        // Add to local list and increment unread count
        _notifications.insert(0, notification);
        _unreadCount++;
        notifyListeners();
        print('✅ Notification created and added to list');
      }
      
      return success;
    } catch (e) {
      print('❌ Error creating notification: $e');
      return false;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _dbHelper.markNotificationAsRead(notificationId);
      
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount--;
          notifyListeners();
          print('✅ Notification marked as read in list');
        }
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(int userId) async {
    try {
      final success = await _dbHelper.markAllNotificationsAsRead(userId);
      
      if (success) {
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
        }
        _unreadCount = 0;
        notifyListeners();
        print('✅ All notifications marked as read');
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final success = await _dbHelper.deleteNotification(notificationId);
      
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final wasUnread = !_notifications[index].isRead;
          _notifications.removeAt(index);
          if (wasUnread) _unreadCount--;
          notifyListeners();
          print('✅ Notification deleted from list');
        }
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(int userId) async {
    try {
      final success = await _dbHelper.deleteAllNotifications(userId);
      
      if (success) {
        _notifications.clear();
        _unreadCount = 0;
        notifyListeners();
        print('✅ All notifications deleted');
      }
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
    }
  }

  /// Get unread notifications count from database
  Future<void> refreshUnreadCount(int userId) async {
    try {
      _unreadCount = await _dbHelper.getUnreadNotificationsCount(userId);
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing unread count: $e');
    }
  }
}
