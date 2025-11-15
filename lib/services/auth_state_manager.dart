// lib/services/auth_state_manager.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateManager extends ChangeNotifier {
  User? _user;
  String? _error;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters remain the same
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthStateManager() {
    _initializeAuthState();
  }

  void _initializeAuthState() async {
    // Listen to auth state changes
    FirebaseAuthService.authStateChanges.listen((user) async {
      print('Auth state changed: ${user?.uid}'); // Debug log
      
      final wasAuthenticated = _user != null;
      final willBeAuthenticated = user != null;
      
      _user = user;
      _error = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", user != null);

      if (!_isInitialized) {
        _isInitialized = true;
      }
      
      // Clear loading state when auth state changes
      if (_isLoading) {
        _isLoading = false;
      }

      // Log the authentication transition
      if (!wasAuthenticated && willBeAuthenticated) {
        print('User successfully authenticated: ${user!.uid}');
      } else if (wasAuthenticated && !willBeAuthenticated) {
        print('User signed out');
      }

      notifyListeners();
    });
  }

  // --- Auth Actions with Enhanced Error Handling and State Management ---

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      print('Starting email sign-in for: $email');
      
      final result = await FirebaseAuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        print('Email sign-in successful: ${result.user?.uid}');
        // Don't manually set _user here - let the stream handle it
        // Keep loading true until stream updates
        return true;
      } else {
        print('Email sign-in failed: ${result.error}');
        _setLoading(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Email sign-in exception: $e');
      _setLoading(false);
      _error = 'Unexpected error during sign-in: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      print('Starting sign-up for: $email');
      
      final result = await FirebaseAuthService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (result.isSuccess) {
        print('Sign-up successful: ${result.user?.uid}');
        // Don't manually set _user here - let the stream handle it
        // Keep loading true until stream updates
        return true;
      } else {
        print('Sign-up failed: ${result.error}');
        _setLoading(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Sign-up exception: $e');
      _setLoading(false);
      _error = 'Unexpected error during sign-up: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _clearError();
    _setLoading(true);

    try {
      print('Sending password reset email to: $email');
      
      final result = await FirebaseAuthService.sendPasswordResetEmail(email);

      _setLoading(false);

      if (result.isSuccess) {
        print('Password reset email sent successfully');
        _error = null;
        notifyListeners();
        return true;
      } else {
        print('Password reset failed: ${result.error}');
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Password reset exception: $e');
      _setLoading(false);
      _error = 'Failed to send reset email: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      print('Starting Google sign-in');
      
      final result = await FirebaseAuthService.signInWithGoogle();
      
      if (result.isSuccess) {
        print('Google sign-in successful: ${result.user?.uid}');
        // Don't manually set _user here - let the stream handle it
        // Keep loading true until stream updates
        return true;
      } else {
        print('Google sign-in failed: ${result.error}');
        _setLoading(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Google sign-in exception: $e');
      _setLoading(false);
      _error = 'Unexpected error during Google sign-in: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    print('Starting sign-out process');
    _setLoading(true);
    _clearError();
    
    try {
      await FirebaseAuthService.signOut();
      print('Sign-out completed');
      // The stream listener will handle setting _user to null and clearing loading
    } catch (e) {
      print('Sign-out error: $e');
      _setLoading(false);
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  // --- Enhanced Helper Methods ---
  
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      print('Loading state changed to: $value');
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      print('Error cleared');
    }
  }

  // --- Public Methods for Manual State Management ---
  
  /// Force clear loading state (use with caution)
  void clearLoadingState() {
    if (_isLoading) {
      _setLoading(false);
      notifyListeners();
      print('Loading state manually cleared');
    }
  }

  /// Force refresh auth state
  Future<void> refreshAuthState() async {
    try {
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        _user = FirebaseAuthService.currentUser;
        notifyListeners();
        print('Auth state manually refreshed');
      }
    } catch (e) {
      print('Error refreshing auth state: $e');
    }
  }

  /// Get current authentication status as a string for debugging
  String get debugStatus {
    return 'AuthStateManager Status:\n'
           '- isInitialized: $_isInitialized\n'
           '- isAuthenticated: $isAuthenticated\n'
           '- isLoading: $_isLoading\n'
           '- user: ${_user?.uid ?? 'null'}\n'
           '- error: ${_error ?? 'null'}';
  }
}