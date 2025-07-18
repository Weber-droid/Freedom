import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/message_driver/cubit/in_app_message_cubit.dart';

class MessageContextHelper {
  static MessageContextInfo? getCurrentContext(BuildContext context) {
    final rideCubit = context.read<RideCubit>();
    final deliveryCubit = context.read<DeliveryCubit>();

    final rideId = rideCubit.state.driverAccepted?.rideId;
    if (rideId?.isNotEmpty == true) {
      return MessageContextInfo(
        context: MessageContext.ride,
        contextId: rideId!,
        driverName: rideCubit.state.driverAccepted?.driverName ?? 'Driver',
      );
    }

    final deliveryId =
        deliveryCubit.state.deliveryDriverAccepted?.deliveryId ??
        deliveryCubit.state.currentDeliveryId;
    if (deliveryId?.isNotEmpty == true) {
      return MessageContextInfo(
        context: MessageContext.delivery,
        contextId: deliveryId!,
        driverName: 'Delivery Driver',
      );
    }

    return null;
  }
}

class MessageContextInfo {
  final MessageContext context;
  final String contextId;
  final String driverName;

  const MessageContextInfo({
    required this.context,
    required this.contextId,
    required this.driverName,
  });
}
