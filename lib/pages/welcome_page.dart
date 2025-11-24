import 'package:flutter/material.dart';
import 'package:grand_battle_arena/pages/sign_in_page.dart';
import 'package:grand_battle_arena/pages/sign_up_page.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Logo + slogan ---
              Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "BATTLE",
                        style: TextStyle(
                          color: Appcolor.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ARENA",
                        style: TextStyle(
                          color: Appcolor.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Where Champions Are Forged.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Appcolor.grey,
                    ),
                  ),
                ],
              ),

              // --- Welcome text ---
              Column(
                children: [
                  Text(
                    "Welcome!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      color: Appcolor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "The ultimate platform for mobile gamers. Join daily tournaments and compete for epic prizes.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Appcolor.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // --- Auth actions ---
              Column(
                children: [
                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignInPage(),
                          ),
                        ); // CHANGE: keep AuthWrapper underneath so it can react.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          color: Appcolor.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        ); // CHANGE: allow wrapper stream to control navigation.
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Appcolor.secondary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                          color: Appcolor.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
