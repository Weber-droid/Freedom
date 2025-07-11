// File: lib/core/services/delivery_persistence_service.dart

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freedom/feature/home/models/delivery_model.dart';

class DeliveryPersistenceService {
  static const String _deliveryIdKey = 'delivery_id';
  static const String _deliveryStateKey = 'delivery_state_json';
  static const String _deliveryRequestKey = 'delivery_request_json';

  static final DeliveryPersistenceService _instance =
      DeliveryPersistenceService._internal();
  factory DeliveryPersistenceService() => _instance;
  DeliveryPersistenceService._internal();

  Future<void> saveDeliveryId(String deliveryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deliveryIdKey, deliveryId);
      dev.log('💾 Delivery ID saved: $deliveryId');
    } catch (e) {
      dev.log('❌ Failed to save delivery ID: $e');
    }
  }

  Future<String?> getDeliveryId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deliveryId = prefs.getString(_deliveryIdKey);
      dev.log('📖 Retrieved delivery ID: $deliveryId');
      return deliveryId;
    } catch (e) {
      dev.log('❌ Failed to get delivery ID: $e');
      return null;
    }
  }

  /// Clear delivery ID from SharedPreferences
  Future<void> clearDeliveryId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deliveryIdKey);
      dev.log('🗑️ Delivery ID cleared');
    } catch (e) {
      dev.log('❌ Failed to clear delivery ID: $e');
    }
  }

  // DELIVERY STATE PERSISTENCE

  /// Save delivery state data to SharedPreferences
  Future<void> saveDeliveryState(Map<String, dynamic> stateData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deliveryStateKey, jsonEncode(stateData));
      dev.log('💾 Delivery state saved');
    } catch (e) {
      dev.log('❌ Failed to save delivery state: $e');
    }
  }

  /// Get delivery state data from SharedPreferences
  Future<Map<String, dynamic>?> getDeliveryState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateString = prefs.getString(_deliveryStateKey);
      if (stateString != null) {
        final stateData = jsonDecode(stateString) as Map<String, dynamic>;
        dev.log('📖 Retrieved delivery state');
        return stateData;
      }
      return null;
    } catch (e) {
      dev.log('❌ Failed to get delivery state: $e');
      return null;
    }
  }

  /// Clear delivery state from SharedPreferences
  Future<void> clearDeliveryState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deliveryStateKey);
      dev.log('🗑️ Delivery state cleared');
    } catch (e) {
      dev.log('❌ Failed to clear delivery state: $e');
    }
  }

  // DELIVERY REQUEST PERSISTENCE

  /// Save delivery request model to SharedPreferences
  Future<void> saveDeliveryRequest(DeliveryModel deliveryRequest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _deliveryRequestKey,
        jsonEncode(deliveryRequest.toJson()),
      );
      dev.log('💾 Delivery request saved');
    } catch (e) {
      dev.log('❌ Failed to save delivery request: $e');
    }
  }

  Future<DeliveryModel?> getDeliveryRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestString = prefs.getString(_deliveryRequestKey);
      if (requestString != null) {
        final requestData = jsonDecode(requestString) as Map<String, dynamic>;
        final deliveryRequest = DeliveryModel.fromJson(requestData);
        dev.log('📖 Retrieved delivery request');
        return deliveryRequest;
      }
      return null;
    } catch (e) {
      dev.log('❌ Failed to get delivery request: $e');
      return null;
    }
  }

  Future<void> clearDeliveryRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deliveryRequestKey);
      dev.log('🗑️ Delivery request cleared');
    } catch (e) {
      dev.log('❌ Failed to clear delivery request: $e');
    }
  }

  Future<void> saveDeliverySession({
    required String deliveryId,
    required DeliveryModel deliveryRequest,
    Map<String, dynamic>? additionalState,
  }) async {
    await Future.wait([
      saveDeliveryId(deliveryId),
      saveDeliveryRequest(deliveryRequest),
      if (additionalState != null) saveDeliveryState(additionalState),
    ]);
    dev.log('💾 Complete delivery session saved');
  }

  Future<DeliverySessionData?> getDeliverySession() async {
    final deliveryId = await getDeliveryId();
    if (deliveryId == null) return null;

    final deliveryRequest = await getDeliveryRequest();
    final deliveryState = await getDeliveryState();

    return DeliverySessionData(
      deliveryId: deliveryId,
      deliveryRequest: deliveryRequest,
      additionalState: deliveryState,
    );
  }

  Future<void> clearAllDeliveryData() async {
    await Future.wait([
      clearDeliveryId(),
      clearDeliveryRequest(),
      clearDeliveryState(),
    ]);
    dev.log('🗑️ All delivery data cleared');
  }

  Future<bool> hasActiveDeliverySession() async {
    final deliveryId = await getDeliveryId();
    return deliveryId != null && deliveryId.isNotEmpty;
  }

  Future<Duration?> getSessionAge() async {
    final stateData = await getDeliveryState();
    if (stateData?['timestamp'] != null) {
      try {
        final timestamp = DateTime.parse(stateData!['timestamp']);
        return DateTime.now().difference(timestamp);
      } catch (e) {
        dev.log('❌ Failed to parse session timestamp: $e');
      }
    }
    return null;
  }

  Future<bool> isSessionStale({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final age = await getSessionAge();
    return age != null && age > maxAge;
  }
}

class DeliverySessionData {
  final String deliveryId;
  final DeliveryModel? deliveryRequest;
  final Map<String, dynamic>? additionalState;

  const DeliverySessionData({
    required this.deliveryId,
    this.deliveryRequest,
    this.additionalState,
  });

  bool get hasDeliveryRequest => deliveryRequest != null;
  bool get hasAdditionalState => additionalState != null;

  @override
  String toString() {
    return 'DeliverySessionData('
        'deliveryId: $deliveryId, '
        'hasRequest: $hasDeliveryRequest, '
        'hasState: $hasAdditionalState'
        ')';
  }
}
