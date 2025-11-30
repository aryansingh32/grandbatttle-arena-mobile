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
import 'package:grand_battle_arena/services/firebase_auth_service.dart'; // FIXED: Import for ID token
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/utils/toast_utils.dart';

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
  /// CRITICAL: Gets Firebase ID token for authentication
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

      // CRITICAL FIX: Get Firebase ID token for authentication
      // Import FirebaseAuthService to get the ID token
      final firebaseIdToken = await _getFirebaseIdToken();
      if (firebaseIdToken == null) {
        print('⚠️ Firebase ID token not available, skipping token registration');
        print('   User may not be authenticated yet');
        return;
      }

      print('🚀 Sending FCM token to server...');
      print('   FCM Token: ${_fcmToken!.substring(0, 20)}...');
      await ApiService.updateDeviceToken(_fcmToken!);
      print('✅ Token sent to server successfully');
    } catch (e) {
      print('❌ Error sending token to server: $e');
      // Don't throw - token will be retried on next app launch
    }
  }

  /// Get Firebase ID token for API authentication
  /// FIXED: Now uses FirebaseAuthService to get ID token
  static Future<String?> _getFirebaseIdToken() async {
    try {
      // Use FirebaseAuthService to get the ID token
      final token = await FirebaseAuthService.getIdToken();
      if (token != null) {
        print('✅ Firebase ID token obtained for device token registration');
      } else {
        print('⚠️ Firebase ID token is null - user may not be authenticated');
      }
      return token;
    } catch (e) {
      print('❌ Error getting Firebase ID token: $e');
      return null;
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
      onDidReceiveBackgroundNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
    
    // Request permissions for Android 13+ explicitly
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    print('✅ Local notifications initialized');
  }

  /// Create Android notification channels
  /// CRITICAL: Channel ID must match backend - "tournament_channel_v2"
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // CRITICAL FIX: Main tournament channel - MUST match backend channel ID
    // Backend uses "tournament_channel" for all tournament notifications
    // We use v2 to ensure high importance for existing users
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'tournament_channel_v2', // FIXED: Changed to v2 to force update settings
        'Tournament Notifications',
        description: 'Notifications for tournaments, wallet updates, and more',
        importance: Importance.max, // FIXED: Max importance for heads-up
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // General channel (fallback)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // Wallet channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'wallet_notifications',
        'Wallet Notifications',
        description: 'Wallet and transaction updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    print('✅ Notification channels created (tournament_channel_v2, general_notifications, wallet_notifications)');
  }

  /// STEP 3.8: Set up message handlers
  /// NOTE: Background handler is registered in main.dart, not here
  static void _setupMessageHandlers() {
    // Foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    print('✅ Message handlers configured (foreground and background tap)');
    print('   Note: Background handler registered in main.dart');
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
  /// FIXED: Added showWhen and showBadge as per documentation
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // FIXED: Handle data-only messages by falling back to data fields
    String? title = message.notification?.title;
    String? body = message.notification?.body;

    if (title == null && message.data.isNotEmpty) {
       title = message.data['title'] ?? 'New Notification';
       body = message.data['body'] ?? message.data['message'] ?? '';
    }

    if (title == null) return;

    String channelId = _getChannelIdForNotification(message.data['type'] ?? 'general');
    final String type = message.data['type'] ?? 'general';
    List<AndroidNotificationAction> actions = [];
    if (type == 'tournament_credentials') {
      actions = const [
        AndroidNotificationAction(
          'copy_id',
          'Copy ID',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'copy_pass',
          'Copy Password',
          showsUserInterface: true,
        ),
      ];
    }
    
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      _getChannelNameForId(channelId),
      channelDescription: _getChannelDescriptionForId(channelId),
      importance: _getImportanceForType(message.data['type'] ?? 'general'),
      priority: Priority.high,
      showWhen: true, // FIXED: Added as per documentation
      playSound: true,
      enableVibration: true, // FIXED: Added as per documentation
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50),
      actions: actions,
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
      title,
      body,
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  /// Get channel ID for notification type
  /// CRITICAL: Use "tournament_channel" to match backend
  static String _getChannelIdForNotification(String type) {
    switch (type) {
      case 'tournament_credentials':
      case 'tournament_reminder':
      case 'tournament_result':
      case 'tournament_update':
      case 'tournament_created':
      case 'tournament_booking_reminder':
      case 'tournament_rules':
      case 'TOURNAMENT': // Backend may send uppercase
        return 'tournament_channel_v2'; // FIXED: Changed to match backend v2
      case 'wallet_transaction':
      case 'reward_distribution':
      case 'WALLET': // Backend may send uppercase
        return 'wallet_notifications';
      case 'event_notification':
      case 'custom_notification':
        return 'tournament_channel_v2'; // Use high-priority channel for importance
      default:
        return 'tournament_channel_v2'; // FIXED: Default to v2 which is actually created
    }
  }

  static String _getChannelNameForId(String channelId) {
    switch (channelId) {
      case 'tournament_channel_v2': // FIXED: Updated to match new channel ID
      case 'tournament_channel': // Keep for backward compatibility
      case 'tournament_credentials': // Keep for backward compatibility
        return 'Tournament Notifications';
      case 'wallet_notifications':
        return 'Wallet Notifications';
      default:
        return 'Tournament Notifications'; // Default to tournament channel
    }
  }

  static String _getChannelDescriptionForId(String channelId) {
    switch (channelId) {
      case 'tournament_channel_v2': // FIXED: Updated to match new channel ID
      case 'tournament_channel': // Keep for backward compatibility
      case 'tournament_credentials': // Keep for backward compatibility
        return 'Notifications for tournaments, wallet updates, and more';
      case 'wallet_notifications':
        return 'Wallet transactions and rewards';
      default:
        return 'Notifications for tournaments, wallet updates, and more';
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
      case 'tournament_created':
      case 'tournament_booking_reminder':
        _handleTournamentReminder(message.data);
        break;
      case 'tournament_result':
      case 'tournament_update':
        _handleTournamentUpdate(message.data);
        break;
      case 'tournament_rules':
        _handleTournamentRules(message.data);
        break;
      case 'wallet_transaction':
      case 'reward_distribution':
        _handleWalletNotification(message.data);
        break;
      case 'event_notification':
        _handleEventNotification(message.data);
        break;
      case 'custom_notification':
        // Custom notifications just navigate to home or show the message
        print('📬 Custom notification received');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      if (response.actionId == 'copy_id') {
        _copyInline(data['gameId'] ?? '', 'Game ID', NavigatorKey.currentContext);
        return;
      }
      if (response.actionId == 'copy_pass') {
        _copyInline(data['gamePassword'] ?? '', 'Password', NavigatorKey.currentContext);
        return;
      }
      final message = RemoteMessage(
        messageId: 'local_notification',
        data: Map<String, String>.from(data),
      );
      _handleNotificationTap(message);
    } catch (e) {
      print('Error parsing notification payload: $e');
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

  static void _handleTournamentRules(Map<String, dynamic> data) {
    final tournamentId = data['tournamentId'] ?? '';
    // You can either navigate to tournament or show rules dialog
    _navigateToTournament(tournamentId);
  }

  static void _handleEventNotification(Map<String, dynamic> data) {
    // Navigate to home or events page
    final context = NavigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
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
    ToastUtils.showPremiumToast(context, '$type copied!');
  }

  static void _copyBothCredentials(String gameId, String gamePassword, BuildContext context) {
    final credentials = 'Game ID: $gameId\nPassword: $gamePassword';
    Clipboard.setData(ClipboardData(text: credentials));
    ToastUtils.showPremiumToast(context, 'All credentials copied!');
  }

  static void _copyInline(String value, String label, BuildContext? context) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    if (context != null) {
      ToastUtils.showPremiumToast(context, '$label copied');
    }
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
        await _localNotifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();

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

// NOTE: Background message handler is now in firebase_messaging_background.dart
// This is registered in main.dart using FirebaseMessaging.onBackgroundMessage

// Navigator key for accessing context
class NavigatorKey {
  static final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();
  
  static GlobalKey<NavigatorState> get key => _key;
  static BuildContext? get currentContext => _key.currentContext;
}