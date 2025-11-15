// lib/models/slots_model.dart

import 'package:intl/intl.dart';


class SlotsModel {
  final int id;
  final int tournamentId;
  final int slotNumber;
  final String? firebaseUserUID; // Nullable as it's only present when booked
  final String? playerName;      // Nullable as it's only present when booked
  final String status;           // e.g., "AVAILABLE" or "BOOKED"
  final DateTime? bookedAt;      // Nullable as it's only present when booked

  SlotsModel({
    required this.id,
    required this.tournamentId,
    required this.slotNumber,
    this.firebaseUserUID,
    this.playerName,
    required this.status,
    this.bookedAt,
  });

  /// **ADDED**: A convenience getter to check if the slot is booked.
  /// This is used in your ParticipantsBottomSheet.
  bool get isBooked => status.toUpperCase() == 'BOOKED';

  /// **FIXED**: This getter now safely handles cases where bookedAt might be null.
  String get dateTimeFormatted {
    if (bookedAt == null) {
      return 'N/A';
    }
    // Using the intl package for robust date and time formatting.
    return DateFormat('MMM d, yyyy, h:mm a').format(bookedAt!);
  }

  /// **FIXED**: The factory constructor now correctly parses the JSON from your backend DTO.
  factory SlotsModel.fromJson(Map<String, dynamic> json) {
    return SlotsModel(
      id: json['id'],
      tournamentId: json['tournamentId'],
      slotNumber: json['slotNumber'],
      firebaseUserUID: json['firebaseUserUID'],
      playerName: json['playerName'],
      status: json['status'],
      // 1. Corrected JSON key from 'bookedAt' to 'booked_at'.
      // 2. Correctly handles the value being null if the slot is not booked.
      bookedAt: json['booked_at'] != null
          ? DateTime.parse(json['booked_at'])
          : null,
    );
  }
}