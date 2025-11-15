class NotificationModel {
  final int id;
  final String firebaseUserUID;
  final String message;
  final DateTime sentAt;
  
  bool isRead;
  final String? type;
  String? title;
  final String? createdAt;
  Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.firebaseUserUID,
    required this.message,
    required this.sentAt,
    this.isRead = false,
    this.type = 'general',
    this.title,
    this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      firebaseUserUID: json['firebaseUserUID'] ?? '',
      message: json['message'] ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'general',
      title: json['title'],
      createdAt: json['createdAt'],
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  // Create from Firebase RemoteMessage
  factory NotificationModel.fromRemoteMessage(Map<String, dynamic> data, String? title, String? body) {
    return NotificationModel(
      id: data['notificationId'] != null 
          ? int.tryParse(data['notificationId']) ?? DateTime.now().millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      firebaseUserUID: '',
      message: body ?? data['message'] ?? '',
      sentAt: DateTime.now(),
      isRead: false,
      type: data['type'] ?? 'general',
      title: title ?? data['title'],
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUserUID': firebaseUserUID,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'title': title,
      'createdAt': createdAt,
      'data': data,
    };
  }

  // Helper methods for different notification types
  bool get isTournamentCredentials => type == 'tournament_credentials';
  bool get isTournamentReminder => type == 'tournament_reminder';
  bool get isTournamentResult => type == 'tournament_result';
  bool get isTournamentUpdate => type == 'tournament_update';
  bool get isWalletTransaction => type == 'wallet_transaction';
  bool get isRewardDistribution => type == 'reward_distribution';

  // Get tournament specific data
  String? get tournamentId => data?['tournamentId'];
  String? get tournamentName => data?['tournamentName'];
  String? get gameId => data?['gameId'];
  String? get gamePassword => data?['gamePassword'];

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, message: $message)';
  }

  NotificationModel copyWith({
    int? id,
    String? firebaseUserUID,
    String? message,
    DateTime? sentAt,
    bool? isRead,
    String? type,
    String? title,
    String? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      firebaseUserUID: firebaseUserUID ?? this.firebaseUserUID,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}