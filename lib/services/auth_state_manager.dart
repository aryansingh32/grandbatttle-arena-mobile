// lib/services/auth_state_manager.dart
// COMPLETELY FIXED VERSION - Instant navigation with proper state management

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
// import 'package:firebase_auth/firebase_auth.dart';
class AuthStateManager extends ChangeNotifier {
  User? _user;
  String? _error;
  bool _isLoading = false;
  bool _isInitialized = false;
  
  StreamSubscription<User?>? _authSubscription;

  // Getters
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStateManager() {
    _initializeAuthState();
  }

  /// Initialize auth state - FIXED to properly await first auth check
  void _initializeAuthState() {
    print('🔵 AuthStateManager: Starting initialization');
    
    // Cancel any existing subscription
    _authSubscription?.cancel();
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuthService.authStateChanges.listen(
      (user) {
        print('🔵 Auth state changed: ${user?.uid ?? "null"}');
        
        final wasAuthenticated = _user != null;
        final isNowAuthenticated = user != null;
        
        _user = user;
        _error = null;
        _isLoading = false; // CRITICAL: Always clear loading
        
        // Mark as initialized after first check
        if (!_isInitialized) {
          _isInitialized = true;
          print('✅ AuthStateManager: Initialization complete');
        }
        
        // Log state transitions
        if (!wasAuthenticated && isNowAuthenticated) {
          print('✅ User signed in: ${user!.uid}');
          print('✅ Triggering navigation to home...');
        } else if (wasAuthenticated && !isNowAuthenticated) {
          print('🚪 User signed out');
          print('🚪 Triggering navigation to welcome...');
        }

        // CRITICAL: Notify listeners IMMEDIATELY
        notifyListeners();
        
        // Force a second notification after a microtask to ensure UI updates
        Future.microtask(() {
          if (_user == user) { // Only if state hasn't changed
            print('🔄 Second notification triggered for UI sync');
            notifyListeners();
          }
        });
      },
      onError: (error) {
        print('❌ Auth stream error: $error');
        _error = 'Authentication error: $error';
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      },
    );
  }

  // StreamSubscription<User?>? _authSubscription;

/// Call this once when the app starts (or when AuthStateManager is created)
void initAuthListener() {
  // cancel previous if any
  _authSubscription?.cancel();
  _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
    _user = user;
    print('>>> authStateChanges: user=${user?.uid ?? "null"} email=${user?.email}');
    // if you want, you can update flags here
    _isInitialized = true;
    notifyListeners();
  }, onError: (e, st) {
    print('⚠️ authStateChanges error: $e');
  });
}


  /// Email sign-in with immediate state clearing
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoadingAndNotify(true);

    try {
      print('🔐 Starting email sign-in for: $email');
      
      final result = await FirebaseAuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        print('✅ Email sign-in successful - waiting for auth stream...');
        // Don't clear loading yet - auth stream will handle it
        return true;
      } else {
        print('❌ Email sign-in failed: ${result.error}');
        _setLoadingAndNotify(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Email sign-in exception: $e');
      _setLoadingAndNotify(false);
      _error = 'Sign-in failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign up with immediate state clearing
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _clearError();
    _setLoadingAndNotify(true);

    try {
      print('🔐 Starting sign-up for: $email');
      
      final result = await FirebaseAuthService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (result.isSuccess) {
        print('✅ Sign-up successful - waiting for auth stream...');
        return true;
      } else {
        print('❌ Sign-up failed: ${result.error}');
        _setLoadingAndNotify(false);
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Sign-up exception: $e');
      _setLoadingAndNotify(false);
      _error = 'Sign-up failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Google sign-in with AGGRESSIVE state clearing
  Future<bool> signInWithGoogle({Duration timeout = const Duration(seconds: 30)}) async {
  // Defensive: if already loading, return immediately
  if (_isLoading) {
    print('⚠️ signInWithGoogle called while already loading');
    return false;
  }
  _setLoadingAndNotify(true); // ensure this helper exists or replace with _isLoading = true; notifyListeners();
  _error = null;
  notifyListeners();

  try {
    print('🔵 signInWithGoogle: starting GoogleSignIn.signIn()');
    // Use timeout so UI doesn't hang indefinitely if OS/browser doesn't return
    final GoogleSignInAccount? googleUser = await _googleSignIn
        .signIn()
        .timeout(timeout, onTimeout: () => throw TimeoutException('Google Sign-In timed out'));

    if (googleUser == null) {
      // user cancelled sign-in (pressed back / closed dialog)
      _error = 'Google sign-in aborted by user';
      print('⚪ signInWithGoogle: user aborted sign-in');
      return false;
    }

    print('🔵 signInWithGoogle: got googleUser: ${googleUser.email}, id=${googleUser.id}');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      _error = 'Google auth returned no tokens';
      print('🔥 signInWithGoogle: no tokens returned from Google');
      return false;
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    print('🔵 signInWithGoogle: signing into Firebase with credential');
    final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);

    _user = userCred.user;
    if (_user == null) {
      _error = 'Firebase returned no user';
      print('🔥 signInWithGoogle: Firebase returned null user');
      return false;
    }

    print('✅ signInWithGoogle: success for uid=${_user!.uid}');
    notifyListeners(); // ensure UI/listeners update
    return true;
  } on TimeoutException catch (te) {
    _error = 'Sign-in timed out';
    print('⏱ signInWithGoogle timeout: ${te.message}');
    return false;
  } on FirebaseAuthException catch (fae) {
    _error = 'FirebaseAuth error: ${fae.code} ${fae.message}';
    print('🔥 FirebaseAuthException in signInWithGoogle: ${fae.code} ${fae.message}');
    return false;
  } catch (e, st) {
    _error = 'Unknown sign-in error';
    print('🔥 Unknown error in signInWithGoogle: $e\n$st');
    return false;
  } finally {
    _setLoadingAndNotify(false);
    // Also ensure listeners are notified if there's an error set
    notifyListeners();
  }
}

  /// Password reset
  Future<bool> sendPasswordResetEmail(String email) async {
    _clearError();
    _setLoadingAndNotify(true);

    try {
      print('📧 Sending password reset to: $email');
      
      final result = await FirebaseAuthService.sendPasswordResetEmail(email);

      _setLoadingAndNotify(false);

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
      _setLoadingAndNotify(false);
      _error = 'Failed to send reset email: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    print('🚪 Starting sign-out');
    _setLoadingAndNotify(true);
    _clearError();
    
    try {
      await FirebaseAuthService.signOut();
      print('✅ Sign-out completed - waiting for auth stream...');
      // Auth stream will handle the rest
    } catch (e) {
      print('❌ Sign-out error: $e');
      _setLoadingAndNotify(false);
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoadingAndNotify(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Emergency loading clear (for debugging)
  void clearLoadingState() {
    if (_isLoading) {
      _setLoadingAndNotify(false);
      print('⚠️ Loading state manually cleared');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}