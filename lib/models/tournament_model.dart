// lib/models/tournament_model.dart
// FIXED VERSION - Robust team size parsing

import 'score_entry.dart';

class TournamentModel {
  final int id;
  final String title;
  final int prizePool;
  final int entryFee;
  final String? imageUrl;
  final String? map;
  final String game;
  final int maxPlayers;
  final DateTime startTime;
  final String teamSize; // "Solo", "Duo", "Squad", "Hexa"
  final String status;
  final String? gameId;
  final String? gamePassword;
  final List<String> rules;
  final int registeredPlayers;
  final List<ParticipantModel> participants;
  final List<ScoreEntry> scoreboard; // CHANGE: expose per-player earnings for scorecards.
  final int? perKillReward;
  final int? firstPrize;
  final int? secondPrize;
  final int? thirdPrize;

  TournamentModel({
    required this.id,
    required this.title,
    required this.prizePool,
    required this.entryFee,
    this.imageUrl,
    this.map,
    required this.game,
    required this.maxPlayers,
    required this.startTime,
    required this.teamSize,
    required this.status,
    this.gameId,
    this.gamePassword,
    this.rules = const [],
    this.registeredPlayers = 0,
    this.participants = const [],
    this.scoreboard = const [],
    this.perKillReward,
    this.firstPrize,
    this.secondPrize,
    this.thirdPrize,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    // CRITICAL FIX: Parse team size with comprehensive handling
    final rawTeamSize =
        json['teamSize'] ?? json['team_type'] ?? json['teamType'] ?? json['team_size'];
    String parsedTeamSize = _parseTeamSize(rawTeamSize);
    
    print('✅ Tournament ${json['id']}: teamSize="${json['teamSize']}" → "$parsedTeamSize"');

    return TournamentModel(
      id: json['id'] as int,
      title: json['name'] as String,
      prizePool: json['prizePool'] as int,
      entryFee: json['entryFee'] as int,
      imageUrl: json['imageLink'] as String?,
      map: json['map'] as String?,
      game: json['game'] as String,
      maxPlayers: json['maxPlayers'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      teamSize: parsedTeamSize,
      status: json['status'] as String,
      gameId: json['gameId'] as String?,
      gamePassword: json['gamePassword'] as String?,
      rules: _parseRules(json['rules']),
      registeredPlayers: _calculateRegisteredPlayers(json),
      participants: _parseParticipants(json['participants']),
      scoreboard: _parseScoreboard(json['scoreboard']),
      perKillReward: json['perKillReward'] as int?,
      firstPrize: json['firstPrize'] as int?,
      secondPrize: json['secondPrize'] as int?,
      thirdPrize: json['thirdPrize'] as int?,
    );
  }

  // CRITICAL: Comprehensive team size parser
  static String _parseTeamSize(dynamic teamSizeValue) {
    if (teamSizeValue == null) {
      print('⚠️ teamSize is NULL - defaulting to Solo');
      return 'Solo';
    }

    // Convert to string and normalize
    String teamSizeStr = teamSizeValue.toString().trim().toUpperCase();
    
    // Map all possible values from backend
    const Map<String, String> teamSizeMap = {
      'SOLO': 'Solo',
      'SOLO1': 'Solo',
      '1': 'Solo',
      'DUO': 'Duo',
      'DUO2': 'Duo',
      '2': 'Duo',
      'SQUAD': 'Squad',
      'SQUAD4': 'Squad',
      '4': 'Squad',
      'HEXA': 'Hexa',
      'HEXA6': 'Hexa',
      '6': 'Hexa',
    };

    String result = teamSizeMap[teamSizeStr] ?? 'Solo';
    if (!teamSizeMap.containsKey(teamSizeStr)) {
      print('⚠️ Unknown teamSize: "$teamSizeValue" - defaulting to Solo');
    }
    
    return result;
  }

  static List<String> _parseRules(dynamic rulesData) {
    if (rulesData == null) return [];
    if (rulesData is List) {
      return rulesData.map((r) => r.toString()).toList();
    }
    return [];
  }

  static int _calculateRegisteredPlayers(Map<String, dynamic> json) {
    if (json.containsKey('registeredPlayers')) {
      return json['registeredPlayers'] as int;
    }
    if (json.containsKey('participants') && json['participants'] is List) {
      return (json['participants'] as List).length;
    }
    return 0;
  }

  static List<ParticipantModel> _parseParticipants(dynamic participantsData) {
    if (participantsData == null) return [];
    if (participantsData is List) {
      return participantsData
          .map((p) => ParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<ScoreEntry> _parseScoreboard(dynamic data) {
    if (data == null || data is! List) return const [];
    return data
        .map((entry) => ScoreEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  // Getters for team configuration
  int get playersPerTeam {
    switch (teamSize.toLowerCase()) {
      case 'solo':
        return 1;
      case 'duo':
        return 2;
      case 'squad':
        return 4;
      case 'hexa':
        return 6;
      default:
        print('⚠️ Unknown teamSize in getter: $teamSize, defaulting to 1');
        return 1;
    }
  }

  int get totalTeams => maxPlayers ~/ playersPerTeam;

  bool get isSolo => teamSize.toLowerCase() == 'solo';
  bool get isDuo => teamSize.toLowerCase() == 'duo';
  bool get isSquad => teamSize.toLowerCase() == 'squad';
  bool get isHexa => teamSize.toLowerCase() == 'hexa';
  bool get isFull => registeredPlayers >= maxPlayers;

  String get dateTimeFormatted {
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    
    final month = months[startTime.month - 1];
    final day = startTime.day;
    final hour = startTime.hour % 12 == 0 ? 12 : startTime.hour % 12;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $hour:$minute $period IST';
  }

  bool get hasCredentials => 
      gameId != null && 
      gameId!.isNotEmpty && 
      gamePassword != null && 
      gamePassword!.isNotEmpty;

  Duration get timeUntilStart => startTime.difference(DateTime.now());
  bool get hasStarted => timeUntilStart.isNegative;
  bool get isUpcoming => !hasStarted && status.toUpperCase() == 'UPCOMING';
  bool get hasScoreboard => scoreboard.isNotEmpty;
  int get perKillCoins => perKillReward ?? 5;
  int get firstPlacePrize => firstPrize ?? (prizePool ~/ 2);
  int get secondPlacePrize => secondPrize ?? (prizePool ~/ 3);
  int get thirdPlacePrize => thirdPrize ?? (prizePool ~/ 5);

  @override
  String toString() {
    return 'Tournament(id: $id, title: $title, teamSize: "$teamSize", playersPerTeam: $playersPerTeam)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TournamentModel &&
        other.id == id &&
        other.registeredPlayers == registeredPlayers &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, registeredPlayers, status);
}

class ParticipantModel {
  final String playerName;
  final int slotNumber;
  final String? userId;

  ParticipantModel({
    required this.playerName,
    required this.slotNumber,
    this.userId,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      playerName: json['playerName'] as String,
      slotNumber: json['slotNumber'] as int,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'slotNumber': slotNumber,
      'userId': userId,
    };
  }
}