import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ RULE 5: LOCAL CACHING
// Singleton app-level cache to prevent duplicate reads

class FirestoreCache {
  static final FirestoreCache _instance = FirestoreCache._internal();
  factory FirestoreCache() => _instance;
  FirestoreCache._internal();

  // Cache storage
  final Map<String, _CachedData> _cache = {};
  final Map<String, List<DocumentSnapshot>> _queryCache = {};

  // Cache TTL (Time To Live)
  final Duration _userDataTTL = const Duration(minutes: 5);
  final Duration _questionsTTL = const Duration(minutes: 2);
  final Duration _statsTTL = const Duration(minutes: 10);

  // ═══════════════════════════════════════════════════════════
  // USER DATA CACHING
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getCachedUserData(String userId) async {
    final key = 'user_$userId';

    // Check cache
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (!cached.isExpired) {
        print('✅ Cache HIT: User data for $userId');
        return cached.data as Map<String, dynamic>?;
      } else {
        print('⏰ Cache EXPIRED: User data for $userId');
        _cache.remove(key);
      }
    }

    print('❌ Cache MISS: User data for $userId');
    return null;
  }

  void cacheUserData(String userId, Map<String, dynamic> data) {
    final key = 'user_$userId';
    _cache[key] = _CachedData(
      data: data,
      timestamp: DateTime.now(),
      ttl: _userDataTTL,
    );
    print('💾 Cached: User data for $userId');
  }

  void invalidateUserData(String userId) {
    final key = 'user_$userId';
    _cache.remove(key);
    print('🗑️ Invalidated: User data for $userId');
  }

  // ═══════════════════════════════════════════════════════════
  // QUESTIONS FEED CACHING
  // ═══════════════════════════════════════════════════════════

  List<DocumentSnapshot>? getCachedQuestions(String queryKey) {
    if (_queryCache.containsKey(queryKey)) {
      final key = 'questions_$queryKey';
      if (_cache.containsKey(key)) {
        final cached = _cache[key]!;
        if (!cached.isExpired) {
          print('✅ Cache HIT: Questions for $queryKey');
          return _queryCache[queryKey];
        } else {
          print('⏰ Cache EXPIRED: Questions for $queryKey');
          _cache.remove(key);
          _queryCache.remove(queryKey);
        }
      }
    }

    print('❌ Cache MISS: Questions for $queryKey');
    return null;
  }

  void cacheQuestions(String queryKey, List<DocumentSnapshot> questions) {
    _queryCache[queryKey] = questions;
    _cache['questions_$queryKey'] = _CachedData(
      data: questions,
      timestamp: DateTime.now(),
      ttl: _questionsTTL,
    );
    print('💾 Cached: ${questions.length} questions for $queryKey');
  }

  void invalidateQuestions(String queryKey) {
    _cache.remove('questions_$queryKey');
    _queryCache.remove(queryKey);
    print('🗑️ Invalidated: Questions for $queryKey');
  }

  // ═══════════════════════════════════════════════════════════
  // STATS CACHING (for trending, live stats)
  // ═══════════════════════════════════════════════════════════

  Map<String, dynamic>? getCachedStats() {
    const key = 'global_stats';

    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (!cached.isExpired) {
        print('✅ Cache HIT: Global stats');
        return cached.data as Map<String, dynamic>?;
      } else {
        print('⏰ Cache EXPIRED: Global stats');
        _cache.remove(key);
      }
    }

    print('❌ Cache MISS: Global stats');
    return null;
  }

  void cacheStats(Map<String, dynamic> stats) {
    _cache['global_stats'] = _CachedData(
      data: stats,
      timestamp: DateTime.now(),
      ttl: _statsTTL,
    );
    print('💾 Cached: Global stats');
  }

  // ═══════════════════════════════════════════════════════════
  // QUERY DEDUPLICATION (RULE 6)
  // ═══════════════════════════════════════════════════════════

  final Map<String, Future<QuerySnapshot>> _pendingQueries = {};

  Future<QuerySnapshot> deduplicateQuery(
    String queryKey,
    Future<QuerySnapshot> Function() queryFn,
  ) async {
    // If same query is already running, return that Future
    if (_pendingQueries.containsKey(queryKey)) {
      print('🔄 Deduplicating query: $queryKey');
      return _pendingQueries[queryKey]!;
    }

    // Start new query
    print('🚀 Executing query: $queryKey');
    final future = queryFn();
    _pendingQueries[queryKey] = future;

    // Clean up after completion
    future.then((_) {
      _pendingQueries.remove(queryKey);
    }).catchError((error) {
      _pendingQueries.remove(queryKey);
      throw error;
    });

    return future;
  }

  // ═══════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  void clearAllCache() {
    _cache.clear();
    _queryCache.clear();
    _pendingQueries.clear();
    print('🗑️ Cleared ALL cache');
  }

  void clearExpiredCache() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      if (key.startsWith('questions_')) {
        _queryCache.remove(key.replaceFirst('questions_', ''));
      }
    }

    print('🗑️ Cleared ${expiredKeys.length} expired cache entries');
  }

  // ═══════════════════════════════════════════════════════════
  // MEMORY MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  int getCacheSize() {
    return _cache.length;
  }

  void printCacheStats() {
    print('''
    ╔═══════════════════════════════════════╗
    ║       CACHE STATISTICS                ║
    ╠═══════════════════════════════════════╣
    ║ Total entries: ${_cache.length.toString().padLeft(18)} ║
    ║ User data: ${_cache.keys.where((k) => k.startsWith('user_')).length.toString().padLeft(22)} ║
    ║ Questions: ${_queryCache.length.toString().padLeft(22)} ║
    ║ Pending queries: ${_pendingQueries.length.toString().padLeft(16)} ║
    ╚═══════════════════════════════════════╝
    ''');
  }
}

// ═══════════════════════════════════════════════════════════
// CACHED DATA MODEL
// ═══════════════════════════════════════════════════════════

class _CachedData {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  _CachedData({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }

  Duration get remainingTTL {
    final elapsed = DateTime.now().difference(timestamp);
    return ttl - elapsed;
  }
}

// ═══════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ═══════════════════════════════════════════════════════════

/*

// In your screens:

final appState = AppState();

// 1. USER DATA WITH CACHE
Future<Map<String, dynamic>> loadUserData(String userId) async {
  // Check cache first
  var userData = await appState.getCachedUserData(userId);
  
  if (userData == null) {
    // Cache miss - fetch from Firestore
    userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get()
      .then((doc) => doc.data());
    
    if (userData != null) {
      appState.cacheUserData(userId, userData);
    }
  }
  
  return userData!;
}

// 2. QUERY DEDUPLICATION
Future<QuerySnapshot> loadQuestions(String universityId, String branchCode) async {
  final queryKey = '${universityId}_$branchCode';
  
  return await appState.deduplicateQuery(
    queryKey,
    () => FirebaseFirestore.instance
      .collection('questions')
      .where('targetUniversityCode', isEqualTo: universityId)
      .where('targetBranchCode', isEqualTo: branchCode)
      .limit(10)
      .get(),
  );
}

// 3. CACHE INVALIDATION (after updates)
void onProfileUpdated(String userId) {
  appState.invalidateUserData(userId);
}

void onQuestionPosted() {
  appState.invalidateQuestions('home_feed');
}

*/
