// File: lib/core/services/delivery_restoration_service.dart

import 'dart:developer' as dev;
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/repository/models/delivery_status_response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/repository/delivery_repository.dart';
import 'package:freedom/core/services/delivery_persistence_service.dart';

class DeliveryRestorationService {
  final DeliveryRepositoryImpl _deliveryRepository;
  final DeliveryPersistenceService _persistenceService;

  DeliveryRestorationService({
    required DeliveryRepositoryImpl deliveryRepository,
    DeliveryPersistenceService? persistenceService,
  }) : _deliveryRepository = deliveryRepository,
       _persistenceService = persistenceService ?? DeliveryPersistenceService();

  /// Main method to check and restore delivery state
  Future<DeliveryRestorationResult> checkAndRestoreDelivery() async {
    try {
      // Check if there's a persisted delivery session
      final hasSession = await _persistenceService.hasActiveDeliverySession();
      if (!hasSession) {
        dev.log('🔍 No active delivery session found');
        return DeliveryRestorationResult.noSession();
      }

      // Check if session is stale
      final isStale = await _persistenceService.isSessionStale();
      if (isStale) {
        dev.log('🔍 Delivery session is stale, clearing data');
        await _persistenceService.clearAllDeliveryData();
        return DeliveryRestorationResult.staleSession();
      }

      // Get delivery session data
      final sessionData = await _persistenceService.getDeliverySession();
      if (sessionData == null) {
        dev.log('🔍 Failed to retrieve delivery session data');
        return DeliveryRestorationResult.error(
          'Failed to retrieve session data',
        );
      }

      // Check delivery status with server
      final statusResult = await _checkDeliveryStatusWithServer(
        sessionData.deliveryId,
      );
      if (!statusResult.isSuccess) {
        await _persistenceService.clearAllDeliveryData();
        return statusResult;
      }

      // Create restoration data
      final restorationData = DeliveryRestorationData(
        sessionData: sessionData,
        statusData: statusResult.statusData!,
      );

      dev.log(
        '✅ Delivery restoration successful: ${statusResult.statusData!.status}',
      );
      return DeliveryRestorationResult.success(restorationData);
    } catch (e) {
      dev.log('❌ Error during delivery restoration: $e');
      await _persistenceService.clearAllDeliveryData();
      return DeliveryRestorationResult.error('Restoration failed: $e');
    }
  }

  /// Check delivery status with server
  Future<DeliveryRestorationResult> _checkDeliveryStatusWithServer(
    String deliveryId,
  ) async {
    try {
      dev.log('🔍 Checking delivery status with server: $deliveryId');

      final response = await _deliveryRepository.checkDeliveryStatus(
        deliveryId,
      );

      return response.fold(
        (failure) {
          dev.log('❌ Delivery status check failed: ${failure.message}');
          return DeliveryRestorationResult.error(failure.message);
        },
        (statusResponse) {
          if (statusResponse.success && statusResponse.data != null) {
            final statusData = statusResponse.data!;

            // Check if delivery is still active
            if (!statusData.isActive) {
              dev.log('🔍 Delivery is no longer active: ${statusData.status}');
              return DeliveryRestorationResult.completed(statusData.status);
            }

            return DeliveryRestorationResult.serverSuccess(statusData);
          } else {
            dev.log('🔍 Invalid server response');
            return DeliveryRestorationResult.error('Invalid server response');
          }
        },
      );
    } catch (e) {
      dev.log('❌ Server check failed: $e');
      return DeliveryRestorationResult.error('Server check failed: $e');
    }
  }

  /// Create driver data for cubit from status
  Map<String, dynamic> createDriverAcceptedData(DeliveryStatusData statusData) {
    return {
      'delivery_id': statusData.deliveryId,
      'driver_id': 'driver_${statusData.deliveryId}',
      'status': 'accepted',
      'eta': statusData.eta?.text ?? '',
      'eta_seconds': statusData.eta?.value ?? 0,
      'driver_location':
          statusData.driverLocation != null
              ? {
                'latitude': statusData.driverLocation!.latitude,
                'longitude': statusData.driverLocation!.longitude,
                'updated_at': statusData.driverLocation!.updatedAt,
              }
              : null,
    };
  }

  /// Create driver started data for cubit from status
  Map<String, dynamic> createDriverStartedData(DeliveryStatusData statusData) {
    return {
      'delivery_id': statusData.deliveryId,
      'driver_id': 'driver_${statusData.deliveryId}',
      'status': 'in_progress',
      'eta': statusData.eta?.text ?? '',
      'eta_seconds': statusData.eta?.value ?? 0,
    };
  }

  /// Get restoration actions based on delivery status
  List<DeliveryRestorationAction> getRestorationActions(
    DeliveryStatusData statusData,
  ) {
    final actions = <DeliveryRestorationAction>[];

    switch (statusData.status) {
      case 'pending':
        actions.addAll([
          DeliveryRestorationAction.showSearchSheet,
          DeliveryRestorationAction.startSearchTimer,
          DeliveryRestorationAction.setupSocketListeners,
        ]);
        break;

      case 'accepted':
        actions.addAll([
          DeliveryRestorationAction.hideSearchSheet,
          DeliveryRestorationAction.displayStaticRoute,
          DeliveryRestorationAction.setupSocketListeners,
        ]);
        if (statusData.driverLocation != null) {
          actions.add(DeliveryRestorationAction.showDriverMarker);
        }
        break;

      case 'started':
      case 'in_progress':
        actions.addAll([
          DeliveryRestorationAction.hideSearchSheet,
          DeliveryRestorationAction.displayStaticRoute,
          DeliveryRestorationAction.startAnimation,
          DeliveryRestorationAction.startRealTimeTracking,
          DeliveryRestorationAction.setupSocketListeners,
          DeliveryRestorationAction.zoomToStreetLevel,
        ]);
        if (statusData.driverLocation != null) {
          actions.add(DeliveryRestorationAction.showDriverMarker);
        }
        break;

      default:
        actions.add(DeliveryRestorationAction.clearAllData);
    }

    return actions;
  }

  /// Save delivery session when state changes
  Future<void> saveDeliverySession({
    required String deliveryId,
    required DeliveryModel deliveryRequest,
    required Map<String, dynamic> stateData,
  }) async {
    await _persistenceService.saveDeliverySession(
      deliveryId: deliveryId,
      deliveryRequest: deliveryRequest,
      additionalState: {
        ...stateData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Clear all delivery data
  Future<void> clearAllDeliveryData() async {
    await _persistenceService.clearAllDeliveryData();
  }
}

class DeliveryRestorationResult {
  final bool isSuccess;
  final DeliveryRestorationData? data;
  final String? errorMessage;
  final DeliveryRestorationStatus status;
  final DeliveryStatusData? statusData;

  const DeliveryRestorationResult._({
    required this.isSuccess,
    required this.status,
    this.data,
    this.errorMessage,
    this.statusData,
  });

  factory DeliveryRestorationResult.success(DeliveryRestorationData data) {
    return DeliveryRestorationResult._(
      isSuccess: true,
      status: DeliveryRestorationStatus.success,
      data: data,
    );
  }

  factory DeliveryRestorationResult.serverSuccess(
    DeliveryStatusData statusData,
  ) {
    return DeliveryRestorationResult._(
      isSuccess: true,
      status: DeliveryRestorationStatus.success,
      statusData: statusData,
    );
  }

  factory DeliveryRestorationResult.noSession() {
    return const DeliveryRestorationResult._(
      isSuccess: false,
      status: DeliveryRestorationStatus.noSession,
    );
  }

  factory DeliveryRestorationResult.staleSession() {
    return const DeliveryRestorationResult._(
      isSuccess: false,
      status: DeliveryRestorationStatus.staleSession,
    );
  }

  factory DeliveryRestorationResult.completed(String deliveryStatus) {
    return DeliveryRestorationResult._(
      isSuccess: false,
      status: DeliveryRestorationStatus.completed,
      errorMessage: 'Delivery is $deliveryStatus',
    );
  }

  factory DeliveryRestorationResult.error(String message) {
    return DeliveryRestorationResult._(
      isSuccess: false,
      status: DeliveryRestorationStatus.error,
      errorMessage: message,
    );
  }
}

/// Data needed for delivery restoration
class DeliveryRestorationData {
  final DeliverySessionData sessionData;
  final DeliveryStatusData statusData;

  const DeliveryRestorationData({
    required this.sessionData,
    required this.statusData,
  });

  String get deliveryId => sessionData.deliveryId;
  DeliveryModel? get deliveryRequest => sessionData.deliveryRequest;
  Map<String, dynamic>? get additionalState => sessionData.additionalState;

  bool get hasDriverLocation => statusData.driverLocation != null;
  LatLng? get driverPosition => statusData.driverPosition;

  String get status => statusData.status;
  bool get isInProgress => statusData.isInProgress;
}

/// Status of restoration attempt
enum DeliveryRestorationStatus {
  success,
  noSession,
  staleSession,
  completed,
  error,
}

/// Actions to take during restoration
enum DeliveryRestorationAction {
  showSearchSheet,
  hideSearchSheet,
  startSearchTimer,
  displayStaticRoute,
  showDriverMarker,
  startAnimation,
  startRealTimeTracking,
  setupSocketListeners,
  zoomToStreetLevel,
  clearAllData,
}
