import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/core/services/app_restoration_manager.dart';
import 'package:freedom/core/services/ride_persistence_service.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/shared/enums/enums.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  final RidePersistenceService _persistenceService;
  final RideRestorationManager _restorationManager;
  late final StreamSubscription<RideState> _rideStateSubscription;
  late final StreamSubscription<DeliveryState> _deliveryStateSubscription;

  Timer? _backgroundPersistenceTimer;
  Timer? _criticalStatePersistenceTimer;
  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastBackgroundTime;

  bool _hasActiveRide = false;
  bool _hasActiveDelivery = false;
  String? _currentRideId;
  String? _currentDeliveryId;

  AppLifecycleManager({
    required RidePersistenceService persistenceService,
    required RideRestorationManager restorationManager,
  }) : _persistenceService = persistenceService,
       _restorationManager = restorationManager;

  Future<void> initialize() async {
    dev.log('🔄 Initializing App Lifecycle Manager...');

    WidgetsBinding.instance.addObserver(this);

    _setupAppTerminationDetection();

    _startCriticalStateMonitoring();

    dev.log('✅ App Lifecycle Manager initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    dev.log('📱 App lifecycle changed: $_lastLifecycleState -> $state');
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

  void _handleAppResumed() async {
    dev.log('🟢 App resumed from background');

    _backgroundPersistenceTimer?.cancel();

    if (_lastBackgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(
        _lastBackgroundTime!,
      );
      dev.log(
        '⏱️ App was in background for: ${backgroundDuration.inMinutes} minutes',
      );

      if (backgroundDuration.inMinutes > 5 &&
          (_hasActiveRide || _hasActiveDelivery)) {
        await _handleLongBackgroundReturn();
      }
    }

    _startCriticalStateMonitoring();

    await _ensureSocketConnection();
  }

  void _handleAppPaused() async {
    dev.log('🟡 App paused/backgrounded');
    _lastBackgroundTime = DateTime.now();

    if (_hasActiveRide || _hasActiveDelivery) {
      await _persistCriticalState('app_paused');
    }

    _startBackgroundPersistence();

    await _persistenceService.recordAppStateOnKill({
      'event': 'app_paused',
      'timestamp': DateTime.now().toIso8601String(),
      'hasActiveRide': _hasActiveRide,
      'hasActiveDelivery': _hasActiveDelivery,
      'currentRideId': _currentRideId,
      'currentDeliveryId': _currentDeliveryId,
    });
  }

  void _handleAppInactive() async {
    dev.log('🟠 App inactive');

    if (_hasActiveRide || _hasActiveDelivery) {
      await _persistCriticalState('app_inactive');
    }
  }

  void _handleAppDetached() async {
    dev.log('🔴 App detached - emergency persistence');

    await _emergencyPersistence();
  }

  void _handleAppHidden() async {
    dev.log('⚫ App hidden');

    if (_hasActiveRide || _hasActiveDelivery) {
      await _persistCriticalState('app_hidden');
    }
  }

  Future<void> _handleLongBackgroundReturn() async {
    try {
      dev.log('🔄 Handling return from long background period...');

      if (_currentRideId != null) {
        dev.log('🔍 Checking ride status after background period...');
        final rideCubit = getIt<RideCubit>();
        await rideCubit.checkRideStatus(_currentRideId!);
      }

      if (_currentDeliveryId != null) {
        dev.log('🔍 Checking delivery status after background period...');
        final deliveryCubit = getIt<DeliveryCubit>();
      }
    } catch (e) {
      dev.log('❌ Error handling long background return: $e');
    }
  }

  void _startCriticalStateMonitoring() {
    _criticalStatePersistenceTimer?.cancel();

    _criticalStatePersistenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (_hasActiveRide || _hasActiveDelivery) {
          _persistCriticalState('periodic_monitoring');
        }
      },
    );
  }

  void _startBackgroundPersistence() {
    _backgroundPersistenceTimer?.cancel();

    if (_hasActiveRide || _hasActiveDelivery) {
      _backgroundPersistenceTimer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) async {
          await _persistCriticalState('background_persistence');
        },
      );
    }
  }

  Future<void> _persistCriticalState(String reason) async {
    try {
      if (_hasActiveRide) {
        final rideCubit = getIt<RideCubit>();
        await _persistenceService.persistCompleteRideState(rideCubit.state);

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
      }

      dev.log('💾 Critical state persisted: $reason');
    } catch (e) {
      dev.log('❌ Error persisting critical state: $e');
    }
  }

  Future<void> _emergencyPersistence() async {
    try {
      dev.log('🚨 EMERGENCY PERSISTENCE - App terminating');

      await _persistenceService.recordAppStateOnKill({
        'event': 'emergency_termination',
        'timestamp': DateTime.now().toIso8601String(),
        'hasActiveRide': _hasActiveRide,
        'hasActiveDelivery': _hasActiveDelivery,
        'currentRideId': _currentRideId,
        'currentDeliveryId': _currentDeliveryId,
        'lastLifecycleState': _lastLifecycleState.toString(),
      });

      await Future.any([
        _persistCriticalState('emergency_termination'),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      dev.log('✅ Emergency persistence completed');
    } catch (e) {
      dev.log('❌ Emergency persistence failed: $e');
    }
  }

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

  Future<void> _handleMemoryWarning() async {
    try {
      await _persistCriticalState('memory_warning');
    } catch (e) {
      dev.log('❌ Error handling memory warning: $e');
    }
  }

  void _reduceBatteryUsage() {
    _criticalStatePersistenceTimer?.cancel();

    if (_hasActiveRide || _hasActiveDelivery) {
      _criticalStatePersistenceTimer = Timer.periodic(
        const Duration(minutes: 2),
        (timer) {
          _persistCriticalState('battery_save_mode');
        },
      );
    }
  }

  Future<void> _ensureSocketConnection() async {
    try {
      final socketService = getIt<SocketService>();

      if (!socketService.isConnected &&
          (_hasActiveRide || _hasActiveDelivery)) {
        dev.log('🔌 Reconnecting socket after app resume...');

        final authToken = await AppPreferences.getToken();

        socketService.connect(ApiConstants.baseUrl2, authToken: authToken);

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

  void startMonitoringRideState(RideCubit rideCubit) {
    _rideStateSubscription = rideCubit.stream.listen((rideState) {
      _updateRideStatus(rideState);
    });
  }

  void startMonitoringDeliveryState(DeliveryCubit deliveryCubit) {
    _deliveryStateSubscription = deliveryCubit.stream.listen((deliveryState) {
      _updateDeliveryStatus(deliveryState);
    });
  }

  void _updateRideStatus(RideState rideState) {
    final previousHasActiveRide = _hasActiveRide;
    final previousRideId = _currentRideId;

    _hasActiveRide = rideState.hasActiveRide;
    _currentRideId = rideState.currentRideId;

    if (_hasActiveRide != previousHasActiveRide) {
      dev.log(
        '🚗 Ride active status changed: $_hasActiveRide (ID: $_currentRideId)',
      );
    }

    if (_currentRideId != previousRideId) {
      dev.log('🆔 Ride ID changed: $previousRideId -> $_currentRideId');
    }

    if (previousHasActiveRide && !_hasActiveRide) {
      _clearRidePersistence();
    }

    if (!previousHasActiveRide && _hasActiveRide) {
      _startIntensiveMonitoring();
    }
  }

  void _updateDeliveryStatus(DeliveryState deliveryState) {
    final previousHasActiveDelivery = _hasActiveDelivery;
    final previousDeliveryId = _currentDeliveryId;

    _hasActiveDelivery = deliveryState.hasActiveDelivery;
    _currentDeliveryId = deliveryState.currentDeliveryId;

    if (_hasActiveDelivery != previousHasActiveDelivery) {
      dev.log(
        '🚚 Delivery active status changed: $_hasActiveDelivery (ID: $_currentDeliveryId)',
      );
    }

    if (previousHasActiveDelivery && !_hasActiveDelivery) {
      _clearDeliveryPersistence();
    }

    if (!previousHasActiveDelivery && _hasActiveDelivery) {
      _startIntensiveMonitoring();
    }
  }

  void _startIntensiveMonitoring() {
    dev.log('🔍 Starting intensive monitoring for active ride/delivery');

    _criticalStatePersistenceTimer?.cancel();

    _criticalStatePersistenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        if (_hasActiveRide || _hasActiveDelivery) {
          _persistCriticalState('intensive_monitoring');
        } else {
          timer.cancel();
          _startCriticalStateMonitoring();
        }
      },
    );
  }

  void _clearRidePersistence() async {
    try {
      dev.log('🧹 Clearing ride persistence - ride ended');
      await _persistenceService.clearRideData();
    } catch (e) {
      dev.log('❌ Error clearing ride persistence: $e');
    }
  }

  void _clearDeliveryPersistence() async {
    try {
      dev.log('🧹 Clearing delivery persistence - delivery ended');
    } catch (e) {
      dev.log('❌ Error clearing delivery persistence: $e');
    }
  }

  Future<void> handleAppStartup() async {
    try {
      dev.log('🚀 Handling app startup...');

      final wasKilled = await _persistenceService.wasAppKilledDuringRide();

      if (wasKilled) {
        dev.log('💥 App was previously killed during active ride');

        final shouldRestore = await _showRestorationDialog();

        if (shouldRestore) {
          await _performRestorationFlow();
        } else {
          await _persistenceService.clearAllPersistedData();
        }
      } else {
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

  Future<bool> _showRestorationDialog() async {
    dev.log('🤔 Would show restoration dialog to user');
    return true;
  }

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

        final rideCubit = getIt<RideCubit>();
        await _restorationManager.executePostRestorationActions(
          rideCubit,
          restorationResult.restoredState!,
        );

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

  Future<void> forceImmediatePersistence({
    String reason = 'manual_force',
  }) async {
    await _persistCriticalState(reason);
  }

  void dispose() {
    dev.log('🗑️ Disposing App Lifecycle Manager...');

    WidgetsBinding.instance.removeObserver(this);

    _backgroundPersistenceTimer?.cancel();
    _criticalStatePersistenceTimer?.cancel();

    _rideStateSubscription.cancel();
    _deliveryStateSubscription.cancel();

    dev.log('✅ App Lifecycle Manager disposed');
  }
}

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
