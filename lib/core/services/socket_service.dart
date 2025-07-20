import 'package:flutter/foundation.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/services/push_notification_service/push_nofication_service.dart';
import 'package:freedom/core/services/push_notification_service/socket_delivery_model.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  final StreamController<DriverAcceptedModel> _rideStatusUpdatedController =
      StreamController<DriverAcceptedModel>.broadcast();

  final StreamController<DriverArrived> _driverArrivedController =
      StreamController<DriverArrived>.broadcast();
  Stream<DriverArrived> get onDriverArrived => _driverArrivedController.stream;

  Stream<DriverAcceptedModel> get onDriverAcceptRide =>
      _rideStatusUpdatedController.stream;

  final StreamController<DriverCancelled> _driverCancelledController =
      StreamController<DriverCancelled>.broadcast();
  Stream<DriverCancelled> get onDriverCancelled =>
      _driverCancelledController.stream;

  final StreamController<DriverRejected> _driverRejectedController =
      StreamController<DriverRejected>.broadcast();
  Stream<DriverRejected> get onDriverRejected =>
      _driverRejectedController.stream;

  final StreamController<DriverStarted> _driverStartedController =
      StreamController<DriverStarted>.broadcast();
  Stream<DriverStarted> get onDriverStarted => _driverStartedController.stream;

  final StreamController<DriverCompleted> _driverCompletedController =
      StreamController<DriverCompleted>.broadcast();
  Stream<DriverCompleted> get onDriverCompleted =>
      _driverCompletedController.stream;

  final StreamController<DriverMessage> _driverMessageController =
      StreamController<DriverMessage>.broadcast();
  Stream<DriverMessage> get onDriverMessage => _driverMessageController.stream;

  final StreamController<Map<String, dynamic>> _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDriverLocation =>
      _driverLocationController.stream;

  ////For delivery
  final StreamController<DeliveryManAcceptedModel>
  _deliveryManAcceptedController =
      StreamController<DeliveryManAcceptedModel>.broadcast();
  Stream<DeliveryManAcceptedModel> get onDeliveryManAccepted =>
      _deliveryManAcceptedController.stream;

  final StreamController<DeliveryArrived> _deliveryManArrivedController =
      StreamController<DeliveryArrived>.broadcast();
  Stream<DeliveryArrived> get onDeliveryManArrived =>
      _deliveryManArrivedController.stream;

  final StreamController<DeliveryManCancelled> _deliveryManCancelledController =
      StreamController<DeliveryManCancelled>.broadcast();
  Stream<DeliveryManCancelled> get onDeliveryManCancelled =>
      _deliveryManCancelledController.stream;

  final StreamController<DeliveryManRejected> _deliveryManRejectedController =
      StreamController<DeliveryManRejected>.broadcast();
  Stream<DeliveryManRejected> get onDeliveryManRejected =>
      _deliveryManRejectedController.stream;

  final StreamController<DeliveryManStarted> _deliveryManStartedController =
      StreamController<DeliveryManStarted>.broadcast();
  Stream<DeliveryManStarted> get onDeliveryManStarted =>
      _deliveryManStartedController.stream;

  final StreamController<DeliveryManCompleted> _deliveryManCompletedController =
      StreamController<DeliveryManCompleted>.broadcast();
  Stream<DeliveryManCompleted> get onDeliveryManCompleted =>
      _deliveryManCompletedController.stream;

  final StreamController<DeliveryManMessage> _deliveryMessageController =
      StreamController<DeliveryManMessage>.broadcast();
  Stream<DeliveryManMessage> get onDeliveryMessage =>
      _deliveryMessageController.stream;

  final StreamController<Map<String, dynamic>> _deliveryManLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDeliveryManLocation =>
      _deliveryManLocationController.stream;

  bool get isConnected => _isConnected;

  void connect(
    String baseUrl, {
    String? authToken,
    Map<String, dynamic>? query,
  }) {
    if (_socket != null) {
      _socket!.disconnect();
    }

    // Build socket options
    final options =
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableForceNew();

    // Add authentication if provided
    if (authToken?.isNotEmpty == true) {
      options.setAuth({'token': authToken});
    }

    if (query != null) {
      options.setQuery(query);
    }

    _socket = io.io(baseUrl, options.build());

    _setupSocketListeners();

    _socket!.connect();
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      if (kDebugMode) {
        log('Socket.IO connected');
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      if (kDebugMode) {
        print('Socket.IO disconnected');
      }
    });

    _socket!.onConnectError((error) {
      if (kDebugMode) {
        print('Socket.IO connection error: $error');
      }
    });

    _socket!.onError((error) {
      if (kDebugMode) {
        print('Socket.IO error: $error');
      }
    });

    _socket!.on('delivery_status_updated', (data) {
      log('delivery_status_updated: $data');
    });

    // Listen for the driver_accept_ride event
    _socket!.on('ride_status_updated', (data) {
      log('join_delivery: $data');
      try {
        final mapData = data as Map<String, dynamic>;
        AppPreferences.setRideId(mapData['rideId']);
        if (mapData['status'] == 'accepted') {
          final modeled = DriverAcceptedModel.fromJson(mapData);
          getIt<PushNotificationService>().showDriverAcceptNotification(
            driverName: modeled.driverName ?? '',
            vehicleInfo: modeled.motorcycleType ?? '',
          );
          _rideStatusUpdatedController.add(modeled);
        }

        if (mapData['status'] == 'arrived') {
          final modeled = DriverArrived.fromJson(mapData);
          getIt<PushNotificationService>().showDriverArrivedNotification(
            driverName: '',
            vehicleInfo: modeled.status ?? '',
          );
          _driverArrivedController.add(modeled);
        }

        if (mapData['status'] == 'cancelled') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'cancelled',
            message: 'Your ride has been cancelled by the rider.',
          );
          _driverCancelledController.add(DriverCancelled.fromJson(mapData));
        }

        if (mapData['status'] == 'rejected') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'Rejected',
            message: 'Your ride has been completed.',
          );
          _driverRejectedController.add(DriverRejected.fromJson(mapData));
        }

        log('ride_status_updated: $mapData');
        if (mapData['status'] == 'completed') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'completed',
            message: 'Your ride has been completed.',
          );
          _driverCompletedController.add(DriverCompleted.fromJson(mapData));
        }

        if (mapData['status'] == 'in_progress') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'started',
            message: 'Your ride has started.',
          );
          _driverStartedController.add(DriverStarted.fromJson(mapData));
        }
      } catch (e, stackTrace) {
        log('Error parsing ride_status_updated payload: $e\n$stackTrace');
      }
    });

    _socket!.on('ride_message', (data) {
      log('ride_message: $data');
      getIt<PushNotificationService>().showRideStatusNotification(
        status: 'ride_message',
        message: data['notification']['body'] as String,
      );
      _driverMessageController.add(DriverMessage.fromJson(data));
    });

    _socket!.on('driver_location_update', (data) {
      log('Driver location update: $data');
      try {
        _driverLocationController.add(data as Map<String, dynamic>);
      } catch (e, stackTrace) {
        log('Error parsing driver_location payload: $e\n$stackTrace');
      }
    });

    ///Delivery status updated
    _socket!.on('delivery_status_updated', (data) {
      log('delivery_status_updated: $data');
      try {
        final mapData = data as Map<String, dynamic>;
        AppPreferences.setDeliveryId(mapData['deliveryId']);
        if (mapData['status'] == 'accepted') {
          final modeled = DeliveryManAcceptedModel.fromJson(mapData);
          getIt<PushNotificationService>().showDriverAcceptNotification(
            driverName: '',
            vehicleInfo: '',
          );
          log('ride_status_updated: $modeled');
          _deliveryManAcceptedController.add(modeled);
        }

        if (mapData['status'] == 'arrived') {
          final modeled = DeliveryArrived.fromJson(mapData);
          getIt<PushNotificationService>().showDriverArrivedNotification(
            driverName: '',
            vehicleInfo: modeled.status ?? '',
          );
          _deliveryManArrivedController.add(modeled);
        }

        if (mapData['status'] == 'cancelled') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'cancelled',
            message: 'Your ride has been cancelled by the rider.',
          );
          _deliveryManCancelledController.add(
            DeliveryManCancelled.fromJson(mapData),
          );
        }

        if (mapData['status'] == 'rejected') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'Rejected',
            message: 'Your ride has been completed.',
          );
          _deliveryManRejectedController.add(
            DeliveryManRejected.fromJson(mapData),
          );
        }

        log('ride_status_updated: $mapData');
        if (mapData['status'] == 'completed') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'completed',
            message: 'Your ride has been completed.',
          );
          _deliveryManCompletedController.add(
            DeliveryManCompleted.fromJson(mapData),
          );
        }

        if (mapData['status'] == 'in_progress') {
          getIt<PushNotificationService>().showRideStatusNotification(
            status: 'started',
            message: 'Your ride has started.',
          );
          _deliveryManStartedController.add(
            DeliveryManStarted.fromJson(mapData),
          );
        }
      } catch (e, stackTrace) {
        log('Error parsing ride_status_updated payload: $e\n$stackTrace');
      }
    });

    _socket!.on('delivery_message', (data) {
      // log('delivery_message: $data');
      // getIt<PushNotificationService>().showRideStatusNotification(
      //   status: 'delivery_message',
      //   message: data['notification']['body'] as String,
      // );
      // _deliveryMessageController.add(DeliveryManMessage.fromJson(data));
    });
  }

  /// Emit an event to the server
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      if (kDebugMode) {
        print('Cannot emit event: Socket is not connected');
      }
    }
  }

  /// Add a custom listener for any event
  void on(String event, void Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    }
  }

  /// Remove a listener for an event
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  /// Disconnect from the Socket.IO server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Dispose of all resources
  void dispose() {
    disconnect();
  }
}
