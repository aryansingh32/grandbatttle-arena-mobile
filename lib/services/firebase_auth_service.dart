import 'dart:async'; // ✅ Added for TimeoutException
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/services/notification_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static bool _isInitialized = false;

  // Initialize GoogleSignIn once
  static Future<void> _initializeGoogleSignIn() async {
    if (!_isInitialized) {
      _isInitialized = true;
      await _googleSignIn.isSignedIn();
    }
  }

  // Get current user
  static User? get currentUser => _firebaseAuth.currentUser;

  // Get current user stream
  static Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get Firebase ID Token
  static Future<String?> getIdToken() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  static String? getCurrentUserUID() {
    try {
      return currentUser?.uid;
    } catch (e) {
      print('Error getting current user UID: $e');
      return null;
    }
  }

  // ✅✅✅ CRITICAL FIX: Sign up with email and password (NON-BLOCKING)
  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print(
        '🔵 FirebaseAuthService: Creating user with email: $email at ${DateTime.now()}',
      );

      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      print(
        '✅ FirebaseAuthService: User created - uid=${credential.user?.uid} at ${DateTime.now()}',
      );

      if (credential.user != null) {
        // Update display name immediately
        print('🔵 FirebaseAuthService: Updating display name to: $fullName');
        await credential.user!.updateDisplayName(fullName);

        // ✅ CRITICAL: Force reload to ensure auth state stream emits
        print(
          '🔵 FirebaseAuthService: Reloading user to trigger auth state change...',
        );
        await credential.user!.reload();

        // ✅ Get fresh user object after reload
        final User? refreshedUser = _firebaseAuth.currentUser;
        print(
          '✅ FirebaseAuthService: User reloaded - displayName=${refreshedUser?.displayName}',
        );
        await Future.delayed(
          Duration(milliseconds: 100),
        ); // Give stream time to process
        print(
          '🔔 FirebaseAuthService: Waiting for auth stream to propagate...',
        );
        // ✅✅✅ CRITICAL FIX: Run backend calls in background WITHOUT blocking
        print(
          '🚀 IMMEDIATE RETURN: Returning success WITHOUT waiting for backend',
        );
        print('🚀 Backend registration will continue in background');
        _registerUserInBackground(fullName, email, credential.user!.uid);

        // ✅ Return immediately - don't wait for backend!
        return AuthResult.success(refreshedUser ?? credential.user!);
      } else {
        print('❌ FirebaseAuthService: credential.user is null!');
        return AuthResult.error('Failed to create user');
      }
    } on FirebaseAuthException catch (e) {
      print(
        '❌ FirebaseAuthService: FirebaseAuthException - ${e.code}: ${e.message}',
      );
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      print('❌ FirebaseAuthService: Unexpected error: $e');
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }

  // ✅✅✅ NEW METHOD: Register user in background without blocking UI
  static void _registerUserInBackground(
    String fullName,
    String email,
    String uid,
  ) {
    // Run in separate future so it doesn't block auth flow
    Future.microtask(() async {
      try {
        print(
          '🔵 Background: Starting backend registration for $email at ${DateTime.now()}',
        );

        // Backend registration (non-blocking with timeout)
        // FIXED: Include firebaseUserUID as per API reference
        await ApiService.registerUser(fullName, email, firebaseUserUID: uid).timeout(
          Duration(seconds: 10), // Prevent hanging
          onTimeout: () {
            print('⚠️ Background: Backend registration timed out after 10s');
            throw TimeoutException('Backend registration timeout');
          },
        );
        print(
          '✅ Background: Backend registration successful at ${DateTime.now()}',
        );

        // Send FCM token (non-blocking with timeout)
        await NotificationService.sendTokenToServer().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Background: FCM token send timed out after 10s');
            throw TimeoutException('FCM token timeout');
          },
        );
        print('✅ Background: FCM token sent at ${DateTime.now()}');
      } catch (e) {
        print('⚠️ Background: Registration failed (non-fatal): $e');
        // This is non-fatal - user is already signed in via Firebase
        // Backend registration can be retried later
      }
    });
  }

  // ✅✅✅ FIXED: Sign in with email and password (NON-BLOCKING)
  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print(
        '🔵 FirebaseAuthService: Signing in with email: $email at ${DateTime.now()}',
      );

      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      print(
        '✅ FirebaseAuthService: Sign-in successful - uid=${credential.user?.uid} at ${DateTime.now()}',
      );

      if (credential.user != null) {
        // ✅ Send FCM token in background (don't block sign-in)
        print(
          '🚀 IMMEDIATE RETURN: Returning success, FCM token will be sent in background',
        );
        _sendFCMTokenInBackground(credential.user!.uid);

        return AuthResult.success(credential.user!);
      } else {
        print('❌ FirebaseAuthService: credential.user is null!');
        return AuthResult.error('Failed to sign in');
      }
    } on FirebaseAuthException catch (e) {
      print(
        '❌ FirebaseAuthService: FirebaseAuthException - ${e.code}: ${e.message}',
      );
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      print('❌ FirebaseAuthService: Unexpected error: $e');
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }

  // ✅✅✅ NEW METHOD: Send FCM token in background
  static void _sendFCMTokenInBackground(String uid) {
    Future.microtask(() async {
      try {
        print(
          '🔵 Background: Sending FCM token for user $uid at ${DateTime.now()}',
        );
        await NotificationService.sendTokenToServer().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Background: FCM token send timed out');
            throw TimeoutException('FCM token timeout');
          },
        );
        print('✅ Background: FCM token sent successfully at ${DateTime.now()}');
      } catch (e) {
        print('⚠️ Background: FCM token send failed (non-fatal): $e');
        // Non-fatal - can retry later
      }
    });
  }

  // ✅✅✅ FIXED: Google Sign In (NON-BLOCKING)
  static Future<AuthResult> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      print(
        '🔵 FirebaseAuthService: Starting Google Sign-In at ${DateTime.now()}',
      );
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ FirebaseAuthService: Google sign-in canceled by user');
        return AuthResult.error('Google sign in was canceled by the user.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        print('❌ FirebaseAuthService: Failed to get Google ID token');
        return AuthResult.error('Failed to get Google authentication tokens.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        print('❌ FirebaseAuthService: Firebase returned null user');
        return AuthResult.error('Failed to sign in with Google.');
      }

      print(
        '✅ FirebaseAuthService: Google sign-in successful - uid=${user.uid} at ${DateTime.now()}',
      );

      // ✅ Handle new user registration in background (don't block)
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        print('🚀 New Google user - registering in background');
        _registerUserInBackground(
          user.displayName ?? 'Google User',
          user.email!,
          user.uid,
        );
      } else {
        print('🚀 Existing Google user - sending FCM token in background');
        // Existing user - just send FCM token in background
        _sendFCMTokenInBackground(user.uid);
      }

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      print(
        '❌ FirebaseAuthService: FirebaseAuthException - ${e.code}: ${e.message}',
      );
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e, stackTrace) {
      print('❌ FirebaseAuthService: Google Sign-in error: $e');
      print('Stack trace: $stackTrace');
      return AuthResult.error(
        'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  // Sign out (improved cleanup)
  static Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      print('✅ FirebaseAuthService: Sign-out completed');
    } catch (e) {
      print('❌ FirebaseAuthService: Sign-out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send password reset email
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      return AuthResult.error('Failed to send reset email: $e');
    }
  }

  // Handle Firebase Auth errors
  static String _handleFirebaseAuthError(FirebaseAuthException e) {
    print('Firebase Auth Error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been temporarily disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait before trying again.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different account.';
      case 'popup-closed-by-user':
        return 'Sign-in was canceled. Please try again.';
      default:
        return 'Authentication failed. Please try again. (${e.code})';
    }
  }
}

// Result class for auth operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  AuthResult.success(this.user) : isSuccess = true, error = null;

  AuthResult.error(this.error) : isSuccess = false, user = null;
}
