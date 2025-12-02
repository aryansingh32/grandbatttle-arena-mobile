import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class AuthWrapper extends StatefulWidget {
  final Widget signedInScreen;
  final Widget signedOutScreen;

  const AuthWrapper({
    super.key,
    required this.signedInScreen,
    required this.signedOutScreen,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    try {
      final appConfig = await ApiService.getAppVersion();
      final latestVersion = appConfig['version'] as String?;
      final updateUrl = appConfig['url'] as String?;
      final isMandatory = appConfig['mandatory'] as bool? ?? false;

      if (latestVersion != null) {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        
        print('📱 App Version Check: Current=$currentVersion, Latest=$latestVersion, Mandatory=$isMandatory');

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          if (mounted) {
            _showUpdateDialog(latestVersion, updateUrl, isMandatory);
          }
        }
      }
    } catch (e) {
      print('❌ Error checking app version: $e');
      // Ideally, for mandatory updates, we might want to retry or block.
      // For now, we just log it to avoid blocking the user if the server is down.
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    // Robust semantic version comparison
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int latestPart = latestParts[i];

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false;
    } catch (e) {
      print('⚠️ Version parsing error: $e');
      return current != latest; // Fallback to string comparison
    }
  }

  void _showUpdateDialog(String latestVersion, String? url, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory, // Prevent dismissal if mandatory
      builder: (context) => WillPopScope(
        onWillPop: () async => !isMandatory, // Prevent back button if mandatory
        child: AlertDialog(
          backgroundColor: Appcolor.cardsColor,
          title: const Text('Update Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version ($latestVersion) is available.',
                style: const TextStyle(color: Colors.white70),
              ),
              if (isMandatory)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'This is a mandatory update. Please update to continue using the app.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              onPressed: () {
                if (url != null) {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.secondary,
                foregroundColor: Appcolor.primary,
              ),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log('🏗️ AuthWrapper: build() called at ${DateTime.now()}', name: 'AuthFlow');
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final timestamp = DateTime.now().toIso8601String();
        
        developer.log(
          '🔄 AuthWrapper StreamBuilder at $timestamp\n'
          '   connectionState: ${snapshot.connectionState}\n'
          '   hasData: ${snapshot.hasData}\n'
          '   hasError: ${snapshot.hasError}\n'
          '   user: ${snapshot.data?.uid ?? "null"}\n'
          '   email: ${snapshot.data?.email ?? "none"}',
          name: 'AuthFlow',
        );

        // While connecting, show loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          developer.log('⏳ AuthWrapper: Showing loading screen', name: 'AuthFlow');
          return Scaffold(
            backgroundColor: const Color(0xFF090B0E), // Appcolor.primary
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    color: Color(0xFFFFC107), // Appcolor.secondary
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          developer.log(
            '✅ AuthWrapper: User authenticated, showing signedInScreen\n'
            '   User: ${snapshot.data!.uid}\n'
            '   Email: ${snapshot.data!.email}',
            name: 'AuthFlow'
          );
          return widget.signedInScreen;
        } else {
          developer.log('🚪 AuthWrapper: No user, showing signedOutScreen', name: 'AuthFlow');
          return widget.signedOutScreen;
        }
      },
    );
  }
}