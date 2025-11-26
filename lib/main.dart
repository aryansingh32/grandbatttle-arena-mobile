import 'package:flutter/material.dart';
// import 'package:grand_battle_arena/components/tournamentdetails.dart';
import 'package:grand_battle_arena/pages/main_component.dart';
import 'package:grand_battle_arena/pages/sign_in_page.dart';
import 'package:grand_battle_arena/pages/sign_up_page.dart';

import 'package:grand_battle_arena/services/notification_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/theme/theme_manager.dart';
import 'package:grand_battle_arena/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // FIXED: Import for background handler
import 'package:grand_battle_arena/firebase_messaging_background.dart'; // FIXED: Import background handler
import 'package:grand_battle_arena/services/auth_wrapper.dart';
import 'pages/profile.dart';
// import 'pages/sign_in_page.dart';
// import 'pages/sign_up_page.dart';
import 'pages/welcome_page.dart';
import 'services/auth_state_manager.dart';
import 'services/booking_refresh_notifier.dart';
import 'services/filter_provider.dart'; // CHANGE: expose shared filters for quick chips.
import 'services/notification_service.dart' show NavigatorKey; // CHANGE: use app-wide navigator key.


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with manual configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDrLPprcDSE83ay79AmDx1NTACz0Be1fTw',
      appId: '1:621118586664:android:b1c9a1adafde17f362da1d',
      messagingSenderId: '621118586664',
      projectId: 'grand-battle-arena',
      storageBucket: 'grand-battle-arena.firebasestorage.app',
      databaseURL:
          'https://grand-battle-arena-default-rtdb.asia-southeast1.firebasedatabase.app',
    ),
  );

  // CRITICAL FIX: Register background message handler BEFORE initializing notification service
  // This MUST be a top-level function and registered before runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('✅ Background message handler registered');

  // Initialize notification service (includes FCM token registration)
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateManager()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => BookingRefreshNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        ThemeData theme;
        switch (themeManager.currentTheme) {
          case AppThemeType.light:
            theme = AppTheme.lightTheme;
            break;
          case AppThemeType.futuristic:
            theme = AppTheme.futuristicTheme;
            break;
          case AppThemeType.dynamic:
            theme = AppTheme.getDynamicTheme(themeManager.dynamicBackgroundColor);
            break;
          case AppThemeType.dark:
          default:
            theme = AppTheme.darkTheme;
            break;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Esports App",
          navigatorKey: NavigatorKey.key,
          home: const AuthWrapper(signedInScreen: MainContainer(), signedOutScreen: WelcomePage()),
          routes: {
            '/main': (context) => MainContainer(),
            '/profile': (context) => Profile(),
            '/tournament': (context) => MainContainer(currentIndex: 1),
            '/wallet': (context) => MainContainer(currentIndex: 2),
          },
          theme: theme,
        );
      },
    );
  }
}

