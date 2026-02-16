// lib/services/app_state_service.dart

import 'package:flutter/foundation.dart';

/// Singleton service to hold global app state
/// 🚀 CRITICAL: Prevents repeated Firestore reads for user data
class AppStateService {
  // Singleton pattern
  static final AppStateService _instance = AppStateService._internal();
  static AppStateService get instance => _instance;

  AppStateService._internal();

  // User data (cached after first load)
  String _userId = '';
  String _universityId = '';
  String _universityName = '';
  String _userName = '';
  String _userYear = '';

  bool _isSenior = false;

  // Getters
  String get userId => _userId;
  String get universityId => _universityId;
  String get universityName => _universityName;
  String get userName => _userName;
  String get userYear => _userYear;
  bool get isSenior => _isSenior;

  bool get isInitialized => _userId.isNotEmpty;

  /// Initialize app state (called once on app start)
  void initialize({
    required String userId,
    required String universityId,
    required String universityName,
    required String userName,
    required String userYear,
    required bool isSenior,
  }) {
    _userId = userId;
    _universityId = universityId;
    _universityName = universityName;
    _userName = userName;
    _userYear = userYear;
    _isSenior = isSenior;

    debugPrint('✅ AppState initialized: $universityName ($universityId)');
  }

  /// Update university selection
  void updateUniversity({
    required String universityId,
    required String universityName,
  }) {
    _universityId = universityId;
    _universityName = universityName;
    debugPrint('✅ University updated: $universityName ($universityId)');
  }

  /// Clear state (on logout)
  void clear() {
    _userId = '';
    _universityId = '';
    _universityName = '';
    _userName = '';
    _userYear = '';
    _isSenior = false;
    debugPrint('✅ AppState cleared');
  }
}
