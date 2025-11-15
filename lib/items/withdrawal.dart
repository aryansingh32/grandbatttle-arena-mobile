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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Dialog(
          backgroundColor: Appcolor.cardsColor,
          child: Container(
            height: 571,
            width: 349,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 85,),
                      Center(
                        child: Text(
                          "Withdraw",
                          style: TextStyle(
                            color: Appcolor.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w400
                          ),
                        ),
                      ),
                      SizedBox(width: 29,),
                      IconButton(
                        icon: Icon(Icons.close, color: Appcolor.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  
                  // Show current balance
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(63, 62, 62, 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Available Balance: ",
                          style: TextStyle(
                            color: Appcolor.grey,
                            fontSize: 14,
                          ),
                        ),
                        Image.asset('assets/icons/dollar.png', width: 16, height: 16),
                        Text(
                          widget.currentBalance.toString(),
                          style: TextStyle(
                            color: Appcolor.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Amount input field with dollar prefix
                  Container(
                    width: 179,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color.fromRGBO(63, 62, 62, 1),
                    ),
                    child: TextField(
                      controller: _withdrawAmountController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/icons/dollar.png',
                            width: 16,
                            height: 16,
                          ),
                        ),
                        hintText: "Enter The Amount",
                        filled: true,
                        fillColor: Color.fromRGBO(63, 62, 62, 1),
                        hintStyle: TextStyle(
                          color: Appcolor.grey,
                          fontSize: 10
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                        color: Appcolor.secondary,
                      ),
                    ),
                  ),
                  
                  // Price chips for withdrawal
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildWithdrawPriceChips(100),
                          _buildWithdrawPriceChips(500),
                          _buildWithdrawPriceChips(1000),
                          _buildWithdrawPriceChips(2000),
                          _buildWithdrawPriceChips(5000),
                        ]
                      ),
                    ),
                  ),
                  
                  // Withdrawal method section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, top: 5, bottom: 7),
                      child: Text(
                        "Withdrawal Method",
                        style: TextStyle(
                          color: Appcolor.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400
                        ),
                      ),
                    ),
                  ),
                  
                  // UPI Mode
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2,),
                      child: Text(
                        "UPI Mode",
                        style: TextStyle(
                          color: Appcolor.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400
                        ),
                      ),
                    ),
                  ),
                  
                  // UPI section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(63, 62, 62, 1),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 5),
                          Text(
                            "Enter Your UPI Id:",
                            style: TextStyle(
                              color: Appcolor.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w400
                            ),
                          ),
                          SizedBox(height: 8),
                          // UPI ID input
                          TextField(
                            controller: _withdrawUpiController,
                            decoration: InputDecoration(
                              hintText: "UPI Id",
                              filled: true,
                              fillColor: Color.fromRGBO(63, 62, 62, 1),
                              hintStyle: TextStyle(
                                color: Appcolor.grey,
                                fontSize: 13
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Appcolor.grey.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Appcolor.secondary, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Appcolor.grey.withOpacity(0.3)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: TextStyle(
                              color: Appcolor.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Withdraw button with loading state
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: _isProcessing ? null : () => _handleWithdrawal(),
                    child: Container(
                      width: 108,
                      height: 43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: _isProcessing 
                          ? Appcolor.secondary.withOpacity(0.5)
                          : Appcolor.secondary,
                      ),
                      child: Center(
                        child: _isProcessing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Appcolor.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Withdraw",
                              style: TextStyle(
                                letterSpacing: 1,
                                color: Appcolor.primary,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }

  void _onWithdrawChipTap(int amount) {
    setState(() {
      _withdrawAmountController.text = amount.toString();
    });
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
      // Call API to create withdrawal request //TODO add , upiId field
      await ApiService.createWithdrawalRequest(withdrawAmount);
      
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

  Widget _buildWithdrawPriceChips(int amount){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () => _onWithdrawChipTap(amount),
        child: Container(
          height: 24,
          width: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Color.fromRGBO(63, 62, 62, 1),
            border: Border.all(color: Appcolor.grey.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              "$amount",
              style: TextStyle(
                color: Appcolor.secondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}