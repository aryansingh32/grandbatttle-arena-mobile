class TransactionModel {
  final int id;
  final String firebaseUserUID;
  final String transactionUID;
  final int amount;
  final String type;
  final String status;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.firebaseUserUID,
    required this.transactionUID,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      firebaseUserUID: json['firebaseUserUID'],
      transactionUID: json['transactionUID'],
      amount: json['amount'],
      type: json['type'],
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }
}