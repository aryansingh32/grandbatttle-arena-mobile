import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/balancecard.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';

class WithdrawalDialog extends StatefulWidget {
  final int currentBalance;
  final VoidCallback? onWithdrawalSuccess;
  
  const WithdrawalDialog({
    super.key,
    required this.currentBalance,
    this.onWithdrawalSuccess,
  });

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  final TextEditingController _withdrawAmountController = TextEditingController();
  final TextEditingController _withdrawUpiController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _withdrawAmountController.dispose();
    _withdrawUpiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Appcolor.cardsColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Appcolor.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Improved header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Appcolor.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Appcolor.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Withdraw Funds",
                          style: TextStyle(
                            color: Appcolor.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Appcolor.grey),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Appcolor.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Improved balance display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Appcolor.secondary.withOpacity(0.2),
                        Appcolor.secondary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Appcolor.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Available Balance",
                            style: TextStyle(
                              color: Appcolor.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/dollar.png',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.currentBalance.toString(),
                                style: const TextStyle(
                                  color: Appcolor.secondary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Appcolor.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Appcolor.secondary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Amount section with improved UI
                const Text(
                  "Withdrawal Amount",
                  style: TextStyle(
                    color: Appcolor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Appcolor.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _withdrawAmountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Appcolor.secondary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/icons/dollar.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      hintText: "Enter Amount",
                      hintStyle: TextStyle(
                        color: Appcolor.grey.withOpacity(0.5),
                        fontSize: 18,
                      ),
                      filled: true,
                      fillColor: Appcolor.primary.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Appcolor.secondary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Appcolor.secondary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                
                // Improved price chips
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildWithdrawPriceChips(100),
                      _buildWithdrawPriceChips(500),
                      _buildWithdrawPriceChips(1000),
                      _buildWithdrawPriceChips(2000),
                      _buildWithdrawPriceChips(5000),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Improved UPI section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Appcolor.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Appcolor.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Appcolor.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Appcolor.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "UPI Payment Method",
                            style: TextStyle(
                              color: Appcolor.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _withdrawUpiController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Appcolor.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your UPI ID (e.g., yourname@paytm)",
                          hintStyle: TextStyle(
                            color: Appcolor.grey.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.payment,
                            color: Appcolor.secondary,
                          ),
                          filled: true,
                          fillColor: Appcolor.cardsColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Appcolor.secondary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Appcolor.secondary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Appcolor.secondary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Appcolor.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Appcolor.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Funds will be transferred to this UPI ID",
                                style: TextStyle(
                                  color: Appcolor.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Improved withdraw button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing
                          ? Appcolor.secondary.withOpacity(0.5)
                          : Appcolor.secondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Appcolor.secondary.withOpacity(0.3),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Appcolor.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.send_rounded,
                                color: Appcolor.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Withdraw Funds",
                                style: TextStyle(
                                  color: Appcolor.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Appcolor.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Appcolor.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Appcolor.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Withdrawal requests are processed within 24-48 hours",
                          style: TextStyle(
                            color: Appcolor.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onWithdrawChipTap(int amount) {
    setState(() {
      _withdrawAmountController.text = amount.toString();
    });
    // Trigger rebuild to update chip selection state
  }

  Future<void> _handleWithdrawal() async {
    final amount = _withdrawAmountController.text;
    final upiId = _withdrawUpiController.text;
    
    if (amount.isEmpty) {
      _showErrorSnackBar('Please enter withdrawal amount');
      return;
    }

    final withdrawAmount = int.tryParse(amount);
    if (withdrawAmount == null) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    // Check if user has sufficient balance
    if (withdrawAmount > widget.currentBalance) {
      _showErrorSnackBar('Insufficient balance. Available: ${widget.currentBalance} coins');
      return;
    }

    // Check minimum withdrawal amount
    if (withdrawAmount < 100) {
      _showErrorSnackBar('Minimum withdrawal amount is 100 coins');
      return;
    }

    if (upiId.isEmpty) {
      _showErrorSnackBar('Please enter your UPI ID');
      return;
    }

    // Basic UPI ID validation
    if (!upiId.contains('@')) {
      _showErrorSnackBar('Please enter a valid UPI ID');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // FIXED: Send exact UPI ID to backend as transactionUID
      await ApiService.createWithdrawalRequest(withdrawAmount, upiId: upiId.trim());
      
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal request submitted for $withdrawAmount coins'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh wallet data in parent
      widget.onWithdrawalSuccess?.call();

      // Clear the controllers
      _withdrawAmountController.clear();
      _withdrawUpiController.clear();

    } catch (e) {
      _showErrorSnackBar('Failed to process withdrawal: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildWithdrawPriceChips(int amount) {
    final isSelected = _withdrawAmountController.text == amount.toString();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onWithdrawChipTap(amount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected
                ? Appcolor.secondary
                : Appcolor.primary.withOpacity(0.5),
            border: Border.all(
              color: isSelected
                  ? Appcolor.secondary
                  : Appcolor.secondary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/dollar.png',
                width: 14,
                height: 14,
                color: isSelected ? Appcolor.primary : Appcolor.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                "$amount",
                style: TextStyle(
                  color: isSelected ? Appcolor.primary : Appcolor.secondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
