// lib/services/cache_service.dart
// NEW FILE - High-performance caching for speed optimization

import 'dart:async';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};

  /// Cache with TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    final entry = _CacheEntry(
      value: value,
      expiry: ttl != null ? DateTime.now().add(ttl) : null,
    );
    _cache[key] = entry;
    print('📦 Cached: $key (TTL: ${ttl?.inSeconds ?? "∞"}s)');
  }

  /// Get from cache
  T? get<T>(String key) {
    final entry = _cache[key];
    
    if (entry == null) {
      return null;
    }

    // Check if expired
    if (entry.expiry != null && DateTime.now().isAfter(entry.expiry!)) {
      _cache.remove(key);
      print('🗑️ Cache expired: $key');
      return null;
    }

    print('✅ Cache hit: $key');
    return entry.value as T?;
  }

  /// Check if key exists and is valid
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.expiry != null && DateTime.now().isAfter(entry.expiry!)) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  /// Invalidate specific key
  void invalidate(String key) {
    _cache.remove(key);
    print('🗑️ Invalidated: $key');
  }

  /// Invalidate keys matching pattern
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    print('🗑️ Invalidated ${keysToRemove.length} keys matching: $pattern');
  }

  /// Clear all cache
  void clear() {
    final count = _cache.length;
    _cache.clear();
    print('🗑️ Cleared $count cache entries');
  }

  /// Get cache stats
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;

    for (final entry in _cache.values) {
      if (entry.expiry == null || now.isBefore(entry.expiry!)) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
    };
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime? expiry;

  _CacheEntry({
    required this.value,
    this.expiry,
  });
}

// Predefined cache keys for consistency
class CacheKeys {
  static const String tournaments = 'tournaments_list';
  static const String userProfile = 'user_profile';
  static const String walletBalance = 'wallet_balance';
  static const String notifications = 'notifications';
  static const String myBookings = 'my_bookings';
  
  static String tournamentDetails(int id) => 'tournament_$id';
  static String tournamentSlots(int id) => 'tournament_${id}_slots';
}

// Predefined TTL durations
class CacheTTL {
  static const Duration tournaments = Duration(minutes: 5);
  static const Duration userProfile = Duration(minutes: 10);
  static const Duration walletBalance = Duration(minutes: 1);
  static const Duration notifications = Duration(minutes: 2);
  static const Duration tournamentDetails = Duration(minutes: 3);
  static const Duration slots = Duration(seconds: 30);
}