// lib/services/auth_state_manager.dart
// FIXED VERSION - Resolves navigation and state synchronization issues

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateManager extends ChangeNotifier {
  User? _user;
  String? _error;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthStateManager() {
    _initializeAuthState();
  }

  /// STEP 1.1: Initialize auth state listener
  /// This runs once when the app starts and listens to Firebase auth changes
  void _initializeAuthState() async {
    print('🔵 AuthStateManager: Initializing auth state listener');
    
    FirebaseAuthService.authStateChanges.listen((user) async {
      print('🔵 Auth state changed: ${user?.uid ?? "null"}');
      
      final wasAuthenticated = _user != null;
      final willBeAuthenticated = user != null;
      
      _user = user;
      _error = null;

      // STEP 1.2: Persist login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", user != null);

      // STEP 1.3: Mark as initialized after first auth check
      if (!_isInitialized) {
        _isInitialized = true;
        print('✅ AuthStateManager: Initialization complete');
      }
      
      // STEP 1.4: Clear loading ONLY when auth state changes
      if (_isLoading) {
        _isLoading = false;
        print('⏸️ Loading state cleared by auth change');
      }

      // STEP 1.5: Log authentication transitions
      if (!wasAuthenticated && willBeAuthenticated) {
        print('✅ User authenticated: ${user!.uid}');
      } else if (wasAuthenticated && !willBeAuthenticated) {
        print('🚪 User signed out');
      }

      notifyListeners();
    }, onError: (error) {
      // STEP 1.6: Handle stream errors
      print('❌ Auth stream error: $error');
      _error = 'Authentication error: $error';
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- STEP 1.7: Enhanced Auth Actions ---

  /// Sign in with email
  /// FIXED: Proper error handling and state management
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      print('🔐 Starting email sign-in for: $email');
      
      final result = await FirebaseAuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        print('✅ Email sign-in successful');
        // Don't clear loading - let auth stream handle it
        return true;
      } else {
        print('❌ Email sign-in failed: ${result.error}');
        _setLoading(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Email sign-in exception: $e');
      _setLoading(false);
      _error = 'Sign-in failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email
  /// FIXED: Consistent state management
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      print('📝 Starting sign-up for: $email');
      
      final result = await FirebaseAuthService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (result.isSuccess) {
        print('✅ Sign-up successful');
        return true;
      } else {
        print('❌ Sign-up failed: ${result.error}');
        _setLoading(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Sign-up exception: $e');
      _setLoading(false);
      _error = 'Sign-up failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Google sign-in
  /// FIXED: Better error handling
  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      print('🔐 Starting Google sign-in');
      
      final result = await FirebaseAuthService.signInWithGoogle();
      
      if (result.isSuccess) {
        print('✅ Google sign-in successful');
        return true;
      } else {
        print('❌ Google sign-in failed: ${result.error}');
        _setLoading(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Google sign-in exception: $e');
      _setLoading(false);
      _error = 'Google sign-in failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Password reset
  Future<bool> sendPasswordResetEmail(String email) async {
    _clearError();
    _setLoading(true);

    try {
      print('📧 Sending password reset to: $email');
      
      final result = await FirebaseAuthService.sendPasswordResetEmail(email);

      _setLoading(false);

      if (result.isSuccess) {
        print('✅ Password reset email sent');
        notifyListeners();
        return true;
      } else {
        print('❌ Password reset failed: ${result.error}');
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Password reset exception: $e');
      _setLoading(false);
      _error = 'Failed to send reset email: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  /// FIXED: Proper cleanup
  Future<void> signOut() async {
    print('🚪 Starting sign-out');
    _setLoading(true);
    _clearError();
    
    try {
      await FirebaseAuthService.signOut();
      print('✅ Sign-out completed');
      // Auth stream will handle state update
    } catch (e) {
      print('❌ Sign-out error: $e');
      _setLoading(false);
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  // --- STEP 1.8: Helper Methods ---
  
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      print('⏳ Loading state: $value');
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      print('🧹 Error cleared');
    }
  }

  /// Force clear loading (emergency use only)
  void clearLoadingState() {
    if (_isLoading) {
      _setLoading(false);
      notifyListeners();
      print('⚠️ Loading state manually cleared');
    }
  }

  /// Manual auth refresh
  Future<void> refreshAuthState() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        _user = FirebaseAuthService.currentUser;
        notifyListeners();
        print('🔄 Auth state refreshed');
      }
    } catch (e) {
      print('❌ Error refreshing auth: $e');
    }
  }

  /// Debug status
  String get debugStatus {
    return 'AuthStateManager Status:\n'
           '- isInitialized: $_isInitialized\n'
           '- isAuthenticated: $isAuthenticated\n'
           '- isLoading: $_isLoading\n'
           '- user: ${_user?.uid ?? 'null'}\n'
           '- error: ${_error ?? 'null'}';
  }
}