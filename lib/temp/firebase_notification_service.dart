import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grand_battle_arena/models/notification_model.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final StreamController<NotificationModel> _notificationStreamController = 
      StreamController<NotificationModel>.broadcast();

  // Stream for listening to notifications
  static Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;

  static Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get initial message if app was opened from notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification
    _showLocalNotification(message);
    
    // Add to notification stream
    final notification = _createNotificationModel(message);
    _notificationStreamController.add(notification);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'tournament_channel',
        'Tournament Notifications',
        channelDescription: 'Notifications for tournament updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        playSound: true,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: json.encode(message.data),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    
    // Handle different notification types
    final data = message.data;
    final type = data['type'] ?? '';
    
    switch (type) {
      case 'tournament_credentials':
        _handleTournamentCredentials(data);
        break;
      case 'tournament_reminder':
        _handleTournamentReminder(data);
        break;
      case 'tournament_update':
        _handleTournamentUpdate(data);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        final message = RemoteMessage(
          messageId: 'local_notification',
          data: data,
        );
        _handleNotificationTap(message);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  static void _handleTournamentCredentials(Map<String, dynamic> data) {
    final gameId = data['gameId'] ?? '';
    final gamePassword = data['gamePassword'] ?? '';
    final tournamentName = data['tournamentName'] ?? 'Tournament';
    
    // Show dialog with copy options
    _showCredentialsDialog(tournamentName, gameId, gamePassword);
  }

  static void _handleTournamentReminder(Map<String, dynamic> data) {
    final tournamentId = int.tryParse(data['tournamentId'] ?? '0') ?? 0;
    final tournamentName = data['tournamentName'] ?? 'Tournament';
    
    // Navigate to tournament details
    print('Navigate to tournament $tournamentId');
  }

  static void _handleTournamentUpdate(Map<String, dynamic> data) {
    final tournamentId = int.tryParse(data['tournamentId'] ?? '0') ?? 0;
    
    // Navigate to tournament or refresh data
    print('Tournament $tournamentId updated');
  }

  static void _showCredentialsDialog(String tournamentName, String gameId, String gamePassword) {
    // Get the current context (you'll need to manage this based on your app structure)
    final context = NavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Appcolor.primary,
          title: Text(
            'Tournament Credentials',
            style: TextStyle(
              color: Appcolor.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournamentName,
                style: TextStyle(
                  color: Appcolor.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildCredentialRow('Game ID:', gameId, context),
              const SizedBox(height: 12),
              _buildCredentialRow('Password:', gamePassword, context),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Appcolor.white),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildCredentialRow(String label, String value, BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Appcolor.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyToClipboard(value, label.replaceAll(':', ''), context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Appcolor.cardsColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Appcolor.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Appcolor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: Appcolor.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static void _copyToClipboard(String text, String type, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied successfully!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Appcolor.secondary,
      ),
    );
  }

  static NotificationModel _createNotificationModel(RemoteMessage message) {
    return NotificationModel(
      id: message.hashCode,
      firebaseUserUID: '',
      message: message.notification?.body ?? message.data['message'] ?? '',
      sentAt: DateTime.now(),
      type: message.data['type'] ?? 'general',
    )..title = message.notification?.title ?? message.data['title'] ?? ''
     ..data = message.data;
  }

  static Future<List<NotificationModel>> getNotifications() async {
    try {
      return await ApiService.getNotifications();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  static void dispose() {
    _notificationStreamController.close();
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

// Global navigator key for accessing context
class NavigatorKey {
  static final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();
  
  static GlobalKey<NavigatorState> get key => _key;
  static BuildContext? get currentContext => _key.currentContext;
}