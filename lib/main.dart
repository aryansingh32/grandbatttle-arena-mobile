import 'package:flutter/material.dart';
// import 'package:grand_battle_arena/components/tournamentdetails.dart';
import 'package:grand_battle_arena/pages/main_component.dart';
import 'package:grand_battle_arena/pages/sign_in_page.dart';

import 'package:grand_battle_arena/services/notification_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grand_battle_arena/services/auth_wrapper.dart';
import 'pages/profile.dart';
// import 'pages/sign_in_page.dart';
// import 'pages/sign_up_page.dart';
// import 'pages/welcome_page.dart';
import 'services/auth_state_manager.dart';


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

  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthStateManager(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // REMOVE the Consumer wrapping MaterialApp
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Esports App",
      // USE the home property and point it to your new wrapper
      home: const AuthWrapper(),
      // Your routes are still needed for in-app navigation
      routes: {
        '/main': (context) => MainContainer(),
        '/profile': (context) => Profile(),
        '/tournament': (context) => MainContainer(currentIndex: 1),
        '/wallet': (context) => MainContainer(currentIndex: 2),
        // '/tournamentdetail': (context) => TournamentDetailsPage(),
        // '/welcome': (context) => const WelcomePage(),
        // '/signin': (context) => const SignInPage(),
        // '/signup': (context) => const SignUpPage(),
      },
      theme: ThemeData(
        fontFamily: 'Rubik',
        scaffoldBackgroundColor: Appcolor.primary,
        appBarTheme: AppBarTheme(
          color: Appcolor.primary,
          iconTheme: IconThemeData(color: Appcolor.white),
        ),
      ),
    );
  }
}

