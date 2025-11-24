import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class TournamentBookingCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final DateTime startTime;
  final int prizePool;
  final int tournamentId;
  final bool showTimer;
  final VoidCallback? onDetailsPressed;
  final VoidCallback? onViewParticipants;
  final double? width;
  final double? height;

  const TournamentBookingCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.startTime,
    required this.prizePool,
    required this.tournamentId,
    this.showTimer = true,
    this.onDetailsPressed,
    this.onViewParticipants,
    this.width = 191,
    this.height = 300,
  });

  @override
  State<TournamentBookingCard> createState() => _TournamentBookingCardState();
}

class _TournamentBookingCardState extends State<TournamentBookingCard> {
  // Timer for the countdown UI
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  // Timer for fetching credentials periodically
  Timer? _credentialFetchTimer;

  // State variables for credentials
  String? _gameId;
  String? _gamePassword;
  bool _isLoadingCredentials = false;
  bool _hasFetchedAfterStart = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize countdown timer
    if (widget.showTimer) {
      _updateCountdown();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateCountdown();
      });
    }

    // Start credential fetching logic
    _startCredentialChecks();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _credentialFetchTimer?.cancel();
    super.dispose();
  }

  /// Handles the logic for fetching and updating credentials
  void _startCredentialChecks() {
    // Fetch immediately when widget loads
    _fetchAndSetCredentials();

    // Start periodic timer to check for updates every 30 seconds
    _credentialFetchTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Stop checking if tournament is long over to save resources
      if (DateTime.now().difference(widget.startTime).inHours > 2) {
        timer.cancel();
      } else {
        _fetchAndSetCredentials();
      }
    });
  }

  /// Fetches credentials from API and updates widget state
  Future<void> _fetchAndSetCredentials() async {
    // Prevent multiple simultaneous fetches
    if (_isLoadingCredentials) return;

    setState(() {
      _isLoadingCredentials = true;
    });

    try {
      final credentials = await ApiService.getTournamentCredentials(widget.tournamentId);

      if (!mounted) return;

      // Only update state if credentials have actually changed
      if (credentials['gameId'] != _gameId || credentials['gamePassword'] != _gamePassword) {
        setState(() {
          _gameId = credentials['gameId'];
          _gamePassword = credentials['gamePassword'];
        });
      }
    } on ApiException catch (e) {
      print("Error fetching credentials: ${e.message}");
      // Optionally show error state in UI
    } catch (e) {
      print("Unexpected error fetching credentials: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  /// Updates the countdown timer UI
  void _updateCountdown() {
    if (!mounted) return;

    final now = DateTime.now();
    final difference = widget.startTime.difference(now);

    if (difference.isNegative) {
      // Tournament has started
      if (_timeRemaining != Duration.zero) {
        setState(() => _timeRemaining = Duration.zero);
        _countdownTimer?.cancel(); // Stop countdown timer
      }
      
      // Fetch credentials once after timer ends
      if (!_hasFetchedAfterStart) {
        _fetchAndSetCredentials();
        setState(() {
          _hasFetchedAfterStart = true;
        });
      }
    } else {
      // Tournament hasn't started yet
      setState(() => _timeRemaining = difference);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  String _formatTimer(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return "Started";
    
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied successfully!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildTimerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Appcolor.primary.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatTimer(_timeRemaining),
        style: const TextStyle(
          fontSize: 10,
          color: Appcolor.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGameCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game ID Row
        Row(
          children: [
            Text("ID: ", style: TextStyle(fontSize: 11, color: Appcolor.secondary)),
            Expanded(
              child: Text(
                _gameId ?? "-",
                style: TextStyle(fontSize: 11, color: Appcolor.white),
              ),
            ),
            // Show copy button only if gameId exists and is not empty
            if (_gameId != null && _gameId!.isNotEmpty)
              InkWell(
                onTap: () => _copyToClipboard(_gameId!, "Game ID"),
                child: Icon(Icons.copy, size: 12, color: Appcolor.secondary),
              ),
          ],
        ),
        const SizedBox(height: 2),
        // Game Password Row
        Row(
          children: [
            Text("Pass: ", style: TextStyle(fontSize: 11, color: Appcolor.secondary)),
            Expanded(
              child: Text(
                _gamePassword ?? "-",
                style: TextStyle(fontSize: 11, color: Appcolor.white),
              ),
            ),
            // Show copy button only if gamePassword exists and is not empty
            if (_gamePassword != null && _gamePassword!.isNotEmpty)
              InkWell(
                onTap: () => _copyToClipboard(_gamePassword!, "Password"),
                child: Icon(Icons.copy, size: 12, color: Appcolor.secondary),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have valid credentials
    final hasValidCredentials = (_gameId?.isNotEmpty ?? false) || (_gamePassword?.isNotEmpty ?? false);
    final isTournamentLive = _timeRemaining == Duration.zero;
    final shouldShowTimer = widget.showTimer && _timeRemaining > Duration.zero;
    final usesNetworkImage = Uri.tryParse(widget.imageUrl)?.hasScheme ?? false;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Appcolor.cardsColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Timer Overlay
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  usesNetworkImage
                      ? Image.network(
                          widget.imageUrl,
                          width: double.infinity,
                          height: 108,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 108,
                              color: Appcolor.primary.withOpacity(0.3),
                              child: const Icon(Icons.image_not_supported, color: Appcolor.grey, size: 40),
                            );
                          },
                        )
                      : Image.asset(
                          widget.imageUrl,
                          width: double.infinity,
                          height: 108,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 108,
                              color: Appcolor.primary.withOpacity(0.3),
                              child: const Icon(Icons.image_not_supported, color: Appcolor.grey, size: 40),
                            );
                          },
                        ),
                  // Show timer only when tournament hasn't started
                  if (shouldShowTimer)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildTimerWidget(),
                    ),
                ],
              ),
            ),
            
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tournament Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 11, 
                        color: Appcolor.white, 
                        fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Date and Prize Pool Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDateTime(widget.startTime),
                            style: TextStyle(fontSize: 11, color: Appcolor.grey),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "Prize Pool",
                              style: TextStyle(
                                fontSize: 10, 
                                color: Appcolor.secondary, 
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            Row(
                              children: [
                                Image.asset("assets/icons/dollar.png", height: 10, width: 10),
                                Text(
                                  widget.prizePool.toString(),
                                  style: TextStyle(fontSize: 8, color: Appcolor.secondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Credentials Section - Show when tournament is live OR when admin provides them early
                    if (isTournamentLive || hasValidCredentials) ...[
                      _buildGameCredentials(),
                    ] else if (_isLoadingCredentials) ...[
                      // Show loading indicator when fetching credentials
                      const Center(
                        child: SizedBox(
                          width: 12, 
                          height: 12, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Action Buttons
                    Row(
                      children: [
                        if (widget.onDetailsPressed != null)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onDetailsPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolor.secondary,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)
                                ),
                              ),
                              child: Text(
                                "Details", 
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Appcolor.cardsColor,
                                  fontWeight: FontWeight.w500,
                                )
                              ),
                            ),
                          ),
                        if (widget.onDetailsPressed != null && widget.onViewParticipants != null)
                          const SizedBox(width: 8),
                        if (widget.onViewParticipants != null)
                          Expanded(
                            child: TextButton(
                              onPressed: widget.onViewParticipants,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Appcolor.secondary),
                                ),
                              ),
                              child: Text(
                                "Participants", 
                                style: TextStyle(fontSize: 12, color: Appcolor.secondary)
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}