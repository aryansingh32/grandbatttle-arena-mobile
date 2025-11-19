// // lib/services/auth_wrapper.dart
// // OPTIMIZED VERSION - Zero-delay navigation with smooth transitions

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:grand_battle_arena/services/auth_state_manager.dart';
// import 'package:grand_battle_arena/pages/main_component.dart';
// import 'package:grand_battle_arena/pages/welcome_page.dart';
// import 'package:grand_battle_arena/theme/appcolor.dart';

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     print('🔵 AuthWrapper build called');
    
//     return Consumer<AuthStateManager>(
//       builder: (context, auth, _) {
//         print('🔵 AuthWrapper - isInitialized: ${auth.isInitialized}, isAuthenticated: ${auth.isAuthenticated}');
        
//         // Show loading ONLY during initialization
//         if (!auth.isInitialized) {
//           return const Scaffold(
//             backgroundColor: Appcolor.primary,
//             body: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     color: Appcolor.secondary,
//                     strokeWidth: 3,
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Loading...',
//                     style: TextStyle(
//                       color: Appcolor.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         // INSTANT navigation after initialization
//         if (auth.isAuthenticated) {
//           print('✅ AuthWrapper: Showing MainContainer');
//           // Use AnimatedSwitcher for smooth transition
//           return const MainContainer();
//         } else {
//           print('🚪 AuthWrapper: Showing WelcomePage');
//           return const WelcomePage();
//         }
//       },
//     );
//   }
// }

// /// Alternative version with animated transitions (optional)
// class AuthWrapperWithAnimation extends StatelessWidget {
//   const AuthWrapperWithAnimation({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthStateManager>(
//       builder: (context, auth, _) {
//         // Loading state
//         if (!auth.isInitialized) {
//           return const Scaffold(
//             backgroundColor: Appcolor.primary,
//             body: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     color: Appcolor.secondary,
//                     strokeWidth: 3,
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Loading...',
//                     style: TextStyle(
//                       color: Appcolor.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         // Animated navigation between auth states
//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 300),
//           switchInCurve: Curves.easeInOut,
//           switchOutCurve: Curves.easeInOut,
//           transitionBuilder: (Widget child, Animation<double> animation) {
//             return FadeTransition(
//               opacity: animation,
//               child: child,
//             );
//           },
//           child: auth.isAuthenticated
//               ? const MainContainer(key: ValueKey('main'))
//               : const WelcomePage(key: ValueKey('welcome')),
//         );
//       },
//     );
//   }
// }

// ---------- Replace/overwrite existing AuthWrapper file content with this ----------
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  final Widget signedInScreen;
  final Widget signedOutScreen;

  const AuthWrapper({
    super.key,
    required this.signedInScreen,
    required this.signedOutScreen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While connecting, show a small loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Signed in - show the signedInScreen (home)
          return signedInScreen;
        } else {
          // Not signed in - show login
          return signedOutScreen;
        }
      },
    );
  }
}
