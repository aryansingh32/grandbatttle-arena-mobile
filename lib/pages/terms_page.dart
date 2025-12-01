import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.background,
      appBar: AppBar(
        title: const Text(
          "Terms and Conditions",
          style: TextStyle(color: Appcolor.white),
        ),
        backgroundColor: Appcolor.background,
        iconTheme: const IconThemeData(color: Appcolor.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1. Introduction"),
            _buildSectionContent(
              "Welcome to Grand Battle Arena. By using our app, you agree to these terms. Please read them carefully.",
            ),
            _buildSectionTitle("2. User Accounts"),
            _buildSectionContent(
              "You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.",
            ),
            _buildSectionTitle("3. Tournaments"),
            _buildSectionContent(
              "Participation in tournaments is subject to the specific rules of each event. We reserve the right to disqualify any player who violates these rules.",
            ),
            _buildSectionTitle("4. Virtual Currency"),
            _buildSectionContent(
              "Coins earned or purchased in the app have no real-world monetary value and cannot be exchanged for cash.",
            ),
            _buildSectionTitle("5. Prohibited Conduct"),
            _buildSectionContent(
              "Cheating, hacking, or using unauthorized third-party software is strictly prohibited and will result in an immediate ban.",
            ),
            _buildSectionTitle("6. Changes to Terms"),
            _buildSectionContent(
              "We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of the new terms.",
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Last Updated: December 2025",
                style: TextStyle(color: Appcolor.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Appcolor.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        color: Appcolor.grey,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}
