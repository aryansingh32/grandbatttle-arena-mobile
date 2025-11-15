import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:grand_battle_arena/pages/main_component.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:grand_battle_arena/pages/sign_up_page.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: const Center(child: Text('Forgot Password Screen')),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isPasswordVisible = false;
  bool _isGoogleSignInLoading = false; // Add separate loading state for Google
  bool _isEmailSignInLoading = false;  // Add separate loading state for email

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
        // If user is authenticated, immediately navigate
        // if (authManager.isAuthenticated && authManager.isInitialized) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     Navigator.of(context).pushReplacementNamed('/main');
        //   });
        // }

        return Scaffold(
          backgroundColor: Appcolor.primary,
          appBar: AppBar(
            title: const Text(
              'Sign In',
              style: TextStyle(color: Appcolor.white, fontWeight: FontWeight.bold),
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
                  // Header Text
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

                  // Google Sign-In Button with Enhanced Visual Feedback
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton.icon(
                        onPressed: (_isGoogleSignInLoading || _isEmailSignInLoading) 
                            ? null 
                            : _handleGoogleSignIn,
                        icon: _isGoogleSignInLoading
                            ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Appcolor.primary,
                                ),
                              )
                            : Image.asset(
                                'assets/images/google_logo.webp',
                                height: 24.0,
                              ),
                        label: _isGoogleSignInLoading
                            ? const Text(
                                'Signing in with Google...',
                                style: TextStyle(
                                  color: Appcolor.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: Appcolor.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isGoogleSignInLoading 
                              ? Appcolor.white.withOpacity(0.8) 
                              : Appcolor.white,
                          elevation: _isGoogleSignInLoading ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // "OR" Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Appcolor.grey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR', style: TextStyle(color: Appcolor.grey)),
                      ),
                      Expanded(child: Divider(color: Appcolor.grey)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Email Text Field
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
                        borderSide: BorderSide(color: Appcolor.secondary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password Text Field
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
                        borderSide: BorderSide(color: Appcolor.secondary, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Appcolor.grey,
                        ),
                        onPressed: (_isGoogleSignInLoading || _isEmailSignInLoading)
                            ? null
                            : () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign In Button with Enhanced Visual Feedback
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: (_isGoogleSignInLoading || _isEmailSignInLoading) 
                            ? null 
                            : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEmailSignInLoading 
                              ? Appcolor.secondary.withOpacity(0.8) 
                              : Appcolor.secondary,
                          elevation: _isEmailSignInLoading ? 2 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isEmailSignInLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Appcolor.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
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
                  ),
                  const SizedBox(height: 16),

                  // Error message display
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
                      child: Text(
                        authManager.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Forgot Password
                  Center(
                    child: TextButton(
                      onPressed: (_isGoogleSignInLoading || _isEmailSignInLoading) 
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
                                color: (_isGoogleSignInLoading || _isEmailSignInLoading) 
                                    ? Appcolor.secondary.withOpacity(0.5)
                                    : Appcolor.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: (_isGoogleSignInLoading || _isEmailSignInLoading)
                                  ? null
                                  : (TapGestureRecognizer()
                                    ..onTap = () {
                                       Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SignUpPage()),
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

  void _handleGoogleSignIn() async {
    if (_isGoogleSignInLoading || _isEmailSignInLoading) return;
    
    setState(() {
      _isGoogleSignInLoading = true;
    });
    

    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    
    try {
      final success = await authManager.signInWithGoogle();

      if (!mounted) return;

      if (success) {
        // Add a small delay to ensure state is properly updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force navigation to main app
        if (mounted) {
          // Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
          Navigator.of(context).pop(); 
        }
      } else {
        setState(() {
          _isGoogleSignInLoading = false;
        });
        
        if (authManager.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authManager.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isGoogleSignInLoading = false;
      });
      
      if (mounted) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }finally {
  if (mounted) setState(() => _isGoogleSignInLoading = false);
}
  }

  void _handleSignIn() async {
    if (_isGoogleSignInLoading || _isEmailSignInLoading) return;
    
    // Basic validation
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isEmailSignInLoading = true;
    });

    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    
    try {
      final success = await authManager.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Add a small delay to ensure state is properly updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force navigation to main app
        if (mounted) {
          // Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        Navigator.of(context).pop(); 
        }
      } else {
        setState(() {
          _isEmailSignInLoading = false;
        });
        
        if (authManager.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authManager.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isEmailSignInLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }finally {
  if (mounted) setState(() => _isGoogleSignInLoading = false);
}
  }

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