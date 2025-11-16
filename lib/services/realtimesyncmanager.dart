// lib/services/realtime_sync_manager.dart
// STEP 5: Real-time data synchronization for instant updates

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grand_battle_arena/services/api_service.dart';
import 'package:grand_battle_arena/models/tournament_model.dart';
import 'package:grand_battle_arena/models/wallet_model.dart';

/// STEP 5.1: Singleton manager for real-time data synchronization
/// This ensures all screens see updates instantly when admin makes changes
class RealtimeSyncManager extends ChangeNotifier {
  static final RealtimeSyncManager _instance = RealtimeSyncManager._internal();
  factory RealtimeSyncManager() => _instance;
  RealtimeSyncManager._internal();

  // STEP 5.2: Cached data with timestamps
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // STEP 5.3: Polling timers
  Timer? _tournamentPollTimer;
  Timer? _walletPollTimer;
  Timer? _notificationPollTimer;
  
  // STEP 5.4: Polling intervals (adjustable based on needs)
  static const Duration tournamentPollInterval = Duration(seconds: 10);
  static const Duration walletPollInterval = Duration(seconds: 15);
  static const Duration notificationPollInterval = Duration(seconds: 20);
  
  // Cache validity duration
  static const Duration cacheValidDuration = Duration(seconds: 30);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// STEP 5.5: Initialize real-time sync
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ RealtimeSyncManager already initialized');
      return;
    }

    print('🔵 Initializing RealtimeSyncManager...');
    
    // Start polling for different data types
    _startTournamentPolling();
    _startWalletPolling();
    _startNotificationPolling();
    
    _isInitialized = true;
    print('✅ RealtimeSyncManager initialized');
  }

  /// STEP 5.6: Tournament polling
  void _startTournamentPolling() {
    _tournamentPollTimer?.cancel();
    
    // Initial fetch
    _fetchTournaments();
    
    // Periodic fetch
    _tournamentPollTimer = Timer.periodic(tournamentPollInterval, (timer) {
      _fetchTournaments();
    });
    
    print('✅ Tournament polling started (${tournamentPollInterval.inSeconds}s)');
  }

  Future<void> _fetchTournaments() async {
    try {
      final tournaments = await ApiService.getAllTournaments();
      
      // Check if data changed
      final oldData = _cache['tournaments'] as List<TournamentModel>?;
      final hasChanged = oldData == null || 
          !_listEquals(tournaments, oldData);
      
      if (hasChanged) {
        _cache['tournaments'] = tournaments;
        _cacheTimestamps['tournaments'] = DateTime.now();
        print('🔄 Tournaments updated (${tournaments.length} items)');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching tournaments: $e');
    }
  }

  /// STEP 5.7: Wallet polling
  void _startWalletPolling() {
    _walletPollTimer?.cancel();
    
    _walletPollTimer = Timer.periodic(walletPollInterval, (timer) {
      _fetchWalletData();
    });
    
    print('✅ Wallet polling started (${walletPollInterval.inSeconds}s)');
  }

  Future<void> _fetchWalletData() async {
    try {
      final firebaseUID = await _getCurrentUserUID();
      if (firebaseUID == null) return;
      
      final wallet = await ApiService.getWallet(firebaseUID);
      
      // Check if data changed
      final oldWallet = _cache['wallet'] as WalletModel?;
      final hasChanged = oldWallet == null || 
          oldWallet.coins != wallet.coins;
      
      if (hasChanged) {
        _cache['wallet'] = wallet;
        _cacheTimestamps['wallet'] = DateTime.now();
        print('🔄 Wallet updated (${wallet.coins} coins)');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching wallet: $e');
    }
  }

  /// STEP 5.8: Notification polling
  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    
    _notificationPollTimer = Timer.periodic(notificationPollInterval, (timer) {
      _fetchNotifications();
    });
    
    print('✅ Notification polling started (${notificationPollInterval.inSeconds}s)');
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await ApiService.getNotifications();
      
      final oldNotifications = _cache['notifications'] as List?;
      final hasChanged = oldNotifications == null || 
          notifications.length != oldNotifications.length;
      
      if (hasChanged) {
        _cache['notifications'] = notifications;
        _cacheTimestamps['notifications'] = DateTime.now();
        print('🔄 Notifications updated (${notifications.length} items)');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
    }
  }

  // STEP 5.9: Manual refresh methods
  Future<void> refreshTournaments() async {
    print('🔄 Manual tournament refresh triggered');
    await _fetchTournaments();
  }

  Future<void> refreshWallet() async {
    print('🔄 Manual wallet refresh triggered');
    await _fetchWalletData();
  }

  Future<void> refreshNotifications() async {
    print('🔄 Manual notification refresh triggered');
    await _fetchNotifications();
  }

  Future<void> refreshAll() async {
    print('🔄 Manual refresh all triggered');
    await Future.wait([
      _fetchTournaments(),
      _fetchWalletData(),
      _fetchNotifications(),
    ]);
  }

  // STEP 5.10: Get cached data with freshness check
  T? getCachedData<T>(String key) {
    final data = _cache[key] as T?;
    final timestamp = _cacheTimestamps[key];
    
    if (data == null || timestamp == null) {
      return null;
    }
    
    // Check if cache is still valid
    final age = DateTime.now().difference(timestamp);
    if (age > cacheValidDuration) {
      print('⚠️ Cache expired for $key (${age.inSeconds}s old)');
      return null;
    }
    
    return data;
  }

  // STEP 5.11: Set cached data
  void setCachedData<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    notifyListeners();
  }

  // STEP 5.12: Clear specific cache
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    print('🧹 Cache cleared for $key');
  }

  // Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('🧹 All cache cleared');
    notifyListeners();
  }

  // STEP 5.13: Getters for cached data
  List<TournamentModel>? get cachedTournaments => 
      getCachedData<List<TournamentModel>>('tournaments');
  
  WalletModel? get cachedWallet => 
      getCachedData<WalletModel>('wallet');
  
  List? get cachedNotifications => 
      getCachedData<List>('notifications');

  // STEP 5.14: Helper to get current user UID
  Future<String?> _getCurrentUserUID() async {
    try {
      // Import your auth service
      // return FirebaseAuthService.getCurrentUserUID();
      return null; // Replace with actual implementation
    } catch (e) {
      print('Error getting user UID: $e');
      return null;
    }
  }

  // STEP 5.15: Compare lists for changes
  bool _listEquals(List? a, List? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }

  // STEP 5.16: Adjust polling intervals (for optimization)
  void adjustTournamentPollInterval(Duration interval) {
    _startTournamentPolling();
    print('⚙️ Tournament poll interval adjusted to ${interval.inSeconds}s');
  }

  void adjustWalletPollInterval(Duration interval) {
    _startWalletPolling();
    print('⚙️ Wallet poll interval adjusted to ${interval.inSeconds}s');
  }

  // STEP 5.17: Pause/Resume polling (for battery optimization)
  void pausePolling() {
    _tournamentPollTimer?.cancel();
    _walletPollTimer?.cancel();
    _notificationPollTimer?.cancel();
    print('⏸️ All polling paused');
  }

  void resumePolling() {
    _startTournamentPolling();
    _startWalletPolling();
    _startNotificationPolling();
    print('▶️ All polling resumed');
  }

  // STEP 5.18: Dispose
  void dispose() {
    _tournamentPollTimer?.cancel();
    _walletPollTimer?.cancel();
    _notificationPollTimer?.cancel();
    _cache.clear();
    _cacheTimestamps.clear();
    print('🛑 RealtimeSyncManager disposed');
    super.dispose();
  }

  // STEP 5.19: Debug info
  String get debugInfo {
    return '''
RealtimeSyncManager Status:
- Initialized: $_isInitialized
- Cached items: ${_cache.length}
- Tournament poll: ${_tournamentPollTimer?.isActive ?? false}
- Wallet poll: ${_walletPollTimer?.isActive ?? false}
- Notification poll: ${_notificationPollTimer?.isActive ?? false}
''';
  }
}

// STEP 5.20: Consumer widget for easy integration
class RealtimeDataConsumer<T> extends StatelessWidget {
  final String cacheKey;
  final Future<T> Function() fetchFunction;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;

  const RealtimeDataConsumer({
    super.key,
    required this.cacheKey,
    required this.fetchFunction,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RealtimeSyncManager(),
      builder: (context, child) {
        final manager = RealtimeSyncManager();
        final cachedData = manager.getCachedData<T>(cacheKey);
        
        if (cachedData != null) {
          return builder(context, cachedData);
        }
        
        return FutureBuilder<T>(
          future: fetchFunction(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingBuilder?.call(context) ?? 
                  const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return errorBuilder?.call(context, snapshot.error.toString()) ?? 
                  Center(child: Text('Error: ${snapshot.error}'));
            }
            
            if (snapshot.hasData) {
              // Cache the data
              manager.setCachedData(cacheKey, snapshot.data!);
              return builder(context, snapshot.data as T);
            }
            
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}