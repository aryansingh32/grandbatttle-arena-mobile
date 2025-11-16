// lib/components/improved_tournament_registration.dart
// 🎨 IMPROVED UI/UX with instant feedback and smooth animations

import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/models/slots_model.dart';
import 'package:grand_battle_arena/services/real_time_slot_manager.dart';
import 'dart:async';

class ImprovedTournamentRegistration extends StatefulWidget {
  final int tournamentId;
  final TournamentModel? tournament;

  const ImprovedTournamentRegistration({
    super.key,
    required this.tournamentId,
    this.tournament,
  });

  @override
  State<ImprovedTournamentRegistration> createState() => _ImprovedTournamentRegistrationState();
}

class _ImprovedTournamentRegistrationState extends State<ImprovedTournamentRegistration> 
    with SingleTickerProviderStateMixin {
  TournamentModel? tournament;
  List<SlotData> slots = [];
  List<SlotsModel> _apiSlots = [];
  
  Set<int> selectedSlotIndices = {};
  int? selectedTeamIndex;
  
  bool isLoading = false;
  bool initialDataLoaded = false;
  bool isBookingInProgress = false;
  
  String? lastError;
  DateTime? lastUpdateTime;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    tournament = widget.tournament;
    
    // Setup animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start real-time sync
    RealTimeSlotManager().startRealTimeSync(widget.tournamentId);
    RealTimeSlotManager().addListener(_onLiveUpdate);
    
    _initializeData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    RealTimeSlotManager().stopRealTimeSync(widget.tournamentId);
    RealTimeSlotManager().removeListener(_onLiveUpdate);
    super.dispose();
  }

  // 🔥 LIVE UPDATE LISTENER
  void _onLiveUpdate() {
    if (!mounted || isBookingInProgress) return;
    
    final latestSlots = RealTimeSlotManager().getCachedSlots(widget.tournamentId);
    if (latestSlots != null) {
      setState(() {
        _apiSlots = latestSlots;
        lastUpdateTime = RealTimeSlotManager().getLastUpdateTime(widget.tournamentId);
        initializeSlots();
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      setState(() => isLoading = true);

      if (widget.tournamentId != null) {
        await _loadTournamentData();
        await _loadSlotDetails();
      }

      if (tournament != null) {
        initializeSlots();
      }
    } catch (e) {
      setState(() => lastError = _getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          initialDataLoaded = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTournamentData() async {
    final tournamentData = await ApiService.getTournamentById(widget.tournamentId!);
    if (mounted) {
      setState(() => tournament = tournamentData);
      print('✅ Tournament loaded: ${tournament!.title}, Team: ${tournament!.teamSize}, Players: ${tournament!.playersPerTeam}');
    }
  }

  Future<void> _loadSlotDetails() async {
    final slotsData = await ApiService.getTournamentSlotSummary(widget.tournamentId!);
    if (mounted) {
      setState(() => _apiSlots = slotsData);
      print('✅ Loaded ${slotsData.length} slots');
    }
  }

  void initializeSlots() {
    if (tournament == null) return;

    if (_apiSlots.isEmpty) {
      slots = List.generate(tournament!.maxPlayers, (index) => SlotData(
        slotNumber: index + 1,
        isSelected: selectedSlotIndices.contains(index),
      ));
      return;
    }

    slots = _apiSlots.map((apiSlot) {
      final slotIndex = apiSlot.slotNumber - 1;
      
      // Check if optimistically booked
      final isOptimistic = RealTimeSlotManager().isOptimisticallyBooked(
        widget.tournamentId!,
        apiSlot.slotNumber,
      );
      
      return SlotData(
        slotNumber: apiSlot.slotNumber,
        isOccupied: apiSlot.status.toUpperCase() == 'BOOKED',
        playerName: apiSlot.playerName,
        isLocked: isOptimistic,
        isSelected: selectedSlotIndices.contains(slotIndex),
      );
    }).toList();

    slots.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
  }

  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    if (errorStr.contains('insufficient')) return 'Insufficient coins to book slots.';
    if (errorStr.contains('not available')) return 'Slots no longer available. Please select different slots.';
    if (errorStr.contains('banned')) return 'Your account is suspended. Contact support.';
    return 'An error occurred. Please try again.';
  }

  int get playersPerTeam => tournament?.playersPerTeam ?? 1;
  int get occupiedSlotsCount => slots.where((slot) => slot.isOccupied).length;
  int get availableSlotsCount => slots.length - occupiedSlotsCount;

  void _handleSlotSelection(int slotIndex) {
    if (slotIndex >= slots.length) return;
    SlotData slot = slots[slotIndex];
    if (slot.isOccupied || slot.isLocked) return;

    setState(() {
      if (selectedSlotIndices.contains(slotIndex)) {
        selectedSlotIndices.remove(slotIndex);
        slot.isSelected = false;
      } else {
        selectedSlotIndices.add(slotIndex);
        slot.isSelected = true;
      }
    });
  }

  Future<void> _bookMultipleSlots(Map<int, String> slotPlayerMap) async {
    if (slotPlayerMap.isEmpty) {
      _showErrorSnackBar('No slots selected.');
      return;
    }

    setState(() {
      isBookingInProgress = true;
      isLoading = true;
    });

    // 🔥 OPTIMISTIC UPDATE (instant UI feedback)
    slotPlayerMap.forEach((slotIndex, playerName) {
      RealTimeSlotManager().optimisticallyBookSlot(
        widget.tournamentId!,
        slots[slotIndex].slotNumber,
        playerName,
      );
    });

    try {
      final playersPayload = slotPlayerMap.entries
          .map((entry) => {
                'slotNumber': slots[entry.key].slotNumber,
                'playerName': entry.value.trim(),
              })
          .toList();

      await ApiService.bookTeam(
        tournamentId: widget.tournamentId!,
        players: playersPayload,
      );

      // Force immediate refresh
      await RealTimeSlotManager().forceRefreshNow(widget.tournamentId!);
      
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSuccessSnackBar('✅ ${playersPayload.length} slot(s) booked successfully!');

    } catch (e) {
      // 🔄 ROLLBACK on error
      slotPlayerMap.forEach((slotIndex, _) {
        RealTimeSlotManager().rollbackOptimisticBooking(
          widget.tournamentId!,
          slots[slotIndex].slotNumber,
        );
      });
      
      String errorMessage = _getErrorMessage(e);
      setState(() => lastError = errorMessage);
      _showErrorSnackBar(errorMessage);
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
        duration: const Duration(seconds: 3),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBookingDialog() {
    final sortedIndices = selectedSlotIndices.toList()..sort();
    final controllers = {
      for (var index in sortedIndices) index: TextEditingController()
    };
    final totalCost = sortedIndices.length * (tournament?.entryFee ?? 0);

    showDialog(
      context: context,
      barrierDismissible: !isBookingInProgress,
      builder: (context) => _buildBookingDialog(sortedIndices, controllers, totalCost),
    );
  }

  Widget _buildBookingDialog(List<int> sortedIndices, Map<int, TextEditingController> controllers, int totalCost) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Appcolor.secondary, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('REGISTER PLAYERS', style: TextStyle(color: Appcolor.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                if (!isBookingInProgress)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: sortedIndices.map((slotIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[slotIndex],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Player name',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Container(
                            width: 50,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Appcolor.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('S${slots[slotIndex].slotNumber}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Total Cost: $totalCost coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (isBookingInProgress)
              const CircularProgressIndicator(color: Appcolor.secondary)
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final slotPlayerMap = {for (var entry in controllers.entries) entry.key: entry.value.text};
                        _bookMultipleSlots(slotPlayerMap);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Appcolor.secondary),
                      child: const Text('BOOK NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!initialDataLoaded) {
      return const Scaffold(
        backgroundColor: Appcolor.primary,
        body: Center(child: CircularProgressIndicator(color: Appcolor.secondary)),
      );
    }

    return Scaffold(
      backgroundColor: Appcolor.primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTournamentInfo(),
            _buildSlotsSection(),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/freefirebanner4.webp"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Appcolor.primary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(tournament!.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoChip(Icons.attach_money, '${tournament!.entryFee}/-', 'Entry/Player'),
              _buildInfoChip(Icons.groups, tournament!.teamSize, 'Team Size'),
              _buildInfoChip(Icons.emoji_events, '${tournament!.prizePool}', 'Prize Pool'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Appcolor.secondary, size: 16),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Appcolor.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }

  Widget _buildSlotsSection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Book Slots', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                _buildLiveIndicator(),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildSlotGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$availableSlotsCount available', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) => _buildSlotCard(index),
    );
  }

  Widget _buildSlotCard(int index) {
    final slot = slots[index];
    final isSelected = selectedSlotIndices.contains(index);

    Color bgColor, borderColor;
    if (isSelected) {
      bgColor = const Color.fromRGBO(243, 205, 35, 0.3);
      borderColor = Appcolor.secondary;
    } else if (slot.isLocked) {
      bgColor = const Color.fromRGBO(255, 152, 0, 0.2);
      borderColor = Colors.orange;
    } else if (slot.isOccupied) {
      bgColor = const Color.fromRGBO(244, 67, 54, 0.1);
      borderColor = Colors.red;
    } else {
      bgColor = const Color.fromRGBO(66, 66, 66, 0.3);
      borderColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () => _handleSlotSelection(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
              ),
              child: Center(child: Text('${slot.slotNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  slot.isOccupied && slot.playerName != null ? slot.playerName! : 'Empty',
                  style: TextStyle(color: slot.isOccupied ? Colors.white : Colors.grey[500], fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Appcolor.secondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final totalCost = selectedSlotIndices.length * (tournament?.entryFee ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
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
                Text('${selectedSlotIndices.length} SLOT(S) SELECTED', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('TOTAL: $totalCost COINS', style: const TextStyle(color: Appcolor.secondary, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: selectedSlotIndices.isEmpty || isBookingInProgress ? null : _showBookingDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolor.secondary,
              disabledBackgroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('BOOK SLOTS', style: TextStyle(color: selectedSlotIndices.isEmpty ? Colors.grey[400] : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class SlotData {
  int slotNumber;
  String? playerName;
  bool isOccupied;
  bool isSelected;
  bool isLocked;

  SlotData({
    required this.slotNumber,
    this.playerName,
    this.isOccupied = false,
    this.isSelected = false,
    this.isLocked = false,
  });
}