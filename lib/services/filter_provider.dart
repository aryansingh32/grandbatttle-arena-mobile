import 'package:flutter/foundation.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';

/// CHANGE: Centralized filter state so home + tournaments share quick filters.
class FilterProvider extends ChangeNotifier {
  String _gameFilter = 'All';
  String _teamSizeFilter = 'All';
  String _mapFilter = 'All';
  String _timeSlotFilter = 'All';

  String get gameFilter => _gameFilter;
  String get teamSizeFilter => _teamSizeFilter;
  String get mapFilter => _mapFilter;
  String get timeSlotFilter => _timeSlotFilter;

  void setGameFilter(String value) {
    if (_gameFilter == value) return;
    _gameFilter = value;
    notifyListeners();
  }

  void setTeamSizeFilter(String value) {
    if (_teamSizeFilter == value) return;
    _teamSizeFilter = value;
    notifyListeners();
  }

  void setMapFilter(String value) {
    if (_mapFilter == value) return;
    _mapFilter = value;
    notifyListeners();
  }

  void setTimeSlotFilter(String value) {
    if (_timeSlotFilter == value) return;
    _timeSlotFilter = value;
    notifyListeners();
  }

  /// CHANGE: Shared predicate so every widget applies identical logic.
  bool matchesTournament(TournamentModel tournament) {
    final matchesGame =
        _gameFilter == 'All' || tournament.game.toLowerCase() == _gameFilter.toLowerCase();
    final matchesTeam =
        _teamSizeFilter == 'All' || tournament.teamSize.toLowerCase() == _teamSizeFilter.toLowerCase();
    final matchesMap =
        _mapFilter == 'All' || (tournament.map ?? '').toLowerCase() == _mapFilter.toLowerCase();

    // Time slot filtering kept simple: compare formatted substring.
    final matchesTime = _timeSlotFilter == 'All'
        || tournament.dateTimeFormatted.contains(_timeSlotFilter);

    return matchesGame && matchesTeam && matchesMap && matchesTime;
  }
}

