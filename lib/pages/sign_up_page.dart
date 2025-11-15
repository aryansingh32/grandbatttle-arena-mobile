import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:grand_battle_arena/pages/main_component.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/auth_state_manager.dart';
import 'package:grand_battle_arena/pages/sign_in_page.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const Center(child: Text('Terms of Service Content')),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Center(child: Text('Privacy Policy Content')),
    );
  }
}

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
                  // Header Text
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
                      onPressed: authManager.isLoading ? null : _handleGoogleSignIn,
                      icon: authManager.isLoading
                          ? Container()
                          : Image.asset(
                              'assets/images/google_logo.webp',
                              height: 24.0,
                            ),
                      label: authManager.isLoading
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
                    enabled: !authManager.isLoading,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Email address',
                    inputType: TextInputType.emailAddress,
                    controller: _emailController,
                    enabled: !authManager.isLoading,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    label: 'Password',
                    isPasswordVisible: _isPasswordVisible,
                    onToggleVisibility: authManager.isLoading
                        ? null
                        : () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                    controller: _passwordController,
                    enabled: !authManager.isLoading,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    label: 'Confirm Password',
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: authManager.isLoading
                        ? null
                        : () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                    controller: _confirmPasswordController,
                    enabled: !authManager.isLoading,
                  ),
                  const SizedBox(height: 30),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authManager.isLoading ? null : _handleCreateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authManager.isLoading
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Appcolor.grey, fontSize: 12),
                          children: [
                            const TextSpan(text: "By signing up, you agree to our "),
                            _buildClickableTextSpan('Terms of Service', 
                              authManager.isLoading ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsOfServicePage(),
                                  ),
                                );
                              }
                            ),
                            const TextSpan(text: " and "),
                            _buildClickableTextSpan('Privacy Policy', 
                              authManager.isLoading ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyPage(),
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
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
                          _buildClickableTextSpan('Sign in here',
                            authManager.isLoading ? null : () {
                             Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInPage()),
                            ); 

                            }
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

  TextSpan _buildClickableTextSpan(String text, VoidCallback? onTap) {
    return TextSpan(
      text: text,
      style: TextStyle(
        color: onTap != null ? Appcolor.secondary : Appcolor.secondary.withOpacity(0.5),
        fontWeight: FontWeight.bold,
      ),
      recognizer: onTap != null ? (TapGestureRecognizer()..onTap = onTap) : null,
    );
  }

  void _handleGoogleSignIn() async {
    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    final success = await authManager.signInWithGoogle();

    if (!mounted) return;
  // Let the AuthWrapper handle the redirect. Only show an error if it fails.
  if (!success && authManager.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authManager.error!)));
  }
    // Success is handled automatically by AuthWrapper
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

    final authManager = Provider.of<AuthStateManager>(context, listen: false);
    final success = await authManager.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (!mounted) return;

      // Let the AuthWrapper handle the redirect. Only show an error if it fails.
  if (!success && authManager.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authManager.error!)));
  }
    // Success is handled automatically by AuthWrapper
  }
}