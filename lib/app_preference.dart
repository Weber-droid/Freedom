import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  // Keys
  static const String tokenKey = 'jwt_token';
  static const String firstTimerKey = 'is_first_timer';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Cached values
  static String? _cachedToken;
  static bool? _cachedIsFirstTimer;
  static bool? _cachedOnboardingCompleted;

  // Token operations
  static Future<String> getToken() async {
    if (_cachedToken != null) return _cachedToken!;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(tokenKey) ?? '';
    return _cachedToken!;
  }

  static Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      _cachedToken = token;
      log('Token saved: $token');
    } catch (e) {
      log('Error saving token: $e');
      rethrow;
    }
  }

  // First timer operations
  static Future<bool> isFirstTimer() async {
    if (_cachedIsFirstTimer != null) return _cachedIsFirstTimer!;

    final prefs = await SharedPreferences.getInstance();
    _cachedIsFirstTimer = prefs.getBool(firstTimerKey) ?? true;
    return _cachedIsFirstTimer!;
  }

  static Future<void> setFirstTimer(bool isFirstTimer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(firstTimerKey, isFirstTimer);
      _cachedIsFirstTimer = isFirstTimer;
      log('First timer flag saved: $isFirstTimer');
    } catch (e) {
      log('Error saving first timer flag: $e');
      rethrow;
    }
  }

  // Onboarding completion operations
  static Future<bool> isOnboardingCompleted() async {
    if (_cachedOnboardingCompleted != null) return _cachedOnboardingCompleted!;

    final prefs = await SharedPreferences.getInstance();
    _cachedOnboardingCompleted = prefs.getBool(onboardingCompletedKey) ?? false;
    return _cachedOnboardingCompleted!;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingCompletedKey, completed);
      _cachedOnboardingCompleted = completed;
      log('Onboarding completion flag saved: $completed');
    } catch (e) {
      log('Error saving onboarding completion flag: $e');
      rethrow;
    }
  }

  // static Future<void> clearAll() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.clear();
  //     _cachedToken = null;
  //     _cachedIsFirstTimer = null;
  //     _cachedOnboardingCompleted = null;
  //     log('All preferences cleared');
  //   } catch (e) {
  //     log('Error clearing preferences: $e');
  //     rethrow;
  //   }
  // }
}