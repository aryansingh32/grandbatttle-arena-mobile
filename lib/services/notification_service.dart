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
  static Future<String?>? _fcmToken;

  // Stream for listening to notifications
  static Stream<NotificationModel> get notificationStream => _notificationStreamController.stream;

  static Future<void> initialize() async {
    
    



    try {
      // Request permissions
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
         _fcmToken = getDeviceToken();
        print('✅ FCM Token obtained and stored: ${_fcmToken ?? "Failed to get"}');
        await sendTokenToServer();
        // Get and update device token
        // await _updateDeviceToken();
      } else {
        print('❌ User declined notification permissions');
      }

      

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up message handlers
      _setupMessageHandlers();

      // Handle app launch from notification
      await _handleInitialMessage();

    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

 static Future<void> sendTokenToServer() async {
    try {
      // --- CHANGE THIS ---
      // First, check if the process was even started
      
      if (_fcmToken != null) {
        // Now, AWAIT the result. This line will PAUSE until the token is available
        String? token = await _fcmToken;

        if(token==null){
      _fcmToken = getDeviceToken();
       token = _fcmToken as String;
        }

        if (token != null) {
          print('🚀 Token is ready. Sending to server...');
          await ApiService.updateDeviceToken(token);
        } else {
          print('⚠️ Token was fetched but is null. Cannot send to server.');
        }
      } else {
         print('⚠️ Notification permissions not granted, cannot get or send token.');
      }
      // --- END CHANGE ---
    } catch(e) {
      print('❌ Error in sendTokenToServer: $e');
    }
  }


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

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel credentialsChannel = AndroidNotificationChannel(
      'tournament_credentials',
      'Tournament Credentials',
      description: 'Game IDs and passwords for tournaments',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const AndroidNotificationChannel walletChannel = AndroidNotificationChannel(
      'wallet_notifications',
      'Wallet Notifications',
      description: 'Wallet and transaction updates',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(credentialsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(walletChannel);
  }

  static Future<void> _updateDeviceToken() async {
    try {
      String? token = await getDeviceToken();
      if (token != null) {
        await ApiService.updateDeviceToken(token);
        print('✅ Device token updated successfully');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Device token refreshed');
        await ApiService.updateDeviceToken(newToken);
      });

    } catch (e) {
      print('❌ Error updating device token: $e');
    }
  }

  static void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App opened from notification');
      await Future.delayed(const Duration(seconds: 2)); // Wait for app to be ready
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ Error getting device token: $e');
      return null;
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📥 Received foreground message: ${message.messageId}');
    print('📥 Title: ${message.notification?.title}');
    print('📥 Body: ${message.notification?.body}');
    print('📥 Data: ${message.data}');
    
    // Create notification model
    final notification = NotificationModel.fromRemoteMessage(
      message.data, 
      message.notification?.title, 
      message.notification?.body
    );
    
    // Show local notification
    _showLocalNotification(message);
    
    // Add to notification stream
    _notificationStreamController.add(notification);
  }

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
      actions: _getNotificationActions(message.data['type'] ?? 'general'),
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

  static List<AndroidNotificationAction>? _getNotificationActions(String type) {
    switch (type) {
      case 'tournament_credentials':
        return [
          const AndroidNotificationAction(
            'copy_credentials',
            'Copy Credentials',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_copy'),
          ),
        ];
      default:
        return null;
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');
    
    final notification = NotificationModel.fromRemoteMessage(
      message.data,
      message.notification?.title,
      message.notification?.body
    );
    
    // Add to notification stream for UI updates
    _notificationStreamController.add(notification);
    
    // Handle different notification types
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

  static void _handleTournamentCredentials(Map<String, dynamic> data) {
    final gameId = data['gameId'] ?? '';
    final gamePassword = data['gamePassword'] ?? '';
    final tournamentName = data['tournamentName'] ?? 'Tournament';
    final tournamentId = data['tournamentId'] ?? '';
    
    if (gameId.isNotEmpty && gamePassword.isNotEmpty) {
      _showCredentialsDialog(tournamentName, gameId, gamePassword);
    } else {
      // Navigate to tournament details to get credentials
      _navigateToTournament(tournamentId);
    }
  }

  static void _handleTournamentReminder(Map<String, dynamic> data) {
    final tournamentId = data['tournamentId'] ?? '';
    final tournamentName = data['tournamentName'] ?? 'Tournament';
    
    print('Tournament reminder: $tournamentName starts soon');
    _navigateToTournament(tournamentId);
  }

  static void _handleTournamentUpdate(Map<String, dynamic> data) {
    final tournamentId = data['tournamentId'] ?? '';
    
    print('Tournament $tournamentId updated');
    _navigateToTournament(tournamentId);
  }

  static void _handleWalletNotification(Map<String, dynamic> data) {
    print('Wallet notification received');
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Appcolor.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Appcolor.secondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap any field to copy to clipboard',
                        style: TextStyle(
                          color: Appcolor.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Appcolor.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy,
                  size: 18,
                  color: Appcolor.secondary,
                ),
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
            Text('$type copied successfully!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Appcolor.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            const Text('All credentials copied successfully!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Appcolor.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // API Integration Methods
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

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error checking notification settings: $e');
      return false;
    }
  }

  // Request permissions again if denied
  static Future<bool> requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _updateDeviceToken();
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
  print('Handling background message: ${message.messageId}');
  print('Background message data: ${message.data}');
}

// Global navigator key for accessing context
class NavigatorKey {
  static final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();
  
  static GlobalKey<NavigatorState> get key => _key;
  static BuildContext? get currentContext => _key.currentContext;
}