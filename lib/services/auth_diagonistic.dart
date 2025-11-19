// lib/utils/auth_diagnostics.dart
// Debug utility to diagnose auth and navigation issues

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthDiagnostics {
  /// Print comprehensive auth state information
  static void printAuthState(BuildContext context) {
    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    
    print('═══════════════════════════════════════');
    print('AUTH DIAGNOSTICS');
    print('═══════════════════════════════════════');
    print('AuthStateManager:');
    print('  - isInitialized: ${authManager.isInitialized}');
    print('  - isAuthenticated: ${authManager.isAuthenticated}');
    print('  - isLoading: ${authManager.isLoading}');
    print('  - user: ${authManager.user?.uid ?? "null"}');
    print('  - error: ${authManager.error ?? "none"}');
    print('');
    print('Firebase Auth:');
    print('  - currentUser: ${firebaseUser?.uid ?? "null"}');
    print('  - email: ${firebaseUser?.email ?? "null"}');
    print('  - displayName: ${firebaseUser?.displayName ?? "null"}');
    print('═══════════════════════════════════════');
  }

  /// Widget to display auth state on screen (for debugging)
  static Widget buildDebugOverlay(BuildContext context) {
    return Consumer<AuthStateManager>(
      builder: (context, auth, _) {
        return Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🐛 DEBUG',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Init: ${auth.isInitialized}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  'Auth: ${auth.isAuthenticated}',
                  style: TextStyle(
                    color: auth.isAuthenticated ? Colors.green : Colors.red,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Loading: ${auth.isLoading}',
                  style: TextStyle(
                    color: auth.isLoading ? Colors.orange : Colors.white,
                    fontSize: 10,
                  ),
                ),
                if (auth.user != null)
                  Text(
                    'UID: ${auth.user!.uid.substring(0, 8)}...',
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                  ),
                if (auth.error != null)
                  Text(
                    'Error: ${auth.error!.substring(0, 20)}...',
                    style: const TextStyle(color: Colors.red, fontSize: 10),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Add debug button to clear loading state
  static Widget buildEmergencyResetButton(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 10,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.red,
        onPressed: () {
          final authManager = Provider.of<AuthStateManager>(context, listen: false);
          authManager.clearLoadingState();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading state cleared!'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Icon(Icons.refresh, size: 20),
      ),
    );
  }

  /// Monitor auth state changes in real-time
  static void startAuthMonitoring(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      print('[$timestamp] 🔵 Firebase Auth State Changed: ${user?.uid ?? "null"}');
      
      // Check if AuthStateManager is in sync
      final authManager = Provider.of<AuthStateManager>(context, listen: false);
      final isInSync = (user != null) == authManager.isAuthenticated;
      
      if (!isInSync) {
        print('⚠️ WARNING: AuthStateManager out of sync!');
        print('  Firebase: ${user?.uid ?? "null"}');
        print('  Manager: ${authManager.user?.uid ?? "null"}');
      }
    });
  }

  /// Test navigation manually
  static void forceNavigateToHome(BuildContext context) {
    print('🔧 Force navigating to home...');
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  static void forceNavigateToWelcome(BuildContext context) {
    print('🔧 Force navigating to welcome...');
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  }
}

/// Debug page to test auth functionality
class AuthDebugPage extends StatelessWidget {
  const AuthDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: Colors.black,
      ),
      body: Consumer<AuthStateManager>(
        builder: (context, auth, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Card
              Card(
                color: auth.isAuthenticated ? Colors.green[100] : Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${auth.isAuthenticated ? "AUTHENTICATED" : "NOT AUTHENTICATED"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: auth.isAuthenticated ? Colors.green[900] : Colors.red[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Initialized: ${auth.isInitialized}'),
                      Text('Loading: ${auth.isLoading}'),
                      Text('User: ${auth.user?.uid ?? "null"}'),
                      Text('Error: ${auth.error ?? "none"}'),
                      const SizedBox(height: 8),
                      Text('Firebase User: ${FirebaseAuth.instance.currentUser?.uid ?? "null"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              ElevatedButton(
                onPressed: () => AuthDiagnostics.printAuthState(context),
                child: const Text('Print Auth State to Console'),
              ),
              ElevatedButton(
                onPressed: () {
                  auth.clearLoadingState();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loading state cleared')),
                  );
                },
                child: const Text('Clear Loading State'),
              ),
              ElevatedButton(
                onPressed: () => AuthDiagnostics.forceNavigateToHome(context),
                child: const Text('Force Navigate to Home'),
              ),
              ElevatedButton(
                onPressed: () => AuthDiagnostics.forceNavigateToWelcome(context),
                child: const Text('Force Navigate to Welcome'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}