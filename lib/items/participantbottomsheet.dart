import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';
import 'package:grand_battle_arena/models/slots_model.dart';
import 'package:grand_battle_arena/services/api_service.dart';

class ParticipantsBottomSheet extends StatefulWidget {
  final int tournamentId;
  final String tournamentTitle;

  const ParticipantsBottomSheet({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
  });

  @override
  State<ParticipantsBottomSheet> createState() => _ParticipantsBottomSheetState();
}

class _ParticipantsBottomSheetState extends State<ParticipantsBottomSheet> {
  List<SlotsModel> participants = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final slots = await ApiService.getTournamentSlotSummary(widget.tournamentId);
      
      setState(() {
        participants = slots.where((slot) => slot.isBooked).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Appcolor.primary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Appcolor.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Participants",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Appcolor.white,
                        ),
                      ),
                      Text(
                        widget.tournamentTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Appcolor.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Appcolor.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Participants count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: Appcolor.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "${participants.length} Participants",
                  style: TextStyle(
                    fontSize: 16,
                    color: Appcolor.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loadParticipants,
                  icon: Icon(
                    Icons.refresh,
                    color: Appcolor.secondary,
                    size: 16,
                  ),
                  label: Text(
                    "Refresh",
                    style: TextStyle(
                      color: Appcolor.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.grey),
          
          // Participants list
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Appcolor.secondary),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Appcolor.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load participants",
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadParticipants,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.secondary,
              ),
              child: Text(
                "Retry",
                style: TextStyle(color: Appcolor.white),
              ),
            ),
          ],
        ),
      );
    }

    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Appcolor.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "No participants yet",
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to join this tournament!",
              style: TextStyle(
                color: Appcolor.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _buildParticipantItem(participant, index);
      },
    );
  }

  Widget _buildParticipantItem(SlotsModel participant, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolor.cardsColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Appcolor.secondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Participant number/position
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Appcolor.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "#${participant.slotNumber}",
                style: TextStyle(
                  color: Appcolor.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Participant details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.playerName ?? "Unknown Player",
                  style: TextStyle(
                    color: Appcolor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (participant.bookedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Joined ${_formatJoinDate(participant.bookedAt!)}",
                    style: TextStyle(
                      color: Appcolor.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Registered",
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}

// Helper function to show the bottom sheet
void showParticipantsBottomSheet(BuildContext context, int tournamentId, String tournamentTitle) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ParticipantsBottomSheet(
        tournamentId: tournamentId,
        tournamentTitle: tournamentTitle,
      ),
    ),
  );
}