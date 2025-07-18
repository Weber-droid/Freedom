import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/services/app_restoration_manager.dart';
import 'package:freedom/core/services/ride_persistence_service.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/shared/enums/enums.dart';

/// Manages app lifecycle events and handles persistence accordingly
class AppLifecycleManager extends WidgetsBindingObserver {
  final RidePersistenceService _persistenceService;
  final RideRestorationManager _restorationManager;
  late final StreamSubscription<RideState> _rideStateSubscription;
  late final StreamSubscription<DeliveryState> _deliveryStateSubscription;

  Timer? _backgroundPersistenceTimer;
  Timer? _criticalStatePersistenceTimer;
  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastBackgroundTime;

  // Critical state tracking
  bool _hasActiveRide = false;
  bool _hasActiveDelivery = false;
  String? _currentRideId;
  String? _currentDeliveryId;

  AppLifecycleManager({
    required RidePersistenceService persistenceService,
    required RideRestorationManager restorationManager,
  }) : _persistenceService = persistenceService,
       _restorationManager = restorationManager;

  /// Initialize the lifecycle manager
  Future<void> initialize() async {
    dev.log('🔄 Initializing App Lifecycle Manager...');

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Set up method channel for app termination detection
    _setupAppTerminationDetection();

    // Start monitoring critical states
    _startCriticalStateMonitoring();

    dev.log('✅ App Lifecycle Manager initialized');
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    dev.log('📱 App lifecycle changed: ${_lastLifecycleState} -> $state');
    _lastLifecycleState = state;

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Handle app resumed from background
  void _handleAppResumed() async {
    dev.log('🟢 App resumed from background');

    // Stop background persistence timer
    _backgroundPersistenceTimer?.cancel();

    // Check if app was in background for significant time
    if (_lastBackgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(
        _lastBackgroundTime!,
      );
      dev.log(
        '⏱️ App was in background for: ${backgroundDuration.inMinutes} minutes',
      );

      // If app was in background for more than 5 minutes and we have active ride,
      // check for updates from server
      if (backgroundDuration.inMinutes > 5 &&
          (_hasActiveRide || _hasActiveDelivery)) {
        await _handleLongBackgroundReturn();
      }
    }

    // Restart critical state monitoring
    _startCriticalStateMonitoring();

    // Reconnect socket if needed
    await _ensureSocketConnection();
  }

  /// Handle app going to background/paused
  void _handleAppPaused() async {
    dev.log('🟡 App paused/backgrounded');
    _lastBackgroundTime = DateTime.now();

    // Immediately persist current state if we have active ride/delivery
    if (_hasActiveRide || _hasActiveDelivery) {
      await _persistCriticalState('app_paused');
    }

    // Start aggressive background persistence
    _startBackgroundPersistence();

    // Record background event
    await _persistenceService.recordAppStateOnKill({
      'event': 'app_paused',
      'timestamp': DateTime.now().toIso8601String(),
      'hasActiveRide': _hasActiveRide,
      'hasActiveDelivery': _hasActiveDelivery,
      'currentRideId': _currentRideId,
      'currentDeliveryId': _currentDeliveryId,
    });
  }

  /// Handle app inactive state
  void _handleAppInactive() async {
    dev.log('🟠 App inactive');

    // Quick persistence for inactive state
    if (_hasActiveRide || _hasActiveDelivery) {
      await _persistCriticalState('app_inactive');
    }
  }

  /// Handle app detached (process about to be killed)
  void _handleAppDetached() async {
    dev.log('🔴 App detached - emergency persistence');

    // Emergency persistence - this is our last chance
    await _emergencyPersistence();
  }

  /// Handle app hidden
  void _handleAppHidden() async {
    dev.log('⚫ App hidden');

    if (_hasActiveRide || _hasActiveDelivery) {
      await _persistCriticalState('app_hidden');
    }
  }

  /// Handle return from long background period
  Future<void> _handleLongBackgroundReturn() async {
    try {
      dev.log('🔄 Handling return from long background period...');

      // Check for ride status updates
      if (_currentRideId != null) {
        dev.log('🔍 Checking ride status after background period...');
        final rideCubit = getIt<RideCubit>();
        await rideCubit.checkRideStatus(_currentRideId!);
      }

      // Check for delivery status updates
      if (_currentDeliveryId != null) {
        dev.log('🔍 Checking delivery status after background period...');
        final deliveryCubit = getIt<DeliveryCubit>();
      }
    } catch (e) {
      dev.log('❌ Error handling long background return: $e');
    }
  }

  /// Start monitoring critical states
  void _startCriticalStateMonitoring() {
    _criticalStatePersistenceTimer?.cancel();

    // Monitor every 30 seconds when we have active ride/delivery
    _criticalStatePersistenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (_hasActiveRide || _hasActiveDelivery) {
          _persistCriticalState('periodic_monitoring');
        }
      },
    );
  }

  /// Start aggressive background persistence
  void _startBackgroundPersistence() {
    _backgroundPersistenceTimer?.cancel();

    // Persist every 10 seconds while in background with active ride
    if (_hasActiveRide || _hasActiveDelivery) {
      _backgroundPersistenceTimer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) async {
          await _persistCriticalState('background_persistence');
        },
      );
    }
  }

  /// Persist critical state immediately
  Future<void> _persistCriticalState(String reason) async {
    try {
      if (_hasActiveRide) {
        final rideCubit = getIt<RideCubit>();
        await _persistenceService.persistCompleteRideState(rideCubit.state);

        // Also persist current driver location if available
        final currentPosition = rideCubit.state.currentDriverPosition;
        if (currentPosition != null) {
          await _persistenceService.persistDriverLocation(
            currentPosition,
            speed: rideCubit.state.currentSpeed,
            timestamp: rideCubit.state.lastPositionUpdate,
          );
        }
      }

      if (_hasActiveDelivery) {
        final deliveryCubit = getIt<DeliveryCubit>();
        // Persist delivery state (implement similar method for delivery)
        // await _persistenceService.persistCompleteDeliveryState(deliveryCubit.state);
      }

      dev.log('💾 Critical state persisted: $reason');
    } catch (e) {
      dev.log('❌ Error persisting critical state: $e');
    }
  }

  /// Emergency persistence for app termination
  Future<void> _emergencyPersistence() async {
    try {
      dev.log('🚨 EMERGENCY PERSISTENCE - App terminating');

      // Record termination event
      await _persistenceService.recordAppStateOnKill({
        'event': 'emergency_termination',
        'timestamp': DateTime.now().toIso8601String(),
        'hasActiveRide': _hasActiveRide,
        'hasActiveDelivery': _hasActiveDelivery,
        'currentRideId': _currentRideId,
        'currentDeliveryId': _currentDeliveryId,
        'lastLifecycleState': _lastLifecycleState.toString(),
      });

      // Emergency state persistence with timeout
      await Future.any([
        _persistCriticalState('emergency_termination'),
        Future.delayed(
          const Duration(seconds: 2),
        ), // Max 2 seconds for emergency
      ]);

      dev.log('✅ Emergency persistence completed');
    } catch (e) {
      dev.log('❌ Emergency persistence failed: $e');
    }
  }

  /// Setup app termination detection using method channels
  void _setupAppTerminationDetection() {
    const platform = MethodChannel('app_lifecycle');

    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppTerminating':
          dev.log('📱 Native app termination detected');
          await _emergencyPersistence();
          break;
        case 'onMemoryWarning':
          dev.log('⚠️ Memory warning - performing cleanup');
          await _handleMemoryWarning();
          break;
        case 'onBatteryLow':
          dev.log('🔋 Battery low - reducing background activity');
          _reduceBatteryUsage();
          break;
      }
    });
  }

  /// Handle memory warning
  Future<void> _handleMemoryWarning() async {
    try {
      // Persist immediately before potential memory cleanup
      await _persistCriticalState('memory_warning');

      // Clear non-essential cached data
      // You can add specific cleanup logic here
    } catch (e) {
      dev.log('❌ Error handling memory warning: $e');
    }
  }

  /// Reduce battery usage during low battery
  void _reduceBatteryUsage() {
    // Reduce persistence frequency during low battery
    _criticalStatePersistenceTimer?.cancel();

    if (_hasActiveRide || _hasActiveDelivery) {
      _criticalStatePersistenceTimer = Timer.periodic(
        const Duration(minutes: 2), // Reduce from 30 seconds to 2 minutes
        (timer) {
          _persistCriticalState('battery_save_mode');
        },
      );
    }
  }

  /// Ensure socket connection is active
  Future<void> _ensureSocketConnection() async {
    try {
      final socketService = getIt<SocketService>();

      if (!socketService.isConnected &&
          (_hasActiveRide || _hasActiveDelivery)) {
        dev.log('🔌 Reconnecting socket after app resume...');

        // Get fresh auth token
        final authToken = await AppPreferences.getToken();

        socketService.connect(
          'wss://your-socket-server.com',
          authToken: authToken,
        );

        // Wait for connection
        await Future.delayed(const Duration(seconds: 3));

        if (socketService.isConnected) {
          dev.log('✅ Socket reconnected successfully');
        } else {
          dev.log('❌ Failed to reconnect socket');
        }
      }
    } catch (e) {
      dev.log('❌ Error ensuring socket connection: $e');
    }
  }

  /// Start monitoring ride state changes
  void startMonitoringRideState(RideCubit rideCubit) {
    _rideStateSubscription = rideCubit.stream.listen((rideState) {
      _updateRideStatus(rideState);
    });
  }

  /// Start monitoring delivery state changes
  void startMonitoringDeliveryState(DeliveryCubit deliveryCubit) {
    _deliveryStateSubscription = deliveryCubit.stream.listen((deliveryState) {
      _updateDeliveryStatus(deliveryState);
    });
  }

  /// Update ride status tracking
  void _updateRideStatus(RideState rideState) {
    final previousHasActiveRide = _hasActiveRide;
    final previousRideId = _currentRideId;

    // Determine if we have an active ride
    _hasActiveRide = rideState.hasActiveRide;
    _currentRideId = rideState.currentRideId;

    // Log state changes
    if (_hasActiveRide != previousHasActiveRide) {
      dev.log(
        '🚗 Ride active status changed: $_hasActiveRide (ID: $_currentRideId)',
      );
    }

    if (_currentRideId != previousRideId) {
      dev.log('🆔 Ride ID changed: $previousRideId -> $_currentRideId');
    }

    // If ride ended, clear persistence
    if (previousHasActiveRide && !_hasActiveRide) {
      _clearRidePersistence();
    }

    // If ride started, begin intensive monitoring
    if (!previousHasActiveRide && _hasActiveRide) {
      _startIntensiveMonitoring();
    }
  }

  /// Update delivery status tracking
  void _updateDeliveryStatus(DeliveryState deliveryState) {
    final previousHasActiveDelivery = _hasActiveDelivery;
    final previousDeliveryId = _currentDeliveryId;

    // Determine if we have an active delivery
    _hasActiveDelivery =
        deliveryState.hasActiveDelivery; // Implement this property
    _currentDeliveryId =
        deliveryState.currentDeliveryId; // Implement this property

    // Log state changes
    if (_hasActiveDelivery != previousHasActiveDelivery) {
      dev.log(
        '🚚 Delivery active status changed: $_hasActiveDelivery (ID: $_currentDeliveryId)',
      );
    }

    // Similar logic as ride state
    if (previousHasActiveDelivery && !_hasActiveDelivery) {
      _clearDeliveryPersistence();
    }

    if (!previousHasActiveDelivery && _hasActiveDelivery) {
      _startIntensiveMonitoring();
    }
  }

  /// Start intensive monitoring for active rides/deliveries
  void _startIntensiveMonitoring() {
    dev.log('🔍 Starting intensive monitoring for active ride/delivery');

    // Cancel existing timer
    _criticalStatePersistenceTimer?.cancel();

    // Start more frequent monitoring (every 15 seconds)
    _criticalStatePersistenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        if (_hasActiveRide || _hasActiveDelivery) {
          _persistCriticalState('intensive_monitoring');
        } else {
          // No active rides/deliveries, reduce frequency
          timer.cancel();
          _startCriticalStateMonitoring();
        }
      },
    );
  }

  /// Clear ride persistence when ride ends
  void _clearRidePersistence() async {
    try {
      dev.log('🧹 Clearing ride persistence - ride ended');
      await _persistenceService.clearRideData();
    } catch (e) {
      dev.log('❌ Error clearing ride persistence: $e');
    }
  }

  /// Clear delivery persistence when delivery ends
  void _clearDeliveryPersistence() async {
    try {
      dev.log('🧹 Clearing delivery persistence - delivery ended');
      // Implement delivery-specific clearing if needed
      // await _persistenceService.clearDeliveryData();
    } catch (e) {
      dev.log('❌ Error clearing delivery persistence: $e');
    }
  }

  /// Handle app startup and restoration
  Future<void> handleAppStartup() async {
    try {
      dev.log('🚀 Handling app startup...');

      // Check if app was killed during active ride
      final wasKilled = await _persistenceService.wasAppKilledDuringRide();

      if (wasKilled) {
        dev.log('💥 App was previously killed during active ride');

        // Show restoration dialog to user
        final shouldRestore = await _showRestorationDialog();

        if (shouldRestore) {
          await _performRestorationFlow();
        } else {
          // User declined restoration, clear data
          await _persistenceService.clearAllPersistedData();
        }
      } else {
        // Normal startup, check for any persisted data
        final hasPersistedData = await _persistenceService.hasActiveRide();

        if (hasPersistedData) {
          dev.log('📱 Found persisted data on normal startup');
          await _performRestorationFlow();
        }
      }
    } catch (e) {
      dev.log('❌ Error handling app startup: $e');
    }
  }

  /// Show restoration dialog to user
  Future<bool> _showRestorationDialog() async {
    // This would typically be implemented in your UI layer
    // For now, we'll auto-restore
    dev.log('🤔 Would show restoration dialog to user');
    return true; // Auto-restore for now
  }

  /// Perform the complete restoration flow
  Future<void> _performRestorationFlow() async {
    try {
      dev.log('🔄 Performing restoration flow...');

      final restorationResult =
          await _restorationManager.attemptRideRestoration();

      if (restorationResult.success &&
          restorationResult.restoredState != null) {
        dev.log(
          '✅ Restoration successful: ${restorationResult.restoredState!.message}',
        );

        // Execute post-restoration actions
        final rideCubit = getIt<RideCubit>();
        await _restorationManager.executePostRestorationActions(
          rideCubit,
          restorationResult.restoredState!,
        );

        // Update our monitoring state
        _updateRideStatus(restorationResult.restoredState!.rideState);
      } else {
        dev.log('❌ Restoration failed: ${restorationResult.error}');
        await _persistenceService.clearAllPersistedData();
      }
    } catch (e) {
      dev.log('❌ Error in restoration flow: $e');
      await _persistenceService.clearAllPersistedData();
    }
  }

  /// Get current monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'hasActiveRide': _hasActiveRide,
      'hasActiveDelivery': _hasActiveDelivery,
      'currentRideId': _currentRideId,
      'currentDeliveryId': _currentDeliveryId,
      'lastLifecycleState': _lastLifecycleState?.toString(),
      'lastBackgroundTime': _lastBackgroundTime?.toIso8601String(),
      'backgroundDuration':
          _lastBackgroundTime != null
              ? DateTime.now().difference(_lastBackgroundTime!).toString()
              : null,
      'isMonitoringActive': _criticalStatePersistenceTimer?.isActive ?? false,
      'isBackgroundPersisting': _backgroundPersistenceTimer?.isActive ?? false,
    };
  }

  /// Force immediate persistence (for testing or critical situations)
  Future<void> forceImmediatePersistence({
    String reason = 'manual_force',
  }) async {
    await _persistCriticalState(reason);
  }

  /// Dispose of the lifecycle manager
  void dispose() {
    dev.log('🗑️ Disposing App Lifecycle Manager...');

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel timers
    _backgroundPersistenceTimer?.cancel();
    _criticalStatePersistenceTimer?.cancel();

    // Cancel subscriptions
    _rideStateSubscription.cancel();
    _deliveryStateSubscription.cancel();

    dev.log('✅ App Lifecycle Manager disposed');
  }
}

/// Extension to add hasActiveRide property to RideState
extension RideStateExtensions on RideState {
  bool get hasActiveRide {
    return currentRideId != null &&
        (status == RideRequestStatus.searching ||
            status == RideRequestStatus.success ||
            rideInProgress ||
            showRiderFound ||
            isRealTimeTrackingActive);
  }
}
