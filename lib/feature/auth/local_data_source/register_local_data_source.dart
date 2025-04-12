import 'dart:developer';

import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/shared/constants/hive_constants.dart';
import 'package:hive/hive.dart';

class RegisterLocalDataSource {
  // Box instances
  static Box<dynamic>? _authBoxInstance;
  static Box<dynamic>? _userPreferencesBoxInstance;
  static Box<User>? _userBoxInstance;

  // Getters with safety checks
  static Box<dynamic> get _authBox {
    if (_authBoxInstance == null || !_authBoxInstance!.isOpen) {
      _authBoxInstance = Hive.box<dynamic>(authBox);
    }
    return _authBoxInstance!;
  }

  static Box<dynamic> get _userPreferencesBox {
    if (_userPreferencesBoxInstance == null ||
        !_userPreferencesBoxInstance!.isOpen) {
      _userPreferencesBoxInstance = Hive.box<dynamic>(userPreferencesBox);
    }
    return _userPreferencesBoxInstance!;
  }

  static Box<User> get _userBox {
    if (_userBoxInstance == null || !_userBoxInstance!.isOpen) {
      _userBoxInstance = Hive.box<User>(userBox);
    }
    return _userBoxInstance!;
  }

  // Static initialization method
  static Future<void> ensureBoxesAreOpen() async {
    if (!Hive.isBoxOpen(authBox)) {
      _authBoxInstance = await Hive.openBox<dynamic>(authBox);
    } else {
      _authBoxInstance = Hive.box<dynamic>(authBox);
    }

    if (!Hive.isBoxOpen(userPreferencesBox)) {
      _userPreferencesBoxInstance =
          await Hive.openBox<dynamic>(userPreferencesBox);
    } else {
      _userPreferencesBoxInstance = Hive.box<dynamic>(userPreferencesBox);
    }

    if (!Hive.isBoxOpen(userBox)) {
      _userBoxInstance = await Hive.openBox<User>(userBox);
    } else {
      _userBoxInstance = Hive.box<User>(userBox);
    }
  }

  // Cached values to reduce reads
  static String? _cachedJwtToken;
  static bool? _cachedIsAuth;
  static String? _cachedAuthType;
  static String? _cachedFirebaseId;
  static bool? _cachedIsFirstTimer;
  static bool? _cachedOnboardingCompleted;
  static User? _cachedUser;

  // JWT Token operations
  static String getJwtToken() {
    if (_cachedJwtToken != null) return _cachedJwtToken!;

    _cachedJwtToken = _authBox.get(jwtTokenKey, defaultValue: '') as String;
    return _cachedJwtToken!;
  }

  static Future<void> setJwtToken(String jwtToken) async {
    try {
      await _authBox.put(jwtTokenKey, jwtToken);
      _cachedJwtToken = jwtToken;
    } catch (e) {
      log('Error setting JWT token: $e');
      rethrow;
    }
  }

  // Authentication status operations
  static bool checkIsAuth() {
    if (_cachedIsAuth != null) return _cachedIsAuth!;

    _cachedIsAuth = _authBox.get(isLoginKey, defaultValue: false) as bool;
    return _cachedIsAuth!;
  }

  Future<void> changeAuthStatus({bool? authStatus}) async {
    try {
      await _authBox.put(isLoginKey, authStatus);
      _cachedIsAuth = authStatus;
    } catch (e) {
      log('Error changing auth status: $e');
      rethrow;
    }
  }

  // Auth type operations
  static String getAuthType() {
    if (_cachedAuthType != null) return _cachedAuthType!;

    _cachedAuthType = _authBox.get(authTypeKey, defaultValue: '') as String;
    return _cachedAuthType!;
  }

  Future<void> setAuthType(String? authType) async {
    try {
      await _authBox.put(authTypeKey, authType);
      _cachedAuthType = authType;
    } catch (e) {
      log('Error setting auth type: $e');
      rethrow;
    }
  }

  // Firebase ID operations
  static String getUserFirebaseId() {
    if (_cachedFirebaseId != null) return _cachedFirebaseId!;

    _cachedFirebaseId =
        _authBox.get(firebaseIdBoxKey, defaultValue: '') as String;
    return _cachedFirebaseId!;
  }

  Future<void> setUserFirebaseId(String? userId) async {
    try {
      await _authBox.put(firebaseIdBoxKey, userId);
      _cachedFirebaseId = userId;
    } catch (e) {
      log('Error setting user Firebase ID: $e');
      rethrow;
    }
  }

  // First timer status operations
  static bool checkIsFirstTimer() {
    if (_cachedIsFirstTimer != null) return _cachedIsFirstTimer!;

    _cachedIsFirstTimer =
    _userPreferencesBox.get(isFirstTimerKey, defaultValue: true) as bool;
    return _cachedIsFirstTimer!;
  }

  static Future<void> setIsFirstTimer({required bool isFirstTimer}) async {
    try {
      log('ATTEMPTING to set isFirstTimer to: $isFirstTimer');
      await _userPreferencesBox.put(isFirstTimerKey, isFirstTimer);
      _cachedIsFirstTimer = isFirstTimer;
      // Verify the value was actually set
      final verifyValue = _userPreferencesBox.get(isFirstTimerKey, defaultValue: true);
      log('VERIFICATION - isFirstTimer now set to: $verifyValue');
    } catch (e) {
      log('ERROR setting first timer status: $e');
      rethrow;
    }
  }

  // Onboarding status operations
  static bool checkOnboardingCompleted() {
    if (_cachedOnboardingCompleted != null) return _cachedOnboardingCompleted!;

    _cachedOnboardingCompleted = _userPreferencesBox
        .get(isOnboardingCompletedKey, defaultValue: false) as bool;
    return _cachedOnboardingCompleted!;
  }

  Future<void> setOnboardingCompleted({bool? onboardingCompleted}) async {
    try {
      await _userPreferencesBox.put(
          isOnboardingCompletedKey, onboardingCompleted);
      _cachedOnboardingCompleted = onboardingCompleted;
    } catch (e) {
      log('Error setting onboarding completion status: $e');
      rethrow;
    }
  }

  // User data operations
  Future<void> saveUser(User user) async {
    try {
      log('verifyLogin() saving user');
     final check = await _userBox.put(userKey, user);
     log('verifyLogin() user saved successfully');
      _cachedUser = user;
    } catch (e) {
      log('Error saving user data: $e');
      rethrow;
    }
  }

  Future<User?> getUser() async {
    if (_cachedUser != null) return _cachedUser;

    try {
      final user = _userBox.get(userKey);
      log('User from storage: $user');
      _cachedUser = user;
      return user;
    } catch (e) {
      log('Error retrieving user data: $e');
      return null;
    }
  }

  // Cache invalidation - useful when logging out or when cache needs to be refreshed
  static void invalidateCache() {
    _cachedJwtToken = null;
    _cachedIsAuth = null;
    _cachedAuthType = null;
    _cachedFirebaseId = null;
    _cachedIsFirstTimer = null;
    _cachedOnboardingCompleted = null;
    _cachedUser = null;
  }

  // Close boxes when app is shutting down
  static Future<void> closeBoxes() async {
    if (_authBoxInstance != null && _authBoxInstance!.isOpen) {
      await _authBoxInstance!.close();
    }

    if (_userPreferencesBoxInstance != null &&
        _userPreferencesBoxInstance!.isOpen) {
      await _userPreferencesBoxInstance!.close();
    }

    if (_userBoxInstance != null && _userBoxInstance!.isOpen) {
      await _userBoxInstance!.close();
    }
  }
}
