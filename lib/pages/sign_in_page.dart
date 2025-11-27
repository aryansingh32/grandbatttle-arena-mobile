// lib/pages/sign_in_page.dart
// COMPLETELY FIXED - Proper loading states with visual feedback

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:grand_battle_arena/pages/sign_up_page.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/providers/app_config_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isPasswordVisible = false;
  bool _isGoogleSignInLoading = false;
  bool _isEmailSignInLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateManager>(
      builder: (context, authManager, child) {
        // If user is authenticated, they shouldn't see this page
        // AuthWrapper will handle navigation
        if (authManager.isAuthenticated) {
          print('⚠️ User is authenticated but still on SignInPage');
        }

        return Scaffold(
          backgroundColor: Appcolor.primary,
          appBar: AppBar(
            title: const Text(
              'Sign In',
              style: TextStyle(
                color: Appcolor.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Appcolor.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Appcolor.white),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Dynamic Logo
                  Consumer<AppConfigProvider>(
                    builder: (context, configProvider, child) {
                      if (configProvider.logoUrl != null && configProvider.logoUrl!.isNotEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: CachedNetworkImage(
                              imageUrl: configProvider.logoUrl!,
                              height: 100,
                              placeholder: (context, url) => const SizedBox(height: 100),
                              errorWidget: (context, url, error) => const SizedBox(),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),

                  // Header
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Appcolor.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your gaming journey',
                    style: TextStyle(color: Appcolor.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_isGoogleSignInLoading || _isEmailSignInLoading)
                              ? null
                              : _handleGoogleSignIn,
                      icon:
                          _isGoogleSignInLoading
                              ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Appcolor.primary,
                                  ),
                                ),
                              )
                              : Image.asset(
                                'assets/images/google_logo.webp',
                                height: 24.0,
                              ),
                      label: Text(
                        _isGoogleSignInLoading
                            ? 'Signing in...'
                            : 'Continue with Google',
                        style: const TextStyle(
                          color: Appcolor.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isGoogleSignInLoading
                                ? Appcolor.white.withOpacity(
                                  0.95,
                                ) // Keep it white, not black
                                : Appcolor.white,
                        disabledBackgroundColor: Appcolor.white.withOpacity(
                          0.95,
                        ), // CRITICAL FIX
                        elevation: _isGoogleSignInLoading ? 2 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Appcolor.grey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Appcolor.grey),
                        ),
                      ),
                      Expanded(child: Divider(color: Appcolor.grey)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    enabled: !(_isGoogleSignInLoading || _isEmailSignInLoading),
                    style: const TextStyle(color: Appcolor.white),
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      labelStyle: TextStyle(color: Appcolor.grey),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Appcolor.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Appcolor.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Appcolor.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    enabled: !(_isGoogleSignInLoading || _isEmailSignInLoading),
                    style: const TextStyle(color: Appcolor.white),
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Appcolor.grey),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Appcolor.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Appcolor.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Appcolor.secondary,
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Appcolor.grey,
                        ),
                        onPressed:
                            (_isGoogleSignInLoading || _isEmailSignInLoading)
                                ? null
                                : () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email Sign-In Button
                  // Email Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_isGoogleSignInLoading || _isEmailSignInLoading)
                              ? null
                              : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Appcolor.secondary, // ✅ Always secondary color
                        disabledBackgroundColor: Appcolor.secondary.withOpacity(
                          0.7,
                        ), // ✅ CRITICAL FIX - stays yellow when disabled
                        elevation: _isEmailSignInLoading ? 2 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isEmailSignInLoading
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Appcolor.primary,
                                      ), // Dark spinner on yellow
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Signing in...',
                                    style: TextStyle(
                                      color: Appcolor.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                'Sign In with Email',
                                style: TextStyle(
                                  color: Appcolor.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Display
                  if (authManager.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authManager.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Forgot Password
                  Center(
                    child: TextButton(
                      onPressed:
                          (_isGoogleSignInLoading || _isEmailSignInLoading)
                              ? null
                              : _handleForgotPassword,
                      child: const Text(
                        'Forgot your password?',
                        style: TextStyle(color: Appcolor.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign Up Link
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Appcolor.grey, fontSize: 14),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign up here',
                              style: TextStyle(
                                color:
                                    (_isGoogleSignInLoading ||
                                            _isEmailSignInLoading)
                                        ? Appcolor.secondary.withOpacity(0.5)
                                        : Appcolor.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer:
                                  (_isGoogleSignInLoading ||
                                          _isEmailSignInLoading)
                                      ? null
                                      : (TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const SignUpPage(),
                                            ),
                                          );
                                        }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Paste this inside SignInPage State class ----------

  // Handler to call when the Google button is tapped
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSignInLoading) return;
    setState(() => _isGoogleSignInLoading = true);

    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    print('🔵 UI: calling signInWithGoogle()');

    try {
      final success = await authManager.signInWithGoogle();
      print(
        '🔵 Google sign-in result (UI): $success, authManager.error=${authManager.error}',
      );
      if (success) {
        // Prefer relying on AuthWrapper stream to navigate. If you want immediate navigation:
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // CHANGE: collapse back to wrapper after Google flow.
        }
      } else {
        // Show error returned from AuthStateManager or generic message
        final message = authManager.error ?? 'Google sign-in failed';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } else {
          print(
            '⚠️ Could not show SnackBar; widget unmounted. message=$message',
          );
        }
      }
    } catch (e, st) {
      print('🔥 _handleGoogleSignIn unknown error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign-in error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGoogleSignInLoading = false);
      // If unmounted, ensure provider clears loading
      if (!mounted) authManager.clearLoadingState();
    }
  }

  // Sample button widget (replace your existing Google button widget)
  Widget _googleSignInButton() {
    return ElevatedButton.icon(
      onPressed: (_isGoogleSignInLoading) ? null : _handleGoogleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      icon:
          _isGoogleSignInLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Image.asset('assets/images/google_logo.webp', height: 22),
      label: Text(
        _isGoogleSignInLoading ? 'Signing in...' : 'Continue with Google',
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
  // ---------- End ----------

  // Handle Email Sign-In
  // Handle Email Sign-In
  void _handleSignIn() async {
    print('📧 _handleSignIn: Starting email sign-in at ${DateTime.now()}');

    if (_isGoogleSignInLoading || _isEmailSignInLoading) {
      print('⚠️ _handleSignIn: Already loading, ignoring');
      return;
    }

    // Validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    print('📧 _handleSignIn: Setting loading state');
    setState(() => _isEmailSignInLoading = true);

    final authManager = Provider.of<AuthStateManager>(context, listen: false);

    print('📧 _handleSignIn: Calling authManager.signInWithEmail()');
    final success = await authManager.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    print(
      '📧 _handleSignIn: Got result - success=$success, error=${authManager.error}',
    );

    if (!mounted) {
      print('⚠️ _handleSignIn: Widget unmounted, aborting');
      return;
    }

    setState(() => _isEmailSignInLoading = false);

    if (success) {
      // ✅ SUCCESS CASE - Show feedback and let AuthWrapper navigate
      print(
        '✅ _handleSignIn: Email sign-in successful! Waiting for AuthWrapper to navigate...',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Signed in successfully! Loading home...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ AuthWrapper's StreamBuilder will automatically detect auth state
      // and show MainContainer within 50-300ms
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // CHANGE: return to AuthWrapper so it can swap screens.
      }
    } else {
      // ❌ ERROR CASE - Show error message
      print('❌ _handleSignIn: Sign-in failed - ${authManager.error}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(authManager.error ?? 'Sign-in failed')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Handle forgot password
  void _handleForgotPassword() async {
    if (_isGoogleSignInLoading || _isEmailSignInLoading) return;

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email to reset password')),
      );
      return;
    }

    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    final success = await authManager.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authManager.error ?? 'Failed to send reset email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
