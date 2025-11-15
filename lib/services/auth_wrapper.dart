import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:grand_battle_arena/pages/main_component.dart';
import 'package:grand_battle_arena/pages/welcome_page.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

// class AuthWrapper extends StatefulWidget {
//   const AuthWrapper({super.key});

//   @override
//   State<AuthWrapper> createState() => _AuthWrapperState();
// }

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateManager>(
      builder: (context, auth, _) {
        print(
            'AuthWrapper build - isInitialized: ${auth.isInitialized}, '
            'isAuthenticated: ${auth.isAuthenticated}, '
            'isLoading: ${auth.isLoading}');

        if (!auth.isInitialized) {
          return const Scaffold(
            backgroundColor: Appcolor.primary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Appcolor.secondary),
                  SizedBox(height: 16),
                  Text(
                    'Initializing...',
                    style: TextStyle(color: Appcolor.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          print('User authenticated - showing MainContainer');
          return const MainContainer();
        } else {
          print('User not authenticated - showing WelcomePage');
          return const WelcomePage();
        }
      },
    );
  }
}

