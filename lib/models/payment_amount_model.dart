class PaymentAmountModel {
  final int amount;
  final int coins;
  final String currency;

  PaymentAmountModel({
    required this.amount,
    required this.coins,
    this.currency = 'INR',
  });

  factory PaymentAmountModel.fromJson(Map<String, dynamic> json) {
    return PaymentAmountModel(
      amount: json['amount'] as int,
      coins: json['coins'] as int,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'coins': coins,
      'currency': currency,
    };
  }
}
