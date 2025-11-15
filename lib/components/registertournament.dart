// tournament_registration_page.dart

import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/models/slots_model.dart'; // Import the slots model
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'dart:async';

// Enum to define the types of teams for clarity and type safety.
enum TeamType {
  solo,
  duo,
  squad,
  hexa, // Added hexa for 6-player teams
}

// The main StatefulWidget for the tournament registration page.
class TournamentRegistrationPage extends StatefulWidget {
  final int? tournamentId;
  final TournamentModel? tournament;
  final Function(String playerName, int slotNumber)? onPlayerRegister;
  final VoidCallback? onBackPressed;

  const TournamentRegistrationPage({
    super.key,
    this.tournamentId,
    this.tournament,
    this.onPlayerRegister,
    this.onBackPressed,
  });

  @override
  State<TournamentRegistrationPage> createState() =>
      _TournamentRegistrationPageState();
}

// Data class to manage the state of each slot in the UI.
class SlotData {
  int slotNumber;
  String? playerName;
  bool isOccupied;
  bool isSelected;
  bool isLocked; // New field for temporary locks during booking

  SlotData({
    required this.slotNumber,
    this.playerName,
    this.isOccupied = false,
    this.isSelected = false,
    this.isLocked = false,
  });
}

class _TournamentRegistrationPageState extends State<TournamentRegistrationPage> {
  TournamentModel? tournament;
  // This list now holds the UI state for the slots
  List<SlotData> slots = [];
  // This list holds the raw data from the API
  List<SlotsModel> _apiSlots = [];

  Set<int> selectedSlotIndices = {};
  int? selectedTeamIndex; // Track which team/group is currently selected

  // State variables to manage loading UI.
  bool isLoading = false;
  bool initialDataLoaded = false;
  bool isBookingInProgress = false;

  // Auto refresh timer
  Timer? _refreshTimer;
  static const int REFRESH_INTERVAL_SECONDS = 5;

  // Error handling
  String? lastError;
  DateTime? lastErrorTime;

  @override
  void initState() {
    super.initState();
    tournament = widget.tournament;
    _initializeData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: REFRESH_INTERVAL_SECONDS),
      (timer) {
        if (!isBookingInProgress && mounted) {
          _refreshSlots();
        }
      },
    );
  }

  Future<void> _refreshSlots() async {
    try {
      if (widget.tournamentId != null) {
        // Only refresh the dynamic slot data in the background
        await _loadSlotDetails();
        if (_apiSlots.isNotEmpty) {
          initializeSlots();
        }
      }
    } catch (e) {
      // Silent refresh failure - don't show error to user
      print('Background refresh failed: $e');
    }
  }

  // Helper method to get team type from string
  TeamType _getTeamType(String teamSize) {
    switch (teamSize.toLowerCase()) {
      case 'solo':
        return TeamType.solo;
      case 'duo':
        return TeamType.duo;
      case 'squad':
        return TeamType.squad;
      case 'hexa':
      case '6':
        return TeamType.hexa;
      default:
        return TeamType.squad;
    }
  }

  // Helper getters
  String get teamSizeString {
    if (tournament == null) return "TBD";
    final teamType = _getTeamType(tournament!.teamSize);
    switch (teamType) {
      case TeamType.solo:
        return "Solo";
      case TeamType.duo:
        return "Duo";
      case TeamType.squad:
        return "Squad";
      case TeamType.hexa:
        return "Hexa";
    }
  }

  int get playersPerTeam {
    if (tournament == null) return 1;
    final teamType = _getTeamType(tournament!.teamSize);
    switch (teamType) {
      case TeamType.solo:
        return 1;
      case TeamType.duo:
        return 2;
      case TeamType.squad:
        return 4;
      case TeamType.hexa:
        return 6;
    }
  }

  // Handles the initial data loading logic.
  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
        lastError = null;
      });

      if (widget.tournamentId != null) {
        // Fetch static tournament data (name, prize pool)
        await _loadTournamentData();
        // Fetch dynamic slot data (status, player names)
        await _loadSlotDetails();
      }

      // Initialize the UI only if both calls succeed
      if (tournament != null) {
        initializeSlots();
      }
    } catch (e) {
      setState(() {
        lastError = _getErrorMessage(e);
        lastErrorTime = DateTime.now();
      });
    } finally {
      if (mounted) {
        setState(() {
          initialDataLoaded = true;
          isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('insufficient')) {
      return 'Insufficient coins to book slots.';
    } else if (errorStr.contains('tournament not found')) {
      return 'Tournament not found or no longer available.';
    } else if (errorStr.contains('banned')) {
      return 'Your account is suspended. Please contact support.';
    } else if (errorStr.contains('already booked') ||
        errorStr.contains('not available') ||
        errorStr.contains('no longer available')) {
      return 'One or more selected slots are no longer available. Refreshing...';
    } else if (errorStr.contains('network') ||
        errorStr.contains('timeout') ||
        errorStr.contains('socketexception')) {
      return 'Network error. Please check your connection.';
    } else if (errorStr.contains('booking has closed')) {
      return 'This tournament is no longer open for booking.';
    } else if (errorStr.contains('being booked')) {
      return 'High traffic! Someone else is booking these slots. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Fetches basic tournament data from the API.
  Future<void> _loadTournamentData() async {
    try {
      final tournamentData =
          await ApiService.getTournamentById(widget.tournamentId!);
      if (mounted) {
        setState(() {
          tournament = tournamentData;
        });
      }
    } catch (e) {
      throw Exception('Failed to load tournament: ${_getErrorMessage(e)}');
    }
  }

  /// **NEW**: Fetches the detailed slot summary from the API.
  Future<void> _loadSlotDetails() async {
    try {
      final slotsData = await ApiService.getTournamentSlotSummary(widget.tournamentId!);
      if (mounted) {
        setState(() {
          _apiSlots = slotsData;
        });
      }
    } catch (e) {
      throw Exception('Failed to load slot details: ${_getErrorMessage(e)}');
    }
  }


  /// **REWRITTEN**: Sets up the UI slot state based on the detailed API data.
  void initializeSlots() {
    if (tournament == null) return;

    // Preserve selected team if still valid, otherwise clear selections
    if (selectedTeamIndex != null && !_isTeamAvailable(selectedTeamIndex!)) {
        selectedSlotIndices.clear();
        selectedTeamIndex = null;
    }
    
    // If the API hasn't returned any slots yet, generate a default empty list
    if (_apiSlots.isEmpty) {
        slots = List.generate(tournament!.maxPlayers, (index) => SlotData(
            slotNumber: index + 1,
            isSelected: selectedSlotIndices.contains(index),
        ));
        return;
    }

    // Map the detailed data from the API to the UI SlotData model
    slots = _apiSlots.map((apiSlot) {
      final slotIndex = apiSlot.slotNumber - 1;
      return SlotData(
        slotNumber: apiSlot.slotNumber,
        isOccupied: apiSlot.status.toUpperCase() == 'BOOKED',
        playerName: apiSlot.playerName,
        isLocked: false, // Always reset lock on refresh
        isSelected: selectedSlotIndices.contains(slotIndex),
      );
    }).toList();

    // Ensure the list is sorted by slot number, just in case
    slots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
  }


  int get occupiedSlotsCount => slots.where((slot) => slot.isOccupied).length;

  // Enhanced team/group selection logic
  void _handleTeamSelection(int teamIndex) {
    // Team selection is only for team modes and if the team is available
    if (_getTeamType(tournament!.teamSize) == TeamType.solo || !_isTeamAvailable(teamIndex)) {
      return; 
    }

    setState(() {
      // If a different team is selected, clear old selections and select the new team.
      if (selectedTeamIndex != teamIndex) {
        selectedSlotIndices.clear();
        for (var slot in slots) {
          slot.isSelected = false;
        }
        selectedTeamIndex = teamIndex;
      }
    });
  }

  // Individual slot selection within a team
  void _handleSlotSelection(int slotIndex) {
    if (slotIndex >= slots.length) return;

    SlotData slot = slots[slotIndex];

    // Prevent selection of occupied or locked slots
    if (slot.isOccupied || slot.isLocked) return;

    int teamIndex = slotIndex ~/ playersPerTeam;

    // In team modes, you must first select the team block
    if (_getTeamType(tournament!.teamSize) != TeamType.solo && selectedTeamIndex != teamIndex) {
      _handleTeamSelection(teamIndex);
    }
    
    // Toggle selection state for the individual slot
    setState(() {
      if (selectedSlotIndices.contains(slotIndex)) {
        selectedSlotIndices.remove(slotIndex);
        slot.isSelected = false;
        // If it was the last selected slot in a team, deselect the team as well
        if (selectedSlotIndices.isEmpty) {
            selectedTeamIndex = null;
        }
      } else {
        selectedSlotIndices.add(slotIndex);
        slot.isSelected = true;
        selectedTeamIndex = teamIndex; // Ensure team is marked as selected
      }
    });
  }

  // Check if a team has any available (not occupied or locked) slots
  bool _isTeamAvailable(int teamIndex) {
    int startSlot = teamIndex * playersPerTeam;
    for (int i = 0; i < playersPerTeam; i++) {
      int slotIndex = startSlot + i;
      if (slotIndex < slots.length && !slots[slotIndex].isOccupied && !slots[slotIndex].isLocked) {
        return true;
      }
    }
    return false;
  }

  // Enhanced booking with better error handling and validation
  Future<void> _bookMultipleSlots(Map<int, String> slotPlayerMap) async {
    if (slotPlayerMap.isEmpty) {
      _showErrorSnackBar('No slots selected for booking.');
      return;
    }

    // Validate player names
    for (var entry in slotPlayerMap.entries) {
        String trimmedName = entry.value.trim();
        if (trimmedName.isEmpty) {
            _showErrorSnackBar('Player name for slot ${slots[entry.key].slotNumber} cannot be empty.');
            return;
        }
        if (trimmedName.length < 2 || trimmedName.length > 20) {
            _showErrorSnackBar('Player name for slot ${slots[entry.key].slotNumber} must be 2-20 characters.');
            return;
        }
    }

    if (FirebaseAuthService.currentUser == null) {
      _showErrorSnackBar('Please sign in to register for the tournament.');
      return;
    }

    setState(() {
      isBookingInProgress = true;
      isLoading = true;
      lastError = null;
      // Lock selected slots in the UI to prevent concurrent actions
      slotPlayerMap.keys.forEach((slotIndex) {
        if (slotIndex < slots.length) {
          slots[slotIndex].isLocked = true;
        }
      });
    });

    try {
      // Prepare payload for the team booking API endpoint
      final List<Map<String, dynamic>> playersPayload = slotPlayerMap.entries
          .map((entry) => {
                'slotNumber': slots[entry.key].slotNumber,
                'playerName': entry.value.trim(),
              })
          .toList();

      await ApiService.bookTeam(
        tournamentId: widget.tournamentId!,
        players: playersPayload,
      );

      // On success, refresh data and show a success message
      await _loadSlotDetails();
      initializeSlots();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close the registration dialog
      _showSuccessSnackBar('${playersPayload.length} slot(s) booked successfully!');

    } catch (e) {
      String errorMessage = _getErrorMessage(e);
      setState(() {
        lastError = errorMessage;
        lastErrorTime = DateTime.now();
      });
       if (mounted) {
         _showErrorSnackBar(errorMessage);
         // Auto-refresh data if the error is related to slot availability
        if (errorMessage.contains('no longer available')) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _refreshSlots();
          });
        }
       }
    } finally {
      if (mounted) {
        setState(() {
          // Always unlock slots after the attempt, regardless of outcome
          slotPlayerMap.keys.forEach((slotIndex) {
              if(slotIndex < slots.length) slots[slotIndex].isLocked = false;
          });
          isBookingInProgress = false;
          isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

    // --- DIALOG BUILDER ---
  void _showMultipleSlotRegistrationDialog() {
    final List<int> sortedIndices = selectedSlotIndices.toList()..sort();
    final Map<int, TextEditingController> controllers = {
      for (var index in sortedIndices)
        index: TextEditingController()
    };
    final int totalCost = sortedIndices.length * (tournament?.entryFee ?? 0);

    showDialog(
      context: context,
      barrierDismissible: !isBookingInProgress,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                      Color(0xFF0f3460),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Appcolor.secondary, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'REGISTER PLAYERS',
                            style: TextStyle(
                              color: Appcolor.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isBookingInProgress)
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Player Input Fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: sortedIndices.map((slotIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: TextField(
                                controller: controllers[slotIndex],
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Player name',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  prefixIcon: Container(
                                    width: 50,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Appcolor.secondary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'S${slots[slotIndex].slotNumber}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Cost Summary
                    Text(
                      'Total Cost: $totalCost coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    if (isBookingInProgress)
                      const Center(child: CircularProgressIndicator(color: Appcolor.secondary))
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final Map<int, String> slotPlayerMap = {
                                  for (var entry in controllers.entries)
                                    entry.key: entry.value.text
                                };
                                _bookMultipleSlots(slotPlayerMap);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolor.secondary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('BOOK NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // --- UI WIDGET BUILDER METHODS ---

  Widget _buildInfoColumn(
      {required Widget icon, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: value.contains('${tournament!.prizePool}')
                    ? Appcolor.secondary
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsSection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Book Slots',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(243, 205, 35, 0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Appcolor.secondary),
                  ),
                  child: Text(
                    '${(occupiedSlotsCount)}/${tournament!.maxPlayers}', // Using direct slot count is more accurate
                    style: const TextStyle(
                      color: Appcolor.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Error display
            if (lastError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 16),
                      onPressed: () => setState(() => lastError = null),
                    ),
                  ],
                ),
              ),
            ],

            Expanded(
              child: _buildSlotsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    if (tournament == null) {
      return const Center(child: Text("No tournament data"));
    }
    final teamType = _getTeamType(tournament!.teamSize);

    switch (teamType) {
      case TeamType.solo:
        return _buildSoloSlotsList();
      case TeamType.duo:
      case TeamType.squad:
      case TeamType.hexa:
        return _buildTeamSlotsList();
    }
  }

  // SOLO SLOTS - Free Fire custom room style grid
  Widget _buildSoloSlotsList() {
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 8,
        ),
        itemCount: slots.length,
        itemBuilder: (context, index) {
            return _buildSoloSlot(index);
        },
    );
  }

  Widget _buildSoloSlot(int slotIndex) {
    SlotData slot = slots[slotIndex];
    bool isSelected = selectedSlotIndices.contains(slotIndex);

    Color backgroundColor;
    Color borderColor;
    String statusText = '';

    if (isSelected) {
      backgroundColor = const Color.fromRGBO(243, 205, 35, 0.3);
      borderColor = Appcolor.secondary;
    } else if (slot.isLocked) {
      backgroundColor = const Color.fromRGBO(255, 152, 0, 0.2);
      borderColor = Colors.orange;
      statusText = 'BOOKING';
    } else if (slot.isOccupied) {
      backgroundColor = const Color.fromRGBO(244, 67, 54, 0.1);
      borderColor = Colors.red;
    } else {
      backgroundColor = const Color.fromRGBO(66, 66, 66, 0.3);
      borderColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () => _handleSlotSelection(slotIndex),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Slot number section
            Container(
              width: 40,
              height: double.infinity,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Center(
                child: Text(
                  '${slot.slotNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Player name section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  slot.isOccupied && slot.playerName != null
                      ? slot.playerName!
                      : 'Empty',
                  style: TextStyle(
                    color: slot.isOccupied ? Colors.white : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Status indicator
            if (statusText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: slot.isLocked ? Colors.orange : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (isSelected)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: const Icon(
                  Icons.check_circle,
                  color: Appcolor.secondary,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // TEAM SLOTS - Free Fire custom room style for Duo/Squad/Hexa
  Widget _buildTeamSlotsList() {
    int teamsCount = tournament!.maxPlayers ~/ playersPerTeam;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: playersPerTeam > 2 ? 1.8 : 2.5,
      ),
      itemCount: teamsCount,
      itemBuilder: (context, index) => _buildTeamSlot(index),
    );
  }

  Widget _buildTeamSlot(int teamIndex) {
    bool isTeamBlockSelected = selectedTeamIndex == teamIndex;
    bool isAvailable = _isTeamAvailable(teamIndex);

    Color borderColor;
    Color backgroundColor;

    if (isTeamBlockSelected) {
      borderColor = Appcolor.secondary;
      backgroundColor = const Color.fromRGBO(243, 205, 35, 0.2);
    } else if (!isAvailable) {
      borderColor = Colors.red;
      backgroundColor = const Color.fromRGBO(244, 67, 54, 0.1);
    } else {
      borderColor = Colors.grey[600]!;
      backgroundColor = const Color.fromRGBO(66, 66, 66, 0.3);
    }
    
    return GestureDetector(
        onTap: () => _handleTeamSelection(teamIndex),
        child: Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
                children: [
                    // Team number section
                    Container(
                        width: 40,
                        height: double.infinity,
                        decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                            ),
                        ),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text(
                                    '${teamIndex + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                    ),
                                ),
                                if (_getTeamType(tournament!.teamSize) != TeamType.solo)
                                    Text(
                                        '${playersPerTeam}P',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 8,
                                        ),
                                    ),
                            ],
                        ),
                    ),
                    // Players section
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildPlayersDisplay(teamIndex),
                        ),
                    ),
                ],
            ),
        ),
    );
}

Widget _buildPlayersDisplay(int teamIndex) {
    int startSlot = teamIndex * playersPerTeam;
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(playersPerTeam, (i) {
            int slotIndex = startSlot + i;
            if (slotIndex >= slots.length) return const SizedBox.shrink();
            
            final slot = slots[slotIndex];
            final isSelected = selectedSlotIndices.contains(slotIndex);
            
            return Expanded(
                child: GestureDetector(
                  onTap: () => _handleSlotSelection(slotIndex),
                  child: Container(
                    color: Colors.transparent, // Makes the whole row tappable
                    child: Row(
                      children: [
                        // Icon showing status (selected, occupied, available)
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Appcolor.secondary
                                : slot.isOccupied
                                    ? Colors.red
                                    : slot.isLocked
                                        ? Colors.orange
                                        : Colors.grey[600],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Player name or status
                        Expanded(
                          child: Text(
                            slot.isOccupied && slot.playerName != null
                                ? slot.playerName!
                                : slot.isLocked
                                    ? 'Booking...'
                                    : 'Empty',
                            style: TextStyle(
                              color: isSelected ? Appcolor.secondary : (slot.isOccupied ? Colors.white : Colors.grey[500]),
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            );
        }),
    );
}
  
    Widget _buildBottomActionBar() {
      final int totalCost = (selectedSlotIndices.length * (tournament?.entryFee ?? 0));

      return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Appcolor.primary,
              border: Border(top: BorderSide(color: Colors.grey[800]!))
          ),
          child: Row(
              children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                              '${selectedSlotIndices.length} SLOT(S) SELECTED',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                              ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              'TOTAL COST: $totalCost COINS',
                              style: const TextStyle(
                                  color: Appcolor.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                              ),
                          ),
                      ],
                  )),
                  ElevatedButton(
                    onPressed: selectedSlotIndices.isEmpty || isBookingInProgress
                        ? null
                        : () => _showMultipleSlotRegistrationDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.secondary,
                      disabledBackgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'BOOK SLOTS',
                      style: TextStyle(
                        color: selectedSlotIndices.isEmpty ? Colors.grey[400] : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
          ),
      );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Appcolor.primary,
            body: SafeArea(
                child: !initialDataLoaded
                    ? const Center(child: CircularProgressIndicator(color: Appcolor.secondary))
                    : tournament == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Failed to load tournament data.', style: TextStyle(color: Colors.white)),
                                const SizedBox(height: 10),
                                if (lastError != null) Text(lastError!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                    onPressed: _initializeData,
                                    child: const Text('Retry'),
                                )
                              ],
                            ),
                          )
                        : Column(
                            children: [
                                // Header with background image
                                Container(
                                    height: MediaQuery.of(context).size.height * 0.25,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage("assets/images/freefirebanner4.webp"),
                                          fit: BoxFit.cover,
                                        ),
                                    ),
                                    child: Stack(
                                        children: [
                                            // Gradient overlay for text visibility
                                            Container(
                                                decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [Colors.transparent, Colors.black87],
                                                    ),
                                                ),
                                            ),
                                            // Back button
                                            Positioned(
                                                top: 16,
                                                left: 16,
                                                child: GestureDetector(
                                                    onTap: () => Navigator.of(context).pop(),
                                                    child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                            color: Appcolor.primary.withOpacity(0.7),
                                                            borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                                // Tournament info
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    child: Column(
                                        children: [
                                            Text(
                                                tournament!.title,
                                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 15),
                                            Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                    _buildInfoColumn(
                                                        icon: Image.asset("assets/icons/dollar.png", height: 14, width: 14),
                                                        value: '${tournament!.entryFee}/-',
                                                        label: 'Entry/Player',
                                                    ),
                                                    _buildInfoColumn(
                                                        icon: const Icon(Icons.groups, color: Appcolor.secondary, size: 16),
                                                        value: teamSizeString,
                                                        label: 'Team Size',
                                                    ),
                                                    _buildInfoColumn(
                                                        icon: const Icon(Icons.emoji_events, color: Appcolor.secondary, size: 16),
                                                        value: '${tournament!.prizePool}',
                                                        label: 'Prize Pool',
                                                    ),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                                // Team-based slots section
                                _buildSlotsSection(),
                                
                                // Bottom register section
                                _buildBottomActionBar(),
                            ],
                        ),
            ),
        );
    }
}