class UserModel {
  final String firebaseUserUID;
  final String userName;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  UserModel({
    required this.firebaseUserUID,
    required this.userName,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firebaseUserUID: json['firebaseUserUID'],
      userName: json['userName'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
