// lib/services/real_time_slot_manager.dart
// 🚀 INSTANT UPDATES: Real-time slot synchronization with optimistic UI

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/slots_model.dart';

class RealTimeSlotManager extends ChangeNotifier {
  static final RealTimeSlotManager _instance = RealTimeSlotManager._internal();
  factory RealTimeSlotManager() => _instance;
  RealTimeSlotManager._internal();

  // Cache management
  final Map<int, List<SlotsModel>> _slotsCache = {};
  final Map<int, DateTime> _lastUpdate = {};
  final Map<int, Timer> _pollTimers = {};
  
  // Optimistic updates tracking
  final Map<int, Set<int>> _optimisticBookings = {}; // tournamentId -> slot numbers
  
  // Aggressive polling (1 second for active tournaments)
  static const Duration ACTIVE_POLL_INTERVAL = Duration(seconds: 1);
  static const Duration CACHE_VALIDITY = Duration(seconds: 2);

  /// Start aggressive real-time sync
  void startRealTimeSync(int tournamentId) {
    if (_pollTimers.containsKey(tournamentId)) {
      print('⚠️ Already syncing tournament $tournamentId');
      return;
    }

    print('🔵 Starting REAL-TIME sync for tournament $tournamentId');
    
    // Immediate first fetch
    _fetchSlotsNow(tournamentId);
    
    // Start 1-second polling
    _pollTimers[tournamentId] = Timer.periodic(ACTIVE_POLL_INTERVAL, (timer) {
      _fetchSlotsNow(tournamentId);
    });
  }

  /// Stop syncing
  void stopRealTimeSync(int tournamentId) {
    _pollTimers[tournamentId]?.cancel();
    _pollTimers.remove(tournamentId);
    _optimisticBookings.remove(tournamentId);
    print('🛑 Stopped sync for tournament $tournamentId');
  }

  /// Immediate slot fetch
  Future<void> _fetchSlotsNow(int tournamentId) async {
    try {
      final slots = await ApiService.getTournamentSlotSummary(tournamentId);
      
      // Check if data actually changed
      if (_hasDataChanged(tournamentId, slots)) {
        _slotsCache[tournamentId] = slots;
        _lastUpdate[tournamentId] = DateTime.now();
        print('🔄 Slots updated for tournament $tournamentId at ${DateTime.now()}');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching slots: $e');
    }
  }

  /// Check if slot data changed
  bool _hasDataChanged(int tournamentId, List<SlotsModel> newSlots) {
    final oldSlots = _slotsCache[tournamentId];
    if (oldSlots == null) return true;
    if (oldSlots.length != newSlots.length) return true;

    for (int i = 0; i < oldSlots.length; i++) {
      if (oldSlots[i].status != newSlots[i].status ||
          oldSlots[i].playerName != newSlots[i].playerName) {
        return true;
      }
    }
    return false;
  }

  /// 🔥 OPTIMISTIC UPDATE: Mark slot as booked immediately
  void optimisticallyBookSlot(int tournamentId, int slotNumber, String playerName) {
    print('⚡ OPTIMISTIC: Booking slot $slotNumber for tournament $tournamentId');

    final slots = _slotsCache[tournamentId];
    if (slots == null) return;

    // Find and update slot optimistically
    final slotIndex = slots.indexWhere((s) => s.slotNumber == slotNumber);
    if (slotIndex != -1) {
      final updatedSlot = SlotsModel(
        id: slots[slotIndex].id,
        tournamentId: tournamentId,
        slotNumber: slotNumber,
        firebaseUserUID: 'OPTIMISTIC',
        playerName: playerName,
        status: "BOOKED",
        bookedAt: DateTime.now(),
      );

      slots[slotIndex] = updatedSlot;
      _optimisticBookings[tournamentId] ??= {};
      _optimisticBookings[tournamentId]!.add(slotNumber);
      
      notifyListeners();
      print('✅ OPTIMISTIC: Slot $slotNumber marked as booked in UI');
    }
  }

  /// 🔥 ROLLBACK: Revert optimistic update if booking fails
  void rollbackOptimisticBooking(int tournamentId, int slotNumber) {
    print('🔄 ROLLBACK: Reverting slot $slotNumber for tournament $tournamentId');

    final slots = _slotsCache[tournamentId];
    if (slots == null) return;

    final slotIndex = slots.indexWhere((s) => s.slotNumber == slotNumber);
    if (slotIndex != -1) {
      final revertedSlot = SlotsModel(
        id: slots[slotIndex].id,
        tournamentId: tournamentId,
        slotNumber: slotNumber,
        firebaseUserUID: null,
        playerName: null,
        status: "AVAILABLE",
        bookedAt: null,
      );

      slots[slotIndex] = revertedSlot;
      _optimisticBookings[tournamentId]?.remove(slotNumber);
      
      notifyListeners();
      print('✅ ROLLBACK: Slot $slotNumber reverted to available');
    }
  }

  /// Force immediate refresh
  Future<void> forceRefreshNow(int tournamentId) async {
    print('🔄 FORCE REFRESH: Tournament $tournamentId');
    await _fetchSlotsNow(tournamentId);
  }

  /// Get cached slots
  List<SlotsModel>? getCachedSlots(int tournamentId) {
    return _slotsCache[tournamentId];
  }

  /// Check if cache is still valid
  bool isCacheValid(int tournamentId) {
    final lastUpdateTime = _lastUpdate[tournamentId];
    if (lastUpdateTime == null) return false;
    return DateTime.now().difference(lastUpdateTime) < CACHE_VALIDITY;
  }

  /// Get last update time
  DateTime? getLastUpdateTime(int tournamentId) {
    return _lastUpdate[tournamentId];
  }

  /// Check if slot is optimistically booked
  bool isOptimisticallyBooked(int tournamentId, int slotNumber) {
    return _optimisticBookings[tournamentId]?.contains(slotNumber) ?? false;
  }

  @override
  void dispose() {
    _pollTimers.values.forEach((timer) => timer.cancel());
    _pollTimers.clear();
    _slotsCache.clear();
    _lastUpdate.clear();
    _optimisticBookings.clear();
    super.dispose();
  }
}

// 🔥 USAGE IN REGISTRATION PAGE:
/*
// In registertournament.dart:

@override
void initState() {
  super.initState();
  tournament = widget.tournament;
  
  // Start real-time sync
  RealTimeSlotManager().startRealTimeSync(widget.tournamentId!);
  RealTimeSlotManager().addListener(_onSlotsUpdated);
  
  _initializeData();
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

// OPTIMISTIC BOOKING:
Future<void> _bookMultipleSlots(Map<int, String> slotPlayerMap) async {
  setState(() {
    isBookingInProgress = true;
    isLoading = true;
  });

  // 1. OPTIMISTIC UPDATE (instant UI feedback)
  slotPlayerMap.forEach((slotIndex, playerName) {
    RealTimeSlotManager().optimisticallyBookSlot(
      widget.tournamentId!,
      slots[slotIndex].slotNumber,
      playerName,
    );
  });

  try {
    // 2. ACTUAL API CALL
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

    // 3. SUCCESS: Force immediate refresh
    await RealTimeSlotManager().forceRefreshNow(widget.tournamentId!);
    
    if (!mounted) return;
    Navigator.of(context).pop();
    _showSuccessSnackBar('${playersPayload.length} slot(s) booked successfully!');

  } catch (e) {
    // 4. ERROR: Rollback optimistic updates
    slotPlayerMap.forEach((slotIndex, _) {
      RealTimeSlotManager().rollbackOptimisticBooking(
        widget.tournamentId!,
        slots[slotIndex].slotNumber,
      );
    });
    
    setState(() {
      lastError = _getErrorMessage(e);
    });
    _showErrorSnackBar(lastError!);
  } finally {
    if (mounted) {
      setState(() {
        isBookingInProgress = false;
        isLoading = false;
      });
    }
  }
}
*/