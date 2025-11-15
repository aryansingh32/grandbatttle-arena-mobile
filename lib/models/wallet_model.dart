class WalletModel {
  final int id;
  final String firebaseUserUID;
  final int coins;
  final DateTime lastUpdated;

  WalletModel({
    required this.id,
    required this.firebaseUserUID,
    required this.coins,
    required this.lastUpdated,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      firebaseUserUID: json['firebaseUserUID'],
      coins: json['coins'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
