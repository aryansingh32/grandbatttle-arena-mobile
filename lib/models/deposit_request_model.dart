class DepositRequestModel {
  final String transactionUID;
  final int amount;

  DepositRequestModel({
    required this.transactionUID,
    required this.amount,
  });

  /// Converts this object to a JSON format for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'transactionUID': transactionUID,
      'amount': amount,
    };
  }
}
