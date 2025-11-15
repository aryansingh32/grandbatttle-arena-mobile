import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/services/notification_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Add configuration for better performance
    scopes: ['email', 'profile'],
  );
  static bool _isInitialized = false;

  // Initialize GoogleSignIn once
  static Future<void> _initializeGoogleSignIn() async {
    if (!_isInitialized) {
      _isInitialized = true;
      // Pre-initialize Google Sign In
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
      // The currentUser getter already gives us the User object.
      // We just need to return its 'uid' property.
      return currentUser?.uid;
    } catch (e) {
      print('Error getting current user UID: $e');
      return null;
    }
  }

  // Sign up with email and password
  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name immediately
        await credential.user!.updateDisplayName(fullName);
        
        // Force reload to get updated user info
        await credential.user!.reload();
        
        try {
          await ApiService.registerUser(fullName, email);
        } catch (e) {
          print('Backend registration failed: $e');
          // Non-fatal error, continue with Firebase auth success
        }
         await NotificationService.sendTokenToServer();

        return AuthResult.success(credential.user!);
      } else {
        return AuthResult.error('Failed to create user');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return AuthResult.success(credential.user!);
      } else {
        return AuthResult.error('Failed to sign in');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: $e');
    }
  }

  // Google Sign In (improved performance)
  static Future<AuthResult> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      // Clear any existing sign-in to ensure fresh authentication
      // await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.error('Google sign in was canceled by the user.');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Ensure we have the required tokens
      if (googleAuth.idToken == null) {
        return AuthResult.error('Failed to get Google authentication tokens.');
      }
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return AuthResult.error('Failed to sign in with Google.');
      }
      
      // Handle new user registration
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        try {
          await ApiService.registerUser(
            user.displayName ?? 'Google User', 
            user.email!,
          );
        } catch (e) {
          print('Backend registration for Google user failed: $e');
          // Non-fatal error, continue with Firebase auth success
        }
      }

      await NotificationService.sendTokenToServer();

      return AuthResult.success(user); 
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleFirebaseAuthError(e));
    } catch (e) {
      print("Google Sign-in error: $e");
      return AuthResult.error('An unexpected error occurred during Google sign-in: ${e.toString()}');
    }
  }

  // Sign out (improved cleanup)
  static Future<void> signOut() async {
    try {
      // Sign out from both services concurrently for better performance
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      // Still throw to let calling code know about the error
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

  // Handle Firebase Auth errors (enhanced)
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

  AuthResult.success(this.user)
      : isSuccess = true,
        error = null;

  AuthResult.error(this.error)
      : isSuccess = false,
        user = null;
}