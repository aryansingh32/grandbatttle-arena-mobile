import 'package:flutter/material.dart';
import 'package:grand_battle_arena/constants/support_constants.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse(
      'https://wa.me/${SupportConstants.whatsappNumber}?text=${Uri.encodeComponent(SupportConstants.whatsappMessage)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: SupportConstants.supportEmail,
      query: 'subject=Support Request&body=Describe your issue here...',
    );
    if (!await launchUrl(emailLaunchUri)) {
      throw 'Could not launch Email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.primary,
      appBar: AppBar(
        backgroundColor: Appcolor.cardsColor,
        title: const Text("Help & Support", style: TextStyle(color: Appcolor.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Appcolor.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact Us",
              style: TextStyle(
                color: Appcolor.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.chat,
              title: "WhatsApp Support",
              subtitle: "Chat with our support team",
              color: Colors.green,
              onTap: _launchWhatsApp,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email,
              title: "Email Support",
              subtitle: "Send us an email",
              color: Colors.blueAccent,
              onTap: _launchEmail,
            ),
            const SizedBox(height: 32),
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                color: Appcolor.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqTile(
              context,
              "How do I deposit money?",
              "Go to the Wallet tab, click 'Deposit', select an amount, and use the UPI QR code to pay. The amount will be reflected in your wallet shortly.",
            ),
            _buildFaqTile(
              context,
              "When do I get the Room ID?",
              "Room ID and Password are shared 10-15 minutes before the match start time via notification and in the 'My Bookings' section.",
            ),
            _buildFaqTile(
              context,
              "I won a match, when will I get paid?",
              "Prizes are usually credited within 24 hours of the match completion. Please upload a screenshot of your victory in the 'My Bookings' section to speed up the process.",
            ),
            _buildFaqTile(
              context,
              "Can I cancel my booking?",
              "Yes, you can cancel your booking up to 30 minutes before the match starts. The refund will be credited to your wallet.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Appcolor.cardsColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Appcolor.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Appcolor.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Appcolor.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Appcolor.secondary.withOpacity(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              color: Appcolor.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: Appcolor.secondary,
          collapsedIconColor: Appcolor.grey,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(color: Appcolor.grey, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
