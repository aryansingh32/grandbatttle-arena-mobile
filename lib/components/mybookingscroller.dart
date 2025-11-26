// lib/widgets/my_bookings_scroller.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grand_battle_arena/models/slots_model.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/items/mybookingcard.dart';
import 'package:grand_battle_arena/items/participantbottomsheet.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package
import 'package:provider/provider.dart';
import 'package:grand_battle_arena/services/booking_refresh_notifier.dart';
import 'package:grand_battle_arena/components/tournamentdetails.dart';

// **NEW**: A simple in-memory cache to store tournament details and speed up loading.
class TournamentCache {
  static final TournamentCache _instance = TournamentCache._internal();
  factory TournamentCache() => _instance;
  TournamentCache._internal();

  final Map<int, TournamentModel> _cache = {};
  final Map<int, DateTime> _timestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  TournamentModel? get(int tournamentId) {
    if (_cache.containsKey(tournamentId) &&
        DateTime.now().difference(_timestamps[tournamentId]!) < _cacheDuration) {
      return _cache[tournamentId];
    }
    return null;
  }

  void set(TournamentModel tournament) {
    _cache[tournament.id] = tournament;
    _timestamps[tournament.id] = DateTime.now();
  }
}

class MyBookingsScroller extends StatefulWidget {
  const MyBookingsScroller({super.key});

  @override
  State<MyBookingsScroller> createState() => _MyBookingsScrollerState();
}

class _MyBookingsScrollerState extends State<MyBookingsScroller> {
  final TournamentCache _cache = TournamentCache();
  List<TournamentModel> _myBookings = [];
  bool _isFetchingInitialList = true;
  bool _hasFinishedLoadingAllCards = false;
  String? _error;
  bool _isSignedIn = false;
  BookingRefreshNotifier? _refreshNotifier;

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
  }

  @override
  void didChangeDependencies() {
  super.didChangeDependencies();

  final notifier = Provider.of<BookingRefreshNotifier?>(context, listen: false);

  if (_refreshNotifier == notifier) return;

  _refreshNotifier?.removeListener(_handleExternalRefresh);
  _refreshNotifier = notifier;
  _refreshNotifier?.addListener(_handleExternalRefresh);
}


  void _handleExternalRefresh() {
    _loadMyBookings();
  }

  @override
  void dispose() {
    _refreshNotifier?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  Future<void> _loadMyBookings() async {
    setState(() {
      _isFetchingInitialList = true;
      _hasFinishedLoadingAllCards = false;
      _error = null;
      _myBookings.clear();
    });

    try {
      // CHANGE: Skip API spam when user is logged out so “My Tournaments” hides cleanly.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isSignedIn = false;
            _isFetchingInitialList = false;
            _hasFinishedLoadingAllCards = true;
          });
        }
        return;
      } else {
        _isSignedIn = true;
      }

      final allBookings = await ApiService.getMyBookings();
      final uniqueTournamentIds = allBookings.map((b) => b.tournamentId).toSet();

      if (mounted) setState(() => _isFetchingInitialList = false);
      if (uniqueTournamentIds.isEmpty) {
        if (mounted) setState(() => _hasFinishedLoadingAllCards = true);
        return;
      }

      final bookingFutures = uniqueTournamentIds.map((id) async {
        try {
          TournamentModel? tournament = _cache.get(id);
          tournament ??= await ApiService.getTournamentDetails(id);
          _cache.set(tournament);
          return tournament;
        } catch (e) {
          print('Could not load details for tournament $id: $e');
          return null;
        }
      }).toList();

      final resolved = await Future.wait(bookingFutures);

      if (mounted) {
        setState(() {
          _myBookings = resolved.whereType<TournamentModel>().toList();
          _hasFinishedLoadingAllCards = true;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'An unexpected error occurred.';
          _isFetchingInitialList = false;
        });
      }
    }
  }

  bool get _shouldShowSection =>
      _isFetchingInitialList || (_isSignedIn && _myBookings.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowSection) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            "My Tournaments",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 25,
              letterSpacing: 0.5,
              color: Appcolor.white,
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isFetchingInitialList) {
      // **NEW**: Show the shimmer effect while loading the initial list.
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => _buildShimmerCard(),
      );
    }

    if (_error != null) {
      return Center(/* Error UI remains the same */);
    }

    // **UPDATED**: New empty state message.
    if (_myBookings.isEmpty && _hasFinishedLoadingAllCards) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, color: Appcolor.grey, size: 48),
            const SizedBox(height: 16),
            Text("No upcoming bookings.", style: TextStyle(color: Appcolor.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text("First, register in a tournament to see it here!", style: TextStyle(color: Appcolor.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 4),
      itemCount: _myBookings.length,
      itemBuilder: (context, index) {
        final tournament = _myBookings[index];
        return TournamentBookingCard(
          title: tournament.title,
          imageUrl: tournament.imageUrl ?? "assets/images/freefirebanner.webp",
          startTime: tournament.startTime,
          prizePool: tournament.prizePool,
          tournamentId: tournament.id,

          width: 180,
          height: 300,
          showTimer: tournament.gameId == null || tournament.gamePassword == null,
          onDetailsPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailsPage(
                  tournamentId: tournament.id,
                ),
              ),
            );
          },
          onViewParticipants: () => showParticipantsBottomSheet(context, tournament.id, tournament.title),
        );
      },
    );
  }



  /// **NEW**: A placeholder card with a shimmer effect.
  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Shimmer.fromColors(
        baseColor: Appcolor.cardsColor,
        highlightColor: Appcolor.cardsColor.withOpacity(0.5),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Appcolor.cardsColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 108,
                decoration: const BoxDecoration(
                  color: Colors.white, // This color will be overlayed by the shimmer
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text line placeholders
                    Container(width: 120, height: 12, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 10, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 140, height: 10, color: Colors.white),
                    const SizedBox(height: 16),
                    // Button placeholders
                    Row(
                      children: [
                        Expanded(child: Container(height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}