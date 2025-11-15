import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/registertournament.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';

class TournamentDetailsPage extends StatefulWidget {
  final int tournamentId;
  
  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  int selectedTab = 0; // 0 for Rules, 1 for Participants
  TournamentModel? tournament;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTournamentDetails();
  }

  Future<void> _loadTournamentDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final tournamentData = await ApiService.getTournamentById(widget.tournamentId);
      
      setState(() {
        tournament = tournamentData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tournament: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Appcolor.primary,
      body: isLoading 
        ? _buildLoadingState()
        : error != null 
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Appcolor.secondary,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            'Failed to load tournament details',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTournamentDetails,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (tournament == null) return _buildErrorState();

    return Column(
      children: [
        // Header with back button and tournament image
        Container(
          height: 400,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 46, 26, 43),
                Color.fromARGB(255, 62, 22, 22),
                Appcolor.primary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background gaming character image
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: tournament!.imageUrl != null 
                        ? NetworkImage(tournament!.imageUrl!)
                        : const AssetImage("assets/images/freefirebanner4.webp") as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: 40,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Appcolor.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Game name text overlay
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    tournament!.game.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: const Color.fromARGB(214, 0, 0, 0),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tournament details section
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament title and prize
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament!.title,
                            style: const TextStyle(
                              color: Appcolor.white,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tournament!.dateTimeFormatted,
                            style: const TextStyle(
                              color: Appcolor.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Prize Pool',
                          style: TextStyle(
                            color: Appcolor.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Appcolor.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset("assets/icons/dollar.png"),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tournament!.prizePool.toString(),
                              style: const TextStyle(
                                color: Appcolor.secondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tournament stats row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Entry/Player',
                          tournament!.entryFee.toString(),
                          const AssetImage("assets/icons/dollar.png"),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 35,
                        color: Appcolor.grey,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Team Size',
                          tournament!.teamSize,
                          const AssetImage("assets/icons/swords.png"),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 35,
                        color: Appcolor.grey,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Enrolled',
                          '${tournament!.registeredPlayers}/${tournament!.maxPlayers}',
                          const AssetImage("assets/icons/people.png"),
                          showProgress: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Rules and Participants tabs
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => selectedTab = 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rules',
                            style: TextStyle(
                              color: selectedTab == 0
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF888888),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 35,
                            height: 2,
                            color: selectedTab == 0
                                ? const Color(0xFFFFD700)
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    GestureDetector(
                      onTap: () => setState(() => selectedTab = 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participants',
                            style: TextStyle(
                              color: selectedTab == 1
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF888888),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 75,
                            height: 2,
                            color: selectedTab == 1
                                ? const Color(0xFFFFD700)
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Content based on selected tab
                Expanded(
                  child: selectedTab == 0
                      ? _buildRulesContent()
                      : _buildParticipantsContent(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    ImageProvider img, {
    bool showProgress = false,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2),
              child: Image(
                image: img,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Appcolor.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRulesContent() {
    if (tournament?.rules == null || tournament!.rules.isEmpty) {
      return const Center(
        child: Text(
          'No rules available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < tournament!.rules.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRuleItem(
                '${i + 1}.',
                tournament!.rules[i],
                '', // You can split the rule into title and description if needed
              ),
            ),
          const SizedBox(height: 80), // Space for button
        ],
      ),
    );
  }

  Widget _buildParticipantsContent() {
    if (tournament?.participants == null || tournament!.participants.isEmpty) {
      return const Center(
        child: Text(
          'No participants yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tournament!.participants.length,
      itemBuilder: (context, i) {
        final participant = tournament!.participants[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    participant.playerName.isNotEmpty 
                        ? participant.playerName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Slot ${participant.slotNumber}',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Joined',
                  style: TextStyle(
                    color: Color(0xFF75B798),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Bottom join button and prize info
  Widget get bottomNavigationBar {
    if (tournament == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(
            color: const Color.fromRGBO(51, 51, 51, 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentRegistrationPage(
                    tournamentId: widget.tournamentId,
                    tournament: tournament,
                    // config: TournamentConfig.fromTournamentModel(tournament!),
                  ),
                ),
              ),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: tournament!.registeredPlayers >= tournament!.maxPlayers
                      ? Colors.grey
                      : Appcolor.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    tournament!.registeredPlayers >= tournament!.maxPlayers
                        ? 'Tournament Full'
                        : 'Join Now',
                    style: TextStyle(
                      color: tournament!.registeredPlayers >= tournament!.maxPlayers
                          ? Colors.white
                          : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entry Fee',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF666666),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset("assets/icons/dollar.png"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tournament!.entryFee.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}