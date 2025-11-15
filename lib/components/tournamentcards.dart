import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/tournamentdetails.dart';
import 'package:grand_battle_arena/items/tournamentcard.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';

class TournamentCards extends StatefulWidget {
  const TournamentCards({super.key});

  @override
  State<TournamentCards> createState() => _TournamentCardsState();
}

class _TournamentCardsState extends State<TournamentCards> {
  List<TournamentModel> tournaments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final tournamentList = await ApiService.getUpcomingTournaments();
      if (mounted) {
      setState(() {
        tournaments = tournamentList.take(2).toList(); // Show only first 2 for home page
        isLoading = false;
      });}
    } catch (e) {
      if (mounted) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });}
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tournaments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            "Upcoming Tournaments",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 25,
              letterSpacing: 0.5,
              color: Appcolor.white,
            ),
          ),
        ),
        
        // Loading state
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Appcolor.secondary,
              ),
            ),
          )
        
        // Error state
        else if (error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load tournaments',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadTournaments,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        
        // Empty state
        else if (tournaments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No upcoming tournaments',
                style: TextStyle(
                  color: Appcolor.grey,
                  fontSize: 16,
                ),
              ),
            ),
          )
        
        // Tournament cards
        else
          ...tournaments.map((tournament) => TournamentCard(
            title: tournament.title,
            imageUrl: tournament.imageUrl ?? 'assets/images/freefirebanner4.webp',
            dateTime: tournament.dateTimeFormatted,
            prize: tournament.prizePool.toString(),
            entry: tournament.entryFee.toString(),
            teamSize: tournament.teamSize,
            enrolled: '${tournament.registeredPlayers}/${tournament.maxPlayers}',
            map: tournament.map ?? 'Unknown Map',
            game: tournament.game,
            onRegister: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailsPage(
                  tournamentId: tournament.id,
                ),
              ),
            ),
          )).toList(),
        
        // View more button
        Center(
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/tournament'),
            child: const Text(
              "View More..",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 10,
                letterSpacing: 1,
                color: Appcolor.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}