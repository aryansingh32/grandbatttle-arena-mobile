import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/glowcard.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';

class Balancecard extends StatefulWidget {
  final bool showWallet;
  final bool showBalanceText;
  final double height;
  
  const Balancecard({
    super.key,
    this.showWallet = true,
    this.height = 190,
    this.showBalanceText = true,
  });

  @override
  State<Balancecard> createState() => _BalancecardState();
}

class _BalancecardState extends State<Balancecard> {
  double balance = 0.0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {




      setState(() {
        isLoading = true;
        error = null;
      });

      // Get current user's Firebase UID
      final currentUser = FirebaseAuthService.currentUser;
      if (currentUser == null) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      final walletData = await ApiService.getWallet(currentUser.uid);
      if (mounted) {
      setState(() {
        balance = (walletData.coins ?? 0).toDouble();
        isLoading = false;
      });}
    } catch (e) {
      if (mounted) {
      setState(() {
        error = e.toString();
        isLoading = false;
        balance = 0.0; // Default value on error
      });}
      
      // Don't show snackbar for balance errors as it's not critical
      print('Failed to load wallet balance: $e');
    }
  }

  String get balanceDisplay {
    if (isLoading) return "...";
    if (error != null) return "0"; // Show 0 on error
    return balance.toInt().toString(); // Remove decimals for display
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlowingContainer(
        height: widget.height,
        width: 368,
        glowColor: Appcolor.secondary,
        glowBarWidth: 10,
        borderWidth: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Balance text
            widget.showBalanceText
                ? const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 15),
                    child: Text(
                      "My Balance",
                      style: TextStyle(
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const SizedBox(height: 4),
            
            // Balance amount with loading/error handling
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icons/dollar.png', height: 31, width: 31),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Appcolor.secondary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          balanceDisplay,
                          key: ValueKey(balanceDisplay),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: error != null ? Appcolor.grey : Appcolor.secondary,
                            fontSize: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    "Coin",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 25),
            
            // Wallet button and refresh
            if (widget.showWallet)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => Navigator.pushNamed(context, '/wallet'),
                    child: Container(
                      width: 108,
                      height: 43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Appcolor.secondary,
                      ),
                      child: const Center(
                        child: Text(
                          "Wallet",
                          style: TextStyle(
                            letterSpacing: 1,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Refresh button
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _loadWalletBalance,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Appcolor.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Appcolor.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}