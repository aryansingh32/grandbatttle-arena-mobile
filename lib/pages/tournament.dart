import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/tournamentcard.dart';
import 'package:grand_battle_arena/components/tournamentdetails.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/filter_provider.dart'; // CHANGE: share filters with home quick chips.

// Tournament data model
class Tournament {
  final String id;
  final String imageUrl;
  final String title;
  final String dateTime;
  final String prize;
  final String entry;
  final String teamSize;
  final String enrolled;
  final String map;
  final String game;
  final String gameType; // For filtering
  final String timeSlot; // For time slot filtering
  final bool isActive;

  Tournament({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.dateTime,
    required this.prize,
    required this.entry,
    required this.teamSize,
    required this.enrolled,
    required this.map,
    required this.game,
    required this.gameType,
    required this.timeSlot,
    this.isActive = true,
  });
}

class TournamentContent extends StatefulWidget {
  @override
  State<TournamentContent> createState() => _TournamentContentState();
}

class _TournamentContentState extends State<TournamentContent> {
  // API tournament data
  List<TournamentModel> apiTournaments = [];
  bool _isApiLoading = true;

  // Dynamic filter options (can be updated from admin dashboard)
  List<String> gameFilters = ["All", "Free Fire", "PUBG", "COD Mobile", "Valorant"];
  List<String> timeSlots = ["All", "6:00-6:30", "7:00-7:30", "7:00-8:00", "8:00-8:30"];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      if (!mounted) return;
      setState(() => _isApiLoading = true);
      final tournaments = await ApiService.getAllTournaments();
      if (!mounted) return;
      setState(() {
        apiTournaments = tournaments;
        _isApiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApiLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tournaments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 120), // Space for nav bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Tournaments",
                style: TextStyle(
                  color: Appcolor.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            // Filters Section
            _buildFiltersSection(),

            // Tournament List
            Expanded(
              child: _buildTournamentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Filter
          Row(
            children: [
              Text(
                "Filter",
                style: TextStyle(
                  color: Appcolor.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Consumer<FilterProvider>(
                    builder: (context, filters, _) {
                      return Row(
                        children: gameFilters.map((filter) {
                          bool isSelected = filters.gameFilter == filter;
                          return GestureDetector(
                            onTap: () => filters.setGameFilter(filter),
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Appcolor.secondary : Color.fromRGBO(63, 62, 62, 1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Appcolor.secondary : Appcolor.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Appcolor.primary : Appcolor.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Time Slots Filter
          Row(
            children: [
              Text(
                "Time Slots",
                style: TextStyle(
                  color: Appcolor.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Consumer<FilterProvider>(
                    builder: (context, filters, _) {
                      return Row(
                        children: timeSlots.map((slot) {
                          bool isSelected = filters.timeSlotFilter == slot;
                          return GestureDetector(
                            onTap: () => filters.setTimeSlotFilter(slot),
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Appcolor.secondary : Color.fromRGBO(63, 62, 62, 1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Appcolor.secondary : Appcolor.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                slot,
                                style: TextStyle(
                                  color: isSelected ? Appcolor.primary : Appcolor.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTournamentList() {
    final filters = context.watch<FilterProvider>();
    if (_isApiLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => TournamentCard(
          imageUrl: "",
          title: "",
          dateTime: "",
          prize: "",
          entry: "",
          teamSize: "",
          enrolled: "",
          map: "",
          game: "",
          onRegister: () {},
          isLoading: true,
        ),
      );
    }

    final tournaments = apiTournaments
        .where((tournament) => tournament.status == "UPCOMING")
        .where(filters.matchesTournament)
        .toList();

    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ac_unit_sharp,
              size: 64,
              color: Appcolor.grey,
            ),
            SizedBox(height: 16),
            Text(
              "No tournaments found",
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try adjusting your filters",
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Inside _buildTournamentList method in tournament.dart

    return ListView.builder(
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        TournamentModel tournament = tournaments[index];
        return TournamentCard(
          imageUrl: tournament.imageUrl ?? 'assets/images/freefirebanner4.webp',
          title: tournament.title,
          dateTime: tournament.dateTimeFormatted,
          prize: tournament.prizePool.toString(),
          entry: tournament.entryFee.toString(),
          teamSize: tournament.teamSize,
          enrolled: "${tournament.registeredPlayers}/${tournament.maxPlayers}",
          map: tournament.map ?? "TBD",
          game: tournament.game,
          isDivider: true,
          onRegister: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailsPage(
                  tournamentId: tournament.id,
                ),
              ),
            );
          },
          onViewDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailsPage(
                  tournamentId: tournament.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
  

  String _formatDateTime(DateTime dateTime) {
    // Format: "JUL 22, 5:00 PM IST"
    return "${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  

  // void _navigateToTournamentDetails(TournamentModel tournament) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TournamentDetailsPage(
  //         // Pass tournament if needed
  //       ),
  //     ),
  //   );
  // }

  // Admin functions (for future backend integration)
  // void addTournament(Tournament tournament) {
  //   setState(() {
  //     allTournaments.add(tournament);
  //   });
  // }

  // void removeTournament(String tournamentId) {
  //   setState(() {
  //     allTournaments.removeWhere((t) => t.id == tournamentId);
  //   });
  // }

  // void addGameFilter(String filter) {
  //   setState(() {
  //     if (!gameFilters.contains(filter)) {
  //       gameFilters.add(filter);
  //     }
  //   });
  // }

  // void removeGameFilter(String filter) {
  //   setState(() {
  //     gameFilters.remove(filter);
  //     if (selectedGameFilter == filter) {
  //       selectedGameFilter = "All";
  //     }
  //   });
  // }

  // void addTimeSlot(String slot) {
  //   setState(() {
  //     if (!timeSlots.contains(slot)) {
  //       timeSlots.add(slot);
  //     }
  //   });
  // }

  // void removeTimeSlot(String slot) {
  //   setState(() {
  //     timeSlots.remove(slot);
  //     if (selectedTimeSlot == slot) {
  //       selectedTimeSlot = "All";
  //     }
  //   });
  // }
}