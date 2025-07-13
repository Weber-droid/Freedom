import 'dart:developer' as dev;

import 'package:freedom/core/services/delivery_persistence_service.dart';

bool shouldResumeRealTimeTracking(PersistedDeliveryData persistedData) {
  final deliveryInProgress = persistedData.deliveryInProgress;

  final driverAccepted =
      persistedData.deliveryDriverAccepted?.status == 'accepted';

  final driverStarted =
      persistedData.deliveryDriverStarted?.status == 'in_progress';

  final wasTrackingActive = persistedData.isRealTimeDeliveryTrackingActive;

  final driverArrived = persistedData.deliveryDriverHasArrived;

  final hasDriverId =
      persistedData.deliveryDriverAccepted?.driverId?.isNotEmpty == true ||
      persistedData.deliveryStatusResponse?.driverId?.isNotEmpty == true;

  dev.log('Tracking resume conditions:');
  dev.log('- deliveryInProgress: $deliveryInProgress');
  dev.log('- driverAccepted: $driverAccepted');
  dev.log('- driverStarted: $driverStarted');
  dev.log('- wasTrackingActive: $wasTrackingActive');
  dev.log('- driverArrived: $driverArrived');
  dev.log('- hasDriverId: $hasDriverId');
  return hasDriverId &&
      (deliveryInProgress ||
          driverStarted ||
          wasTrackingActive ||
          (driverAccepted && driverArrived));
}

String getDriverId(PersistedDeliveryData persistedData) {
  String driverId = '';

  if (persistedData.deliveryDriverAccepted?.driverId?.isNotEmpty == true) {
    driverId = persistedData.deliveryDriverAccepted!.driverId!;
    dev.log('✅ Using driver ID from deliveryDriverAccepted: $driverId');
  } else if (persistedData.deliveryStatusResponse?.driverId?.isNotEmpty ==
      true) {
    driverId = persistedData.deliveryStatusResponse!.driverId!;
    dev.log('✅ Using driver ID from deliveryStatusResponse: $driverId');
  } else {
    dev.log('❌ No driver ID found in persisted data');
    dev.log(
      '   - deliveryDriverAccepted.driverId: ${persistedData.deliveryDriverAccepted?.driverId}',
    );
    dev.log(
      '   - deliveryStatusResponse.driverId: ${persistedData.deliveryStatusResponse?.driverId}',
    );
    dev.log(
      '   - deliveryDriverStarted only has: deliveryId, status (no driverId)',
    );
  }

  return driverId;
}
