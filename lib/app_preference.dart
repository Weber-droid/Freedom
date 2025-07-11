import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as dev show log;
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String tokenKey = 'jwt_token';
  static const String firstTimerKey = 'is_first_timer';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String _deliveryIdKey = 'delivery_id';

  static const String rideIdKey = 'rideId';
  static const String _deliveryStateKey = 'delivery_state_json';

  static String? _cachedToken;
  static bool? _cachedIsFirstTimer;
  static bool? _cachedOnboardingCompleted;

  static Future<String> getToken() async {
    if (_cachedToken != null) return _cachedToken!;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(tokenKey) ?? '';
    return _cachedToken!;
  }

  static Future<String> getRideId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rideId') ?? '';
  }

  static Future<void> setToken(String token) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setString(tokenKey, token);
      _cachedToken = token;
      log('Token saved: $token');
    } catch (e) {
      log('Error saving token: $e');
      rethrow;
    }
  }

  static Future<bool> isFirstTimer() async {
    if (_cachedIsFirstTimer != null) return _cachedIsFirstTimer!;

    final pref = await SharedPreferences.getInstance();
    _cachedIsFirstTimer = pref.getBool(firstTimerKey) ?? true;
    return _cachedIsFirstTimer!;
  }

  static Future<void> setFirstTimer(bool isFirstTimer) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setBool(firstTimerKey, isFirstTimer);
      _cachedIsFirstTimer = isFirstTimer;
      log('First timer flag saved: $isFirstTimer');
    } catch (e) {
      log('Error saving first timer flag: $e');
      rethrow;
    }
  }

  static Future<bool> isOnboardingCompleted() async {
    if (_cachedOnboardingCompleted != null) return _cachedOnboardingCompleted!;

    final pref = await SharedPreferences.getInstance();
    _cachedOnboardingCompleted = pref.getBool(onboardingCompletedKey) ?? false;
    return _cachedOnboardingCompleted!;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final pref = await SharedPreferences.getInstance();
      await pref.setBool(onboardingCompletedKey, completed);
      _cachedOnboardingCompleted = completed;
      log('Onboarding completion flag saved: $completed');
    } catch (e) {
      log('Error saving onboarding completion flag: $e');
      rethrow;
    }
  }

  static Future<void> setRideId(String rideId) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('rideId', rideId);
  }

  static Future<void> setDeliveryId(String deliveryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryIdKey, deliveryId);
  }

  static Future<String?> getDeliveryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deliveryIdKey);
  }

  static Future<void> saveDeliveryState(
    Map<String, dynamic> deliveryStateJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryStateKey, jsonEncode(deliveryStateJson));
  }

  static Future<Map<String, dynamic>?> getDeliveryState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_deliveryStateKey);
    if (stateString != null) {
      try {
        return jsonDecode(stateString) as Map<String, dynamic>;
      } catch (e) {
        dev.log('❌ Error parsing delivery state: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> clearAll() async {
    try {
      _cachedToken = null;
      log('All preferences cleared');
    } catch (e) {
      log('Error clearing preferences: $e');
      rethrow;
    }
  }
}
