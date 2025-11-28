import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/circularavatar.dart';
import 'package:grand_battle_arena/items/withdrawal.dart';
import 'package:grand_battle_arena/models/transaction_model.dart';
import 'package:grand_battle_arena/pages/deposit_page.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:shimmer/shimmer.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  // REMOVED: Unused TextEditingControllers for amount and UPI.
  int currentIndex = 2;

  // --- State Variables ---
  int currentBalance = 0;
  bool _isBalanceLoading = true;
  String? userFirebaseUID;
  String? userPhotoURL; // ADDED: To store user's profile image URL.
  List<TransactionModel> transactions = [];
  bool _isTransactionsLoading = true;
  bool get _isLoadingAny => _isBalanceLoading || _isTransactionsLoading;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  // MODIFIED: No longer need to dispose controllers.
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeWallet() async {
    await _getCurrentUser();
    // Only load data if user is successfully authenticated.
    if (userFirebaseUID != null) {
      await _loadWalletData();
      await _loadTransactions();
    }
  }

  // MODIFIED: Fetches the full user object to get photoURL.
  Future<void> _getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        userFirebaseUID = user.uid;
        userPhotoURL = user.photoURL;
      });
    } catch (e) {
      print('Error getting current user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: $e')),
        );
      }
    }
  }

  Future<void> _loadWalletData() async {
    if (userFirebaseUID == null) return;
    try {
      final walletData = await ApiService.getWallet(userFirebaseUID!);
      if (mounted) {
        setState(() {
          currentBalance = walletData.coins ?? 0;
          _isBalanceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBalanceLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallet: $e')),
        );
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactionData = await ApiService.getTransactionHistory();
      if (mounted) {
        setState(() {
          transactions = transactionData;
          _isTransactionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTransactionsLoading = false);
      }
      print('Failed to load transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(9, 11, 14, 1),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _initializeWallet,
            color: Appcolor.secondary,
            backgroundColor: Appcolor.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(top: 90, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "My Wallet",
                          style: TextStyle(color: Appcolor.white, fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 25),

                      // Balance Display
                      _buildBalanceHero(),

                      // Deposit and Withdraw Buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 25, bottom: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => showDepositPopUp(),
                              child: Container(
                                height: 49,
                                width: 127,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: Appcolor.secondary),
                                child: Center(
                                  child: Text("Deposit",
                                      style: TextStyle(
                                          color: Appcolor.primary,
                                          letterSpacing: 1)),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => WithdrawalDialog(
                                      currentBalance: currentBalance,
                                      onWithdrawalSuccess: _loadWalletData),
                                );
                              },
                              child: Container(
                                height: 49,
                                width: 127,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Appcolor.secondary),
                                ),
                                child: Center(
                                  child: Text("Withdraw",
                                      style: TextStyle(
                                          color: Appcolor.secondary,
                                          letterSpacing: 1)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 15),
                          child: Container(
                              width: 175,
                              height: 0.5,
                              decoration: BoxDecoration(color: Appcolor.grey)),
                        ),
                      ),

                      if (_isTransactionsLoading || rewardTransactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildEarningsScoreboard(),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Transactions",
                            style: TextStyle(
                                color: Appcolor.white,
                                fontSize: 20,
                                letterSpacing: 1)),
                      ),

                      // Transaction List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                          decoration: BoxDecoration(
                            color: Appcolor.cardsColor,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20)),
                          ),
                          height: 500 - 36,
                          width: double.infinity,
                          child: _isTransactionsLoading
                              ? _buildTransactionShimmer()
                              : transactions.isEmpty
                                  ? Center(
                                      child: Text("No transactions yet",
                                          style: TextStyle(color: Appcolor.grey, fontSize: 16)))
                                  : SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          // MODIFIED: Map now passes status and photoUrl to the widget.
                                          ...transactions.map(
                                            (transaction) => Padding(
                                              padding: const EdgeInsets.only(bottom: 16.0),
                                              child: _buildTransactionLogs(
                                                transtype: transaction.type,
                                                amount: transaction.amount,
                                                date: transaction.date.toIso8601String(),
                                                status: transaction.status, // Pass status from model
                                                photoUrl: userPhotoURL, // Pass user photo URL
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 80),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHero() {
    if (_isBalanceLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[700]!,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/icons/dollar.png', height: 31),
        const SizedBox(width: 10),
        Text(
          currentBalance.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              ),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Appcolor.secondary,
            fontSize: 20,
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
    );
  }

  Widget _buildTransactionShimmer() {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[600]!,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  List<TransactionModel> get rewardTransactions =>
      transactions.where((tx) => tx.type.toLowerCase() == 'reward').toList();

  Widget _buildEarningsScoreboard() {
    final rewards = rewardTransactions;
    if (_isTransactionsLoading && rewards.isEmpty) {
      return const SizedBox.shrink();
    }

    if (rewards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Play tournaments to unlock your earnings scorecard.',
          style: TextStyle(color: Appcolor.grey, fontSize: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Earnings Scoreboard",
          style: TextStyle(
            color: Appcolor.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...rewards.take(5).map(
          (tx) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Appcolor.cardsColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Appcolor.secondary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Appcolor.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reward: ${tx.transactionUID}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatDate(tx.date.toIso8601String()),
                        style: const TextStyle(color: Appcolor.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Image.asset('assets/icons/dollar.png', height: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+${tx.amount}',
                      style: const TextStyle(
                        color: Appcolor.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // --- Widgets and Methods ---

  // REPLACED: The old `showDepositPopUp` is replaced with the new UI.
// MODIFIED: Fetches deposit options from the API before showing the dialog.
void showDepositPopUp() async {
  // Show a temporary loading indicator while fetching options.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator(color: Appcolor.secondary)),
  );

  try {
    // Fetch the available payment options from your ApiService.
    final depositOptions = await ApiService.getAvailablePaymentAmounts();
    
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss the loading indicator.

    int? selectedInr; // State for the selected amount

    // Now, show the main dialog with the fetched options.
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Color.fromRGBO(9, 11, 14, 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Deposit",
                            style: TextStyle(
                                color: Appcolor.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: Appcolor.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text("TopUp Wallet",
                        style: TextStyle(
                            color: Appcolor.white.withOpacity(0.8),
                            fontSize: 18)),
                    SizedBox(height: 10),
                    // Use the fetched depositOptions list here.
                    ...depositOptions.map((option) {
                      return _buildDepositChip(
                        inr: option.amount,      // Use option.amount
                        coins: option.coins,    // Use option.coins
                        isSelected: selectedInr == option.amount,
                        onTap: () => setDialogState(() => selectedInr = option.amount),
                      );
                    }).toList(),
                    SizedBox(height: 30),
                    Text("Select Payment Mode",
                        style: TextStyle(
                            color: Appcolor.white.withOpacity(0.8),
                            fontSize: 18)),
                    SizedBox(height: 8),
                    Text("UPI Mode",
                        style: TextStyle(
                            color: Appcolor.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 30),
                    InkWell(
                      borderRadius: BorderRadius.circular(15),
                      // FIXED: Correctly navigate to the PaymentPage.
                      onTap: selectedInr == null
                          ? null
                          : () {
                              Navigator.pop(context); // Close the dialog first.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentPage(amount: selectedInr!),
                                ),
                              );
                            },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: selectedInr == null
                              ? Colors.grey[700]
                              : Appcolor.secondary,
                        ),
                        child: Center(
                          child: Text(
                            selectedInr == null ? "PAY" : "PAY ₹$selectedInr",
                            style: TextStyle(
                                letterSpacing: 1,
                                color: selectedInr == null
                                    ? Colors.grey[400]
                                    : Appcolor.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading indicator on error.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load deposit options: $e")),
    );
  }
}
  
  // ADDED: Helper widget for the new deposit chips in the dialog.
  Widget _buildDepositChip({
    required int inr,
    required int coins,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color.fromRGBO(63, 62, 62, 1),
          border:
              isSelected ? Border.all(color: Appcolor.secondary, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("₹$inr",
                style: TextStyle(
                    color: Appcolor.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Row(
              children: [
                Image.asset('assets/icons/dollar.png', height: 20),
                SizedBox(width: 8),
                Text("$coins Coin",
                    style: TextStyle(
                        color: Appcolor.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIED: `_handlePayment` now takes an amount and doesn't use controllers.
  Future<void> _handlePayment(int amount) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid amount')),
      );
      return;
    }

    try {
      String transactionUID = "txn_${DateTime.now().millisecondsSinceEpoch}";
      await ApiService.createDepositRequest(transactionUID, amount);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deposit request for ₹$amount submitted successfully')),
      );

      _loadWalletData();
      _loadTransactions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process deposit: $e')),
      );
    }
  }

  // MODIFIED: This widget now shows the user's photo and transaction status.
  Widget _buildTransactionLogs({
    required String transtype,
    required int amount,
    String? date,
    required String status,
    required String? photoUrl,
  }) {
    final isDeposit = transtype.toLowerCase() == 'deposit';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Column(
              children: [
                SizedBox(height: 10,width: 1,),
                // Uses network image for user's photo, with a local fallback.
            CircularProfile(
              isNetwork: photoUrl != null,
              imageLink: photoUrl ?? "assets/images/default_avatar.png",
              navigationLocation: '',
            ),
              ],
            ),
            
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transtype, style: TextStyle(color: Appcolor.white)),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: TextStyle(color: Appcolor.grey, fontSize: 10),
                  ),
                  SizedBox(height: 4),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text(
                  isDeposit ? '+' : '-',
                  style: TextStyle(
                      color: isDeposit ? Colors.green : Colors.redAccent),
                ),
                // Image.asset("assets/icons/dollar.png", width: 16),
                Text('₹$amount',
                    style: TextStyle(
                        color: isDeposit ? Colors.green : Colors.redAccent)),
              ],
            ),
            SizedBox(height: 4),
            // Display transaction status with color coding.
            Text(
              status,
              style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
          ],
        )
      ],
    );
  }

  // ADDED: Helper function to determine status color.
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orangeAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Appcolor.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }
}