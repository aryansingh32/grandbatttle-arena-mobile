// lib/firebase_messaging_background.dart
// Background message handler for Firebase Cloud Messaging
// This file MUST be a top-level function (not a class method) to work with FCM

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize local notifications plugin for background handler
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler - MUST be top-level function
/// This is called when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background notification received: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');

  // Show local notification for background messages
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'tournament_channel', // CRITICAL: Must match backend channel ID
    'Tournament Notifications',
    channelDescription: 'Notifications for tournaments, wallet updates, and more',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? '',
    notificationDetails,
    payload: message.data.toString(),
  );

  print('✅ Background notification displayed');
}

