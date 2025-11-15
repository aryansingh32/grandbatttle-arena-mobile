class AvailableAmount {
  final int amount;
  final int coins;

  AvailableAmount({
    required this.amount,
    required this.coins,
  });

  factory AvailableAmount.fromJson(Map<String, dynamic> json) {
    return AvailableAmount(
      amount: json['amount'] as int,
      coins: json['coins'] as int,
    );
  }
}