// lib/pages/sign_up_page.dart
// FIXED VERSION - No manual navigation, AuthWrapper handles it

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:grand_battle_arena/pages/sign_in_page.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateManager>(
      builder: (context, authManager, child) {
        return Scaffold(
          backgroundColor: Appcolor.primary,
          appBar: AppBar(
            title: const Text(
              'Sign Up',
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
                  const Text(
                    'Join Battle Arena',
                    style: TextStyle(
                      color: Appcolor.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account and start competing',
                    style: TextStyle(color: Appcolor.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : Image.asset(
                              'assets/images/google_logo.webp',
                              height: 24.0,
                            ),
                      label: _isLoading
                          ? const SizedBox(
                              height: 24.0,
                              width: 24.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Appcolor.secondary,
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
                        backgroundColor: Appcolor.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

                  // Form Fields
                  _buildTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Email address',
                    inputType: TextInputType.emailAddress,
                    controller: _emailController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    label: 'Password',
                    isPasswordVisible: _isPasswordVisible,
                    onToggleVisibility: _isLoading
                        ? null
                        : () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                    controller: _passwordController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    label: 'Confirm Password',
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: _isLoading
                        ? null
                        : () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 30),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Appcolor.primary,
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Appcolor.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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

                  // Terms and Policy
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: Text(
                        'By signing up, you agree to our Terms of Service and Privacy Policy',
                        style: TextStyle(color: Appcolor.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign In Link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Appcolor.grey, fontSize: 14),
                        children: [
                          const TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: 'Sign in here',
                            style: TextStyle(
                              color: _isLoading 
                                  ? Appcolor.secondary.withOpacity(0.5)
                                  : Appcolor.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: _isLoading
                                ? null
                                : (TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignInPage()
                                      ),
                                    );
                                  }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType inputType = TextInputType.text,
    TextEditingController? controller,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Appcolor.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: enabled ? Appcolor.grey : Appcolor.grey.withOpacity(0.5)),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Appcolor.grey.withOpacity(0.5)),
        ),
      ),
      keyboardType: inputType,
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool isPasswordVisible,
    required VoidCallback? onToggleVisibility,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Appcolor.white),
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: enabled ? Appcolor.grey : Appcolor.grey.withOpacity(0.5)),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Appcolor.grey.withOpacity(0.5)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: enabled ? Appcolor.grey : Appcolor.grey.withOpacity(0.5),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    final success = await authManager.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (!success && authManager.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authManager.error!))
        );
      }
    }
    // If success, AuthWrapper handles navigation automatically
  }

  void _handleCreateAccount() async {
    // Validation
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    final success = await authManager.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (!success && authManager.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authManager.error!))
        );
      }
    }
    // If success, AuthWrapper handles navigation automatically
  }
}