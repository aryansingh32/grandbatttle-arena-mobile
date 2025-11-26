import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/components/registertournament.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/services/booking_refresh_notifier.dart';
import 'package:grand_battle_arena/utils/toast_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:palette_generator/palette_generator.dart';

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
  int selectedTab = 0; // 0=Rules,1=Participants,2=Scoreboard
  TournamentModel? tournament;
  bool isLoading = true;
  String? error;
  String _scoreFilter = 'All';
  String? _currentUserUid;
  bool _userHasBooking = false;
  List<ParticipantModel> _userParticipants = [];
  
  // Dynamic Background State
  List<Color> _bgColors = [Appcolor.primary, Colors.black];
  int _colorIndex = 0;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    _loadTournamentDetails();
    _startBackgroundAnimation();
  }

  void _startBackgroundAnimation() {
    _animationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _colorIndex = (_colorIndex + 1) % 2;
        });
      }
    });
  }

  Future<void> _updatePalette() async {
    if (tournament?.imageUrl == null) return;
    try {
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(tournament!.imageUrl!),
        size: const Size(200, 100), // Resize for speed
      );
      
      if (mounted) {
        setState(() {
          final darkMuted = generator.darkMutedColor?.color ?? Appcolor.primary;
          final darkVibrant = generator.darkVibrantColor?.color ?? Colors.black;
          final dominant = generator.dominantColor?.color ?? Appcolor.cardsColor;
          
          // Create a rich, dark gradient palette
          _bgColors = [
            darkMuted.withOpacity(0.8),
            darkVibrant.withOpacity(0.6),
            dominant.withOpacity(0.4),
            Colors.black
          ];
        });
      }
    } catch (e) {
      debugPrint("Error generating palette: $e");
    }
  }

  void _evaluateUserBooking(TournamentModel data) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final mine = data.participants.where((p) => p.userId == uid).toList();
    setState(() {
      _currentUserUid = uid;
      _userHasBooking = mine.isNotEmpty;
      _userParticipants = mine;
    });
  }

  Future<void> _loadTournamentDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      

      // FIX: Use authenticated endpoint to get rules, participants, and scoreboard
      // The public endpoint (/api/public/tournaments/{id}) doesn't include these fields
      // The authenticated endpoint (/api/tournaments/{id}) includes all tournament data
      final tournamentData = await ApiService.getTournamentDetails(widget.tournamentId);
      
      setState(() {
        // Temporary test for Spectator Mode
        // tournament = tournamentData.copyWith(streamUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ");
        tournament = tournamentData; // Uncomment this and remove above line for production
        
        isLoading = false;
      });
      
      // Trigger palette update after data load
      _updatePalette();
      
      _evaluateUserBooking(tournamentData);
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

  YoutubePlayerController? _youtubeController;

  @override
  void dispose() {
    _animationTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _initializeYoutubePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
        ),
      );
    }
  }

  Widget _buildYoutubePlayer() {
    if (_youtubeController == null && tournament?.streamUrl != null) {
      _initializeYoutubePlayer(tournament!.streamUrl!);
    }

    if (_youtubeController == null) return _buildHeaderImage();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Appcolor.secondary,
          progressColors: const ProgressBarColors(
            playedColor: Appcolor.secondary,
            handleColor: Appcolor.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      child: Stack(
        children: [
          // Background gaming character image OR YouTube Player
          Positioned.fill(
            child: (tournament?.streamUrl != null && tournament!.streamUrl!.isNotEmpty)
                ? _buildYoutubePlayer()
                : _buildHeaderImage(),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Glass effect
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          // Share button
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () {
                if (tournament != null) {
                  Share.share(
                    'Join me in the ${tournament!.title} tournament on Grand Battle Arena! 🎮\n\nPrize Pool: ${tournament!.prizePool}\nEntry: ${tournament!.entryFee}\n\nRegister now: https://grandbattlearena.com/tournament/${tournament!.id}',
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Glass effect
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          // Game name text overlay (Only show if NOT playing video)
          if (tournament?.streamUrl == null || tournament!.streamUrl!.isEmpty)
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
    );
  }

  Widget _buildHeaderImage() {
    return Hero(
      tag: 'tournament_img_${widget.tournamentId}',
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
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Appcolor.primary,
      body: AnimatedContainer(
        duration: const Duration(seconds: 4),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _colorIndex == 0 ? Alignment.topLeft : Alignment.bottomRight,
            end: _colorIndex == 0 ? Alignment.bottomRight : Alignment.topLeft,
            colors: _bgColors.length >= 2 
                ? [_bgColors[0], _bgColors[1]] 
                : [Theme.of(context).scaffoldBackgroundColor, Colors.black],
          ),
        ),
        child: isLoading 
          ? _buildLoadingState()
          : error != null 
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.secondary,
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
        _buildHeaderSection(context),

        // Tournament details section
        Expanded(
          child: SingleChildScrollView(
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
                        Text(
                          'Prize Pool',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
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
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
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

                _buildPrizeBreakdown(),
                if (_userHasBooking && (tournament?.hasCredentials ?? false))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _buildCredentialCard(),
                  ),
                if (_userHasBooking && _userParticipants.isNotEmpty)
                  _buildUserSlotSummary(),

                // Rules and Participants tabs
                Row(
                  children: [
                    _buildTabButton('Rules', 0),
                    const SizedBox(width: 16),
                    _buildTabButton('Participants', 1),
                    const SizedBox(width: 16),
                    _buildTabButton('Scoreboard', 2),
                  ],
                ),

                const SizedBox(height: 20),

                // Content based on selected tab
                _buildTabBody(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody() {
    if (selectedTab == 0) return _buildRulesContent();
    if (selectedTab == 1) return _buildParticipantsContent();
    return _buildScoreboardContent();
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFFFD700) : const Color(0xFF888888),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 2,
            color: isActive ? const Color(0xFFFFD700) : Colors.transparent,
          ),
        ],
      ),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tournament!.participants.length,
      itemBuilder: (context, i) {
        final participant = tournament!.participants[i];
        final isMe = participant.userId != null &&
            participant.userId!.isNotEmpty &&
            participant.userId == _currentUserUid;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Appcolor.secondary.withOpacity(0.15) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMe ? Appcolor.secondary : const Color(0xFF333333),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isMe ? Appcolor.secondary : const Color(0xFF333333),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    participant.playerName.isNotEmpty
                        ? participant.playerName[0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      color: isMe ? Appcolor.primary : Colors.white,
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
                  color: isMe ? Appcolor.secondary : const Color(0xFF0F5132),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMe ? 'You' : 'Joined',
                  style: TextStyle(
                    color: isMe ? Appcolor.primary : const Color(0xFF75B798),
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

  Widget _buildPrizeBreakdown() {
    if (tournament == null) return const SizedBox.shrink();
    final killReward = tournament!.perKillCoins;
    final first = tournament!.firstPlacePrize;
    final second = tournament!.secondPlacePrize;
    final third = tournament!.thirdPlacePrize;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards Breakdown',
            style: const TextStyle(
              color: Appcolor.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _rewardPill('Per Kill', '+$killReward'),
              _rewardPill('1st Place', first.toString()),
              _rewardPill('2nd Place', second.toString()),
              _rewardPill('3rd Place', third.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rewardPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).primaryColor.withOpacity(0.4),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Appcolor.grey,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Image.asset("assets/icons/dollar.png", height: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Appcolor.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Credentials',
            style: const TextStyle(
              color: Appcolor.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _credentialRow('Room ID', tournament!.gameId ?? '-'),
          const SizedBox(height: 8),
          _credentialRow('Password', tournament!.gamePassword ?? '-'),
        ],
      ),
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Appcolor.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Appcolor.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copy $label',
          onPressed: value.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: value));
                  ToastUtils.showPremiumToast(context, '$label copied');
                },
          icon: const Icon(Icons.copy, color: Appcolor.secondary, size: 18),
        ),
      ],
    );
  }

  Widget _buildUserSlotSummary() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _userParticipants.map((p) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Appcolor.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Appcolor.secondary),
            ),
            child: Text(
              'Your Slot ${p.slotNumber}',
              style: const TextStyle(
                color: Appcolor.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreboardContent() {
    final scores = tournament?.scoreboard ?? [];

    if (scores.isEmpty) {
      return const Center(
        child: Text(
          'Scoreboard will appear once admins publish match data.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final filtered = _scoreFilter == 'Top 3'
        ? scores.take(3).toList()
        : scores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Score Card',
              style: TextStyle(color: Appcolor.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              dropdownColor: Appcolor.cardsColor,
              value: _scoreFilter,
              style: const TextStyle(color: Appcolor.white),
              underline: SizedBox(),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Players')),
                DropdownMenuItem(value: 'Top 3', child: Text('Top 3')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _scoreFilter = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Each kill grants ${tournament?.perKillCoins ?? 0} coins.',
            style: const TextStyle(color: Appcolor.grey, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = filtered[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Appcolor.cardsColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Appcolor.secondary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Appcolor.secondary.withOpacity(0.2),
                    child: Text(
                      '#${entry.placement}',
                      style: const TextStyle(color: Appcolor.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.playerName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(
                          'Team ${entry.teamName}',
                          style: const TextStyle(color: Appcolor.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${entry.kills} Kills',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Image.asset("assets/icons/dollar.png", height: 14),
                          const SizedBox(width: 4),
                          Text(
                            '+${entry.coinsEarned}',
                            style: const TextStyle(color: Appcolor.secondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
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
              onTap: () async {
                final joined = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentRegistrationPage(
                      tournamentId: widget.tournamentId,
                      tournament: tournament,
                    ),
                  ),
                );
                if (joined == true) {
                  await _loadTournamentDetails();
                  if (mounted) {
                    context.read<BookingRefreshNotifier>().ping();
                  }
                }
              },
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