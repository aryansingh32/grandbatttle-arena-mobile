// tournament_registration_page.dart - PRODUCTION READY VERSION
// ✅ Fixed: Team size parsing, instant updates, validation, race conditions

import 'package:flutter/material.dart';
import 'package:grand_battle_arena/services/real_time_slot_manager.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/models/slots_model.dart';
import 'package:grand_battle_arena/services/firebase_auth_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/booking_refresh_notifier.dart';

enum TeamType {
  solo,
  duo,
  squad,
  hexa,
}

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

class SlotData {
  int slotNumber;
  String? playerName;
  bool isOccupied;
  bool isSelected;
  bool isLocked;
  bool isOptimistic; // NEW: Track optimistically booked slots

  SlotData({
    required this.slotNumber,
    this.playerName,
    this.isOccupied = false,
    this.isSelected = false,
    this.isLocked = false,
    this.isOptimistic = false,
  });
}

class _TournamentRegistrationPageState extends State<TournamentRegistrationPage> {
  TournamentModel? tournament;
  List<SlotData> slots = [];
  List<SlotsModel> _apiSlots = [];

  Set<int> selectedSlotIndices = {};
  int? selectedTeamIndex;

  bool isLoading = false;
  bool initialDataLoaded = false;
  bool isBookingInProgress = false;

  Timer? _refreshTimer;
  static const int REFRESH_INTERVAL_SECONDS = 3; // Faster polling

  String? lastError;
  DateTime? lastErrorTime;

  @override
  void initState() {
    super.initState();
    tournament = widget.tournament;
    _initializeData();
    RealTimeSlotManager().startRealTimeSync(widget.tournamentId!);
    RealTimeSlotManager().addListener(_onSlotsUpdated);
  }

  @override
  void dispose() {
    RealTimeSlotManager().stopRealTimeSync(widget.tournamentId!);
    RealTimeSlotManager().removeListener(_onSlotsUpdated);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onSlotsUpdated() {
    if (!mounted) return;
    
    final latestSlots = RealTimeSlotManager().getCachedSlots(widget.tournamentId!);
    if (latestSlots != null) {
      setState(() {
        _apiSlots = latestSlots;
        initializeSlots();
      });
    }
  }

  Future<void> _refreshSlots() async {
    try {
      if (widget.tournamentId != null && !isBookingInProgress) {
        await _loadSlotDetails();
        if (_apiSlots.isNotEmpty) {
          initializeSlots();
        }
      }
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  // 🔥 FIX #1: Proper team type parsing from backend
  TeamType _getTeamType(String teamSize) {
    // Backend sends: "SOLO", "DUO", "SQUAD", "HEXA"
    // or "Solo", "Duo", "Squad", "Hexa"
    String normalized = teamSize.trim().toUpperCase();
    
    print('🔍 Parsing teamSize: "$teamSize" → normalized: "$normalized"');
    
    switch (normalized) {
      case 'SOLO':
      case '1':
        return TeamType.solo;
      case 'DUO':
      case '2':
        return TeamType.duo;
      case 'SQUAD':
      case '4':
        return TeamType.squad;
      case 'HEXA':
      case '6':
        return TeamType.hexa;
      default:
        print('⚠️ Unknown teamSize: "$teamSize", defaulting to SOLO');
        return TeamType.solo;
    }
  }

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

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
        lastError = null;
      });

      if (widget.tournamentId != null) {
        await _loadTournamentData();
        await _loadSlotDetails();
      }

      if (tournament != null) {
        print('✅ Tournament loaded: teamSize="${tournament!.teamSize}", playersPerTeam=$playersPerTeam');
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

  void initializeSlots() {
    if (tournament == null) return;

    if (selectedTeamIndex != null && !_isTeamAvailable(selectedTeamIndex!)) {
      selectedSlotIndices.clear();
      selectedTeamIndex = null;
    }
    
    if (_apiSlots.isEmpty) {
      slots = List.generate(tournament!.maxPlayers, (index) => SlotData(
        slotNumber: index + 1,
        isSelected: selectedSlotIndices.contains(index),
      ));
      return;
    }

    slots = _apiSlots.map((apiSlot) {
      final slotIndex = apiSlot.slotNumber - 1;
      return SlotData(
        slotNumber: apiSlot.slotNumber,
        isOccupied: apiSlot.status.toUpperCase() == 'BOOKED',
        playerName: apiSlot.playerName,
        isLocked: false,
        isSelected: selectedSlotIndices.contains(slotIndex),
      );
    }).toList();

    slots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
  }

  int get occupiedSlotsCount => slots.where((slot) => slot.isOccupied).length;

  void _handleTeamSelection(int teamIndex) {
    if (_getTeamType(tournament!.teamSize) == TeamType.solo || !_isTeamAvailable(teamIndex)) {
      return; 
    }

    setState(() {
      if (selectedTeamIndex != teamIndex) {
        selectedSlotIndices.clear();
        for (var slot in slots) {
          slot.isSelected = false;
        }
        selectedTeamIndex = teamIndex;
      }
    });
  }

  void _handleSlotSelection(int slotIndex) {
    if (slotIndex >= slots.length) return;

    SlotData slot = slots[slotIndex];

    if (slot.isOccupied || slot.isLocked) return;

    int teamIndex = slotIndex ~/ playersPerTeam;

    if (_getTeamType(tournament!.teamSize) != TeamType.solo && selectedTeamIndex != teamIndex) {
      _handleTeamSelection(teamIndex);
    }
    
    setState(() {
      if (selectedSlotIndices.contains(slotIndex)) {
        selectedSlotIndices.remove(slotIndex);
        slot.isSelected = false;
        if (selectedSlotIndices.isEmpty) {
          selectedTeamIndex = null;
        }
      } else {
        selectedSlotIndices.add(slotIndex);
        slot.isSelected = true;
        selectedTeamIndex = teamIndex;
      }
    });
  }

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

  // 🔥 FIX #2: Instant optimistic updates + proper validation
  Future<void> _bookMultipleSlots(Map<int, String> slotPlayerMap) async {
    // 🔥 CRITICAL: Validate all names before booking
    for (var entry in slotPlayerMap.entries) {
      String name = entry.value.trim();
      if (name.isEmpty) {
        _showErrorSnackBar('Player name for Slot ${slots[entry.key].slotNumber} cannot be empty!');
        return;
      }
      if (name.length < 2) {
        _showErrorSnackBar('Player name must be at least 2 characters long!');
        return;
      }
      if (name.length > 30) {
        _showErrorSnackBar('Player name must be less than 30 characters!');
        return;
      }
    }

    setState(() {
      isBookingInProgress = true;
      isLoading = true;
      lastError = null; // Clear previous errors
    });

    // 1. OPTIMISTIC UPDATE - Instant UI feedback
    setState(() {
      slotPlayerMap.forEach((slotIndex, playerName) {
        slots[slotIndex].isLocked = true;
        slots[slotIndex].playerName = playerName;
        slots[slotIndex].isOptimistic = true;
        
        RealTimeSlotManager().optimisticallyBookSlot(
          widget.tournamentId!,
          slots[slotIndex].slotNumber,
          playerName,
        );
      });
    });

    try {
      // 2. ACTUAL API CALL
      final playersPayload = slotPlayerMap.entries
          .map((entry) => {
                'slotNumber': slots[entry.key].slotNumber,
                'playerName': entry.value.trim(),
              })
          .toList();

      print('📤 Booking request: $playersPayload');

      await ApiService.bookTeam(
        tournamentId: widget.tournamentId!,
        players: playersPayload,
      );

      print('✅ Booking successful!');

      // 3. SUCCESS: Force immediate refresh to confirm booking
      await RealTimeSlotManager().forceRefreshNow(widget.tournamentId!);
      
      if (!mounted) return;
      
      // Clear selections
      setState(() {
        selectedSlotIndices.clear();
        selectedTeamIndex = null;
      });
      
      Navigator.of(context).pop(true);
      context.read<BookingRefreshNotifier>().ping();
      _showSuccessSnackBar('${playersPayload.length} slot(s) booked successfully! 🎉');

    } catch (e) {
      print('❌ Booking failed: $e');
      
      // 4. ERROR: Rollback optimistic updates
      setState(() {
        slotPlayerMap.forEach((slotIndex, _) {
          slots[slotIndex].isLocked = false;
          slots[slotIndex].playerName = null;
          slots[slotIndex].isOptimistic = false;
          
          RealTimeSlotManager().rollbackOptimisticBooking(
            widget.tournamentId!,
            slots[slotIndex].slotNumber,
          );
        });
        
        lastError = _getErrorMessage(e);
      });
      
      _showErrorSnackBar(lastError!);
      
      // Force refresh to get actual server state
      await _refreshSlots();
    } finally {
      if (mounted) {
        setState(() {
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

  // 🔥 FIX #3: Improved registration dialog with validation
  void _showMultipleSlotRegistrationDialog() {
    final List<int> sortedIndices = selectedSlotIndices.toList()..sort();
    final Map<int, TextEditingController> controllers = {
      for (var index in sortedIndices)
        index: TextEditingController()
    };
    final int totalCost = sortedIndices.length * (tournament?.entryFee ?? 0);

    // Auto-focus first field
    final focusNodes = {
      for (var index in sortedIndices)
        index: FocusNode()
    };

    // Focus first field after dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sortedIndices.isNotEmpty) {
        focusNodes[sortedIndices.first]?.requestFocus();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: !isBookingInProgress,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool allFieldsFilled = controllers.values.every((c) => c.text.trim().isNotEmpty);

            return WillPopScope(
              onWillPop: () async => !isBookingInProgress,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
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
                    boxShadow: [
                      BoxShadow(
                        color: Appcolor.secondary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (!isBookingInProgress)
                            IconButton(
                              onPressed: () {
                                focusNodes.values.forEach((node) => node.dispose());
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Player Input Fields
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: sortedIndices.asMap().entries.map((entry) {
                              int idx = entry.key;
                              int slotIndex = entry.value;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: TextField(
                                  controller: controllers[slotIndex],
                                  focusNode: focusNodes[slotIndex],
                                  enabled: !isBookingInProgress,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  textInputAction: idx < sortedIndices.length - 1 
                                      ? TextInputAction.next 
                                      : TextInputAction.done,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      // Trigger rebuild to enable/disable button
                                    });
                                  },
                                  onSubmitted: (_) {
                                    if (idx < sortedIndices.length - 1) {
                                      focusNodes[sortedIndices[idx + 1]]?.requestFocus();
                                    } else if (allFieldsFilled) {
                                      // Auto-submit on last field if all filled
                                      final Map<int, String> slotPlayerMap = {
                                        for (var e in controllers.entries)
                                          e.key: e.value.text
                                      };
                                      focusNodes.values.forEach((node) => node.dispose());
                                      _bookMultipleSlots(slotPlayerMap);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Enter player name',
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
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
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    suffixIcon: controllers[slotIndex]!.text.trim().isNotEmpty
                                        ? Icon(Icons.check_circle, color: Colors.green[400], size: 20)
                                        : Icon(Icons.radio_button_unchecked, color: Colors.grey[600], size: 20),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Cost Summary with icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Appcolor.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/icons/dollar.png", height: 20, width: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Cost: $totalCost coins',
                              style: const TextStyle(
                                color: Appcolor.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      if (isBookingInProgress)
                        Column(
                          children: [
                            const CircularProgressIndicator(color: Appcolor.secondary),
                            const SizedBox(height: 10),
                            Text(
                              'Booking ${sortedIndices.length} slot(s)...',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  focusNodes.values.forEach((node) => node.dispose());
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: !allFieldsFilled ? null : () {
                                  final Map<int, String> slotPlayerMap = {
                                    for (var entry in controllers.entries)
                                      entry.key: entry.value.text
                                  };
                                  focusNodes.values.forEach((node) => node.dispose());
                                  _bookMultipleSlots(slotPlayerMap);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allFieldsFilled ? Appcolor.secondary : Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'BOOK NOW',
                                  style: TextStyle(
                                    color: allFieldsFilled ? Colors.black : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // UI BUILDERS (keeping your existing UI structure)

  Widget _buildInfoColumn({required Widget icon, required String value, required String label}) {
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
                color: value.contains('${tournament!.prizePool}') ? Appcolor.secondary : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildRewardHighlight() {
    if (tournament == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Appcolor.primary.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Appcolor.secondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _rewardChip('Per Kill', '+${tournament!.perKillCoins}'),
          _rewardChip('1st', tournament!.firstPlacePrize.toString()),
          _rewardChip('2nd', tournament!.secondPlacePrize.toString()),
          _rewardChip('3rd', tournament!.thirdPlacePrize.toString()),
        ],
      ),
    );
  }

  Widget _rewardChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Appcolor.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            Image.asset("assets/icons/dollar.png", height: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Appcolor.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(243, 205, 35, 0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Appcolor.secondary),
                  ),
                  child: Text(
                    '${occupiedSlotsCount}/${tournament!.maxPlayers}',
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

            Expanded(child: _buildSlotsList()),
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
    Widget? statusIcon;

    if (isSelected) {
      backgroundColor = const Color.fromRGBO(243, 205, 35, 0.3);
      borderColor = Appcolor.secondary;
      statusIcon = const Icon(Icons.check_circle, color: Appcolor.secondary, size: 16);
    } else if (slot.isOptimistic) {
      backgroundColor = const Color.fromRGBO(76, 175, 80, 0.2);
      borderColor = Colors.green;
      statusText = 'BOOKING';
    } else if (slot.isLocked) {
      backgroundColor = const Color.fromRGBO(255, 152, 0, 0.2);
      borderColor = Colors.orange;
      statusText = 'PENDING';
    } else if (slot.isOccupied) {
      backgroundColor = const Color.fromRGBO(244, 67, 54, 0.1);
      borderColor = Colors.red;
    } else {
      backgroundColor = const Color.fromRGBO(66, 66, 66, 0.3);
      borderColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () => _handleSlotSelection(slotIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Appcolor.secondary.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
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
                  color: slot.isOptimistic ? Colors.green : (slot.isLocked ? Colors.orange : Colors.red),
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

            if (statusIcon != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: statusIcon,
              ),
          ],
        ),
      ),
    );
  }

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isTeamBlockSelected ? [
            BoxShadow(
              color: Appcolor.secondary.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
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
        
        Color iconColor;
        if (isSelected) {
          iconColor = Appcolor.secondary;
        } else if (slot.isOptimistic) {
          iconColor = Colors.green;
        } else if (slot.isOccupied) {
          iconColor = Colors.red;
        } else if (slot.isLocked) {
          iconColor = Colors.orange;
        } else {
          iconColor = Colors.grey[600]!;
        }
        
        return Expanded(
          child: GestureDetector(
            onTap: () => _handleSlotSelection(slotIndex),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: iconColor,
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
                          : slot.isOptimistic
                              ? 'Booking...'
                              : slot.isLocked
                                  ? 'Pending...'
                                  : 'Empty',
                      style: TextStyle(
                        color: isSelected 
                            ? Appcolor.secondary 
                            : (slot.isOccupied ? Colors.white : Colors.grey[500]),
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
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
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
                Row(
                  children: [
                    Image.asset("assets/icons/dollar.png", height: 14, width: 14),
                    const SizedBox(width: 4),
                    Text(
                      'TOTAL: $totalCost COINS',
                      style: const TextStyle(
                        color: Appcolor.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              elevation: selectedSlotIndices.isEmpty ? 0 : 5,
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
            ? const Center(
                child: CircularProgressIndicator(color: Appcolor.secondary),
              )
            : tournament == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 20),
                        const Text(
                          'Failed to load tournament data.',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        if (lastError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              lastError!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _initializeData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Appcolor.secondary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
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
                            // Gradient overlay
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
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tournament info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        child: Column(
                          children: [
                            Text(
                              tournament!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInfoColumn(
                                  icon: Image.asset(
                                    "assets/icons/dollar.png",
                                    height: 14,
                                    width: 14,
                                  ),
                                  value: '${tournament!.entryFee}/-',
                                  label: 'Entry/Player',
                                ),
                                _buildInfoColumn(
                                  icon: const Icon(
                                    Icons.groups,
                                    color: Appcolor.secondary,
                                    size: 16,
                                  ),
                                  value: teamSizeString,
                                  label: 'Team Size',
                                ),
                                _buildInfoColumn(
                                  icon: const Icon(
                                    Icons.emoji_events,
                                    color: Appcolor.secondary,
                                    size: 16,
                                  ),
                                  value: '${tournament!.prizePool}',
                                  label: 'Prize Pool',
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          _buildRewardHighlight(),
                          ],
                        ),
                      ),
                      // Slots section
                      _buildSlotsSection(),
                      // Bottom action bar
                      _buildBottomActionBar(),
                    ],
                  ),
      ),
    );
  }
}