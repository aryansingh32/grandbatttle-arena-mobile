import 'package:intl/intl.dart';

// A nested class to represent a single participant in the tournament.
class Participant {
  final int slotNumber;
  final String playerName;

  Participant({
    required this.slotNumber,
    required this.playerName,
  });

  // Factory constructor to create a Participant from a JSON object.
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      slotNumber: json['slotNumber'],
      playerName: json['playerName'],
    );
  }
}

// The main model for tournament data, updated to include all necessary fields.
class TournamentModel {
  final int id;
  final String title; // Renamed from 'name' for consistency.
  final int prizePool;
  final int entryFee;
  final String? imageUrl; // Renamed from 'imageLink'.
  final String? map; // Made nullable to match UI logic.
  final String game;
  final int maxPlayers;
  final DateTime startTime;
  final String teamSize;
  final String status;
  final String? gameId;
  final String? gamePassword;
  final int registeredPlayers; // Added field.
  final List<String> rules; // Added field.
  final List<Participant> participants; // Added field for registered players list.


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
    required this.registeredPlayers,
    required this.rules,
    required this.participants,
    this.gameId,
    this.gamePassword,
  });

  // Getter to format the startTime into a readable string for the UI.
  // Example output: "Aug 19, 2025, 3:41 PM"
  String get dateTimeFormatted {
    // Using the intl package for robust date and time formatting.
    return DateFormat('MMM d, yyyy, h:mm a').format(startTime);
  }

  // Updated factory constructor to parse the full JSON response from the API.
  // In tournament_model.dart

factory TournamentModel.fromJson(Map<String, dynamic> json) {
  // Parse lists safely, initializing them as empty if they are missing.
  var participantsList = <Participant>[];
  if (json['participants'] != null) {
    participantsList = (json['participants'] as List)
        .map((p) => Participant.fromJson(p))
        .toList();
  }

  var rulesList = <String>[];
  if (json['rules'] != null) {
    rulesList = List<String>.from(json['rules']);
  }

  return TournamentModel(
    id: json['id'],
    
    // Fallback for title/name
    title: json['title'] ?? json['name'] ?? 'Untitled Tournament',
    
    prizePool: json['prizePool'] ?? 0,
    entryFee: json['entryFee'] ?? 0,
    imageUrl: json['imageUrl'] ?? json['imageLink'],
    map: json['map'], // This is nullable (String?), so it's safe without a default.

    // Provide default values for all required fields
    game: json['game'] ?? 'Unknown Game',
    maxPlayers: json['maxPlayers'] ?? 0,
    
    // Safely parse DateTime
    startTime: json['startTime'] != null
        ? DateTime.parse(json['startTime'])
        : DateTime.now(),
        
    // This is the line that will fix your current crash
    teamSize: json['teamSize'] ?? 'TBD',
    
    status: json['status'] ?? 'UNKNOWN',
    registeredPlayers: json['registeredPlayers'] ?? 0,
    
    // Assign the safely parsed lists
    rules: rulesList,
    participants: participantsList,
  );
}}