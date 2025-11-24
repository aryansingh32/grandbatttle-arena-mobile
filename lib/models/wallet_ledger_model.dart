// lib/models/wallet_ledger_model.dart
// Model for wallet transaction ledger entries

class WalletLedgerModel {
  final int id;
  final int walletId;
  final String userId;
  final String direction; // "CREDIT" | "DEBIT"
  final int amount;
  final int balanceAfter;
  final String referenceType; // "BOOKING" | "REFUND" | "ADMIN_ADJUSTMENT" | "TRANSACTION"
  final String referenceId;
  final Map<String, dynamic>? metadata;
  final String createdBy;
  final DateTime createdAt;

  WalletLedgerModel({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    required this.referenceType,
    required this.referenceId,
    this.metadata,
    required this.createdBy,
    required this.createdAt,
  });

  factory WalletLedgerModel.fromJson(Map<String, dynamic> json) {
    return WalletLedgerModel(
      id: json['id'] as int,
      walletId: json['walletId'] as int,
      userId: json['userId'] as String,
      direction: json['direction'] as String,
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      referenceType: json['referenceType'] as String,
      referenceId: json['referenceId'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'direction': direction,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'metadata': metadata,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

