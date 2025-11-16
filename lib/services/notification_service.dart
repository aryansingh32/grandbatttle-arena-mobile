// lib/services/notification_service.dart
// FIXED VERSION - Resolves FCM token handling and async issues

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
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final StreamController<NotificationModel> _notificationStreamController = 
      StreamController<NotificationModel>.broadcast();
  
  // STEP 3.1: Store FCM token properly
  static String? _fcmToken;
  static bool _isInitialized = false;

  // Stream for listening to notifications
  static Stream<NotificationModel> get notificationStream => 
      _notificationStreamController.stream;

  /// STEP 3.2: Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Notification service already initialized');
      return;
    }

    try {
      print('🔵 Initializing notification service...');

      // Request permissions first
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permissions');
        
        // STEP 3.3: Get FCM token synchronously
        await _getFcmToken();
        
        // STEP 3.4: Send token to server
        await sendTokenToServer();
        
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Set up message handlers
        _setupMessageHandlers();

        // Handle app launch from notification
        await _handleInitialMessage();

        _isInitialized = true;
        print('✅ Notification service initialized successfully');
      } else {
        print('❌ User declined notification permissions');
      }
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      rethrow;
    }
  }

  /// STEP 3.5: Get FCM token with proper error handling
  static Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
      } else {
        print('⚠️ FCM Token is null');
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed');
        _fcmToken = newToken;
        sendTokenToServer();
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      rethrow;
    }
  }

  /// STEP 3.6: Send token to server with proper async handling
  static Future<void> sendTokenToServer() async {
    try {
      // Wait for token if not yet available
      if (_fcmToken == null) {
        print('⏳ Waiting for FCM token...');
        await _getFcmToken();
      }

      if (_fcmToken == null) {
        print('⚠️ Cannot send token: FCM token is null');
        return;
      }

      print('🚀 Sending token to server...');
      await ApiService.updateDeviceToken(_fcmToken!);
      print('✅ Token sent to server successfully');
    } catch (e) {
      print('❌ Error sending token to server: $e');
      // Don't throw - token will be retried on next app launch
    }
  }

  /// STEP 3.7: Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
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
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
    print('✅ Local notifications initialized');
  }

  /// Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Tournament channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'tournament_credentials',
        'Tournament Notifications',
        description: 'Game IDs and passwords for tournaments',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    );

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    );

    // Wallet channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'wallet_notifications',
        'Wallet Notifications',
        description: 'Wallet and transaction updates',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    );

    print('✅ Notification channels created');
  }

  /// STEP 3.8: Set up message handlers
  static void _setupMessageHandlers() {
    // Background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    print('✅ Message handlers configured');
  }

  /// Handle initial message (app opened from notification)
  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App opened from notification: ${initialMessage.messageId}');
      await Future.delayed(const Duration(seconds: 2));
      _handleNotificationTap(initialMessage);
    }
  }

  /// STEP 3.9: Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('🔥 Foreground message: ${message.messageId}');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    
    final notification = NotificationModel.fromRemoteMessage(
      message.data, 
      message.notification?.title, 
      message.notification?.body
    );
    
    _showLocalNotification(message);
    _notificationStreamController.add(notification);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    String channelId = _getChannelIdForNotification(message.data['type'] ?? 'general');
    
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      _getChannelNameForId(channelId),
      channelDescription: _getChannelDescriptionForId(channelId),
      importance: _getImportanceForType(message.data['type'] ?? 'general'),
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50),
      playSound: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
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

  /// Get channel ID for notification type
  static String _getChannelIdForNotification(String type) {
    switch (type) {
      case 'tournament_credentials':
      case 'tournament_reminder':
      case 'tournament_result':
      case 'tournament_update':
        return 'tournament_credentials';
      case 'wallet_transaction':
      case 'reward_distribution':
        return 'wallet_notifications';
      default:
        return 'general_notifications';
    }
  }

  static String _getChannelNameForId(String channelId) {
    switch (channelId) {
      case 'tournament_credentials':
        return 'Tournament Notifications';
      case 'wallet_notifications':
        return 'Wallet Notifications';
      default:
        return 'General Notifications';
    }
  }

  static String _getChannelDescriptionForId(String channelId) {
    switch (channelId) {
      case 'tournament_credentials':
        return 'Tournament updates, credentials, and results';
      case 'wallet_notifications':
        return 'Wallet transactions and rewards';
      default:
        return 'General app notifications';
    }
  }

  static Importance _getImportanceForType(String type) {
    switch (type) {
      case 'tournament_credentials':
      case 'wallet_transaction':
      case 'reward_distribution':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  /// STEP 3.10: Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.messageId}');
    
    final notification = NotificationModel.fromRemoteMessage(
      message.data,
      message.notification?.title,
      message.notification?.body
    );
    
    _notificationStreamController.add(notification);
    
    final type = message.data['type'] ?? 'general';
    
    switch (type) {
      case 'tournament_credentials':
        _handleTournamentCredentials(message.data);
        break;
      case 'tournament_reminder':
        _handleTournamentReminder(message.data);
        break;
      case 'tournament_result':
      case 'tournament_update':
        _handleTournamentUpdate(message.data);
        break;
      case 'wallet_transaction':
      case 'reward_distribution':
        _handleWalletNotification(message.data);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        final message = RemoteMessage(
          messageId: 'local_notification',
          data: Map<String, String>.from(data),
        );
        _handleNotificationTap(message);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Navigation handlers
  static void _handleTournamentCredentials(Map<String, dynamic> data) {
    final gameId = data['gameId'] ?? '';
    final gamePassword = data['gamePassword'] ?? '';
    final tournamentName = data['tournamentName'] ?? 'Tournament';
    final tournamentId = data['tournamentId'] ?? '';
    
    if (gameId.isNotEmpty && gamePassword.isNotEmpty) {
      _showCredentialsDialog(tournamentName, gameId, gamePassword);
    } else {
      _navigateToTournament(tournamentId);
    }
  }

  static void _handleTournamentReminder(Map<String, dynamic> data) {
    final tournamentId = data['tournamentId'] ?? '';
    _navigateToTournament(tournamentId);
  }

  static void _handleTournamentUpdate(Map<String, dynamic> data) {
    final tournamentId = data['tournamentId'] ?? '';
    _navigateToTournament(tournamentId);
  }

  static void _handleWalletNotification(Map<String, dynamic> data) {
    _navigateToWallet();
  }

  static void _navigateToTournament(String tournamentId) {
    final context = NavigatorKey.currentContext;
    if (context != null && tournamentId.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/tournament');
    }
  }

  static void _navigateToWallet() {
    final context = NavigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushReplacementNamed('/wallet');
    }
  }

  static void _showCredentialsDialog(String tournamentName, String gameId, String gamePassword) {
    final context = NavigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Appcolor.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Appcolor.secondary.withOpacity(0.3), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.sports_esports, color: Appcolor.secondary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tournament Credentials',
                  style: TextStyle(
                    color: Appcolor.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Appcolor.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Appcolor.secondary.withOpacity(0.3)),
                ),
                child: Text(
                  tournamentName,
                  style: TextStyle(
                    color: Appcolor.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
              onPressed: () {
                _copyBothCredentials(gameId, gamePassword, context);
                Navigator.of(context).pop();
              },
              child: Text(
                'Copy All',
                style: TextStyle(color: Appcolor.secondary, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Appcolor.white)),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildCredentialRow(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Appcolor.grey, fontSize: 12)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _copyToClipboard(value, label.replaceAll(':', ''), context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.copy, size: 18, color: Appcolor.secondary),
              ],
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
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$type copied!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Appcolor.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _copyBothCredentials(String gameId, String gamePassword, BuildContext context) {
    final credentials = 'Game ID: $gameId\nPassword: $gamePassword';
    Clipboard.setData(ClipboardData(text: credentials));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('All credentials copied!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Appcolor.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // API Integration
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

  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      return await ApiService.getNotificationStats();
    } catch (e) {
      print('Error fetching notification stats: $e');
      return {};
    }
  }

  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error checking notification settings: $e');
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _getFcmToken();
        await sendTokenToServer();
        return true;
      }
      return false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  static void dispose() {
    _notificationStreamController.close();
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Background message: ${message.messageId}');
}

// Navigator key for accessing context
class NavigatorKey {
  static final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();
  
  static GlobalKey<NavigatorState> get key => _key;
  static BuildContext? get currentContext => _key.currentContext;
}