import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

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
    developer.log('🏗️ AuthWrapper: build() called at ${DateTime.now()}', name: 'AuthFlow');
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final timestamp = DateTime.now().toIso8601String();
        
        developer.log(
          '🔄 AuthWrapper StreamBuilder at $timestamp\n'
          '   connectionState: ${snapshot.connectionState}\n'
          '   hasData: ${snapshot.hasData}\n'
          '   hasError: ${snapshot.hasError}\n'
          '   user: ${snapshot.data?.uid ?? "null"}\n'
          '   email: ${snapshot.data?.email ?? "none"}',
          name: 'AuthFlow',
        );

        // While connecting, show loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          developer.log('⏳ AuthWrapper: Showing loading screen', name: 'AuthFlow');
          return Scaffold(
            backgroundColor: Color(0xFF090B0E), // Appcolor.primary
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFFC107), // Appcolor.secondary
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          developer.log(
            '✅ AuthWrapper: User authenticated, showing signedInScreen\n'
            '   User: ${snapshot.data!.uid}\n'
            '   Email: ${snapshot.data!.email}',
            name: 'AuthFlow'
          );
          return signedInScreen;
        } else {
          developer.log('🚪 AuthWrapper: No user, showing signedOutScreen', name: 'AuthFlow');
          return signedOutScreen;
        }
      },
    );
  }
}