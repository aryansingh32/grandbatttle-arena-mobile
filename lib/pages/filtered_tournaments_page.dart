import 'package:flutter/material.dart';
import 'package:grand_battle_arena/items/tournamentcard.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:shimmer/shimmer.dart';

class FilteredTournamentsPage extends StatefulWidget {
  final String filterQuery;
  final String? filterType;

  const FilteredTournamentsPage({super.key, required this.filterQuery, this.filterType});

  @override
  State<FilteredTournamentsPage> createState() => _FilteredTournamentsPageState();
}

class _FilteredTournamentsPageState extends State<FilteredTournamentsPage> {
  List<TournamentModel> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      final allTournaments = await ApiService.getAllTournaments();
      
      final query = widget.filterQuery.toLowerCase();
      final type = widget.filterType;

      final filtered = allTournaments.where((t) {
        // If specific type is provided, filter strictly by that
        if (type == 'game') {
          return t.game.toLowerCase().contains(query);
        } else if (type == 'teamSize') {
          return t.teamSize.toLowerCase() == query; // Exact match for team size usually better
        }

        // Fallback to general search if no type provided
        final game = t.game.toLowerCase();
        final map = t.map?.toLowerCase() ?? '';
        final title = t.title.toLowerCase();
        final teamSize = t.teamSize.toLowerCase();
        
        return game.contains(query) || 
               map.contains(query) || 
               title.contains(query) ||
               teamSize.contains(query);
      }).toList();

      if (mounted) {
        setState(() {
          _tournaments = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tournaments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.filterQuery,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: _isLoading
          ? _buildShimmerList()
          : _tournaments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tournaments found for "${widget.filterQuery}"',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = _tournaments[index];
                    return TournamentCard(
                      tournamentId: tournament.id,
                      imageUrl: tournament.imageUrl ?? 'assets/images/pubg.png',
                      title: tournament.title,
                      dateTime: tournament.dateTimeFormatted,
                      prize: tournament.prizePool.toString(),
                      entry: tournament.entryFee.toString(),
                      teamSize: tournament.teamSize,
                      enrolled: '${tournament.registeredPlayers}/${tournament.maxPlayers}',
                      map: tournament.map ?? 'Random',
                      game: tournament.game,
                      onRegister: () {
                         Navigator.pushNamed(
                          context,
                          '/tournament-detail',
                          arguments: tournament.id,
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).cardColor,
            highlightColor: Theme.of(context).cardColor.withOpacity(0.5),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
