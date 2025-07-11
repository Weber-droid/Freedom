import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/message_driver/cache/in_app_message_cache.dart';
import 'package:freedom/feature/message_driver/models/message_models.dart';
import 'package:freedom/feature/message_driver/remote_data_source/message_remote_data_source.dart';

part 'in_app_message_state.dart';

class InAppMessageCubit extends Cubit<InAppMessageState> {
  InAppMessageCubit({
    required this.messageRemoteDataSource,
    required this.driverMessageStream,
  }) : super(InAppMessageInitial());

  final MessageRemoteDataSource messageRemoteDataSource;
  final Stream<DriverMessage> driverMessageStream;
  StreamSubscription<DriverMessage>? _driverMessageSubscription;
  String? _currentUserId;

  Future<void> _initializeCurrentUserId() async {
    _currentUserId ??= await RegisterLocalDataSource().getUser().then(
      (user) => user?.userId,
    );
  }

  void startListeningToDriverMessages(String rideId) {
    _driverMessageSubscription?.cancel();
    _driverMessageSubscription = driverMessageStream.listen(
      (driverMessage) async {
        await _handleIncomingDriverMessage(driverMessage, rideId);
      },
      onError: (error) {
        log('Error listening to driver messages: $error');
      },
    );
  }

  Future<void> _handleIncomingDriverMessage(
    DriverMessage driverMessage,
    String currentRideId,
  ) async {
    try {
      if (driverMessage.notification.rideId != currentRideId) return;

      await _initializeCurrentUserId();

      if (_currentUserId != null &&
          driverMessage.notification.from == _currentUserId) {
        log('Skipping own message to avoid duplicate');
        return;
      }

      final existingMessages = await InAppMessageCache.getMessages(
        currentRideId,
      );
      final messageAlreadyExists = existingMessages.any(
        (msg) =>
            msg.message == driverMessage.notification.body &&
            msg.senderId == driverMessage.notification.from &&
            msg.timestamp?.millisecondsSinceEpoch ==
                DateTime.tryParse(
                  driverMessage.notification.timestamp,
                )?.millisecondsSinceEpoch,
      );

      if (messageAlreadyExists) {
        log('Message already exists, skipping duplicate');
        return;
      }

      final incomingMessage = MessageModels(
        driverMessage.notification.body,
        driverMessage.notification.from,
        DateTime.tryParse(driverMessage.notification.timestamp) ??
            DateTime.now(),
        driverMessage.notification.rideId,
        null,
        null,
        driverMessage.notification.notificationId,
        status: MessageStatus.delivered,
      );

      final cache = InAppMessageCache();
      await cache.addMessage(currentRideId, incomingMessage);

      final updatedMessages = await InAppMessageCache.getMessages(
        currentRideId,
      );
      emit(InAppMessageLoaded(inAppMessages: updatedMessages));

      log('Received new driver message: ${driverMessage.notification.body}');
    } catch (e) {
      log('Error handling incoming driver message: $e');
    }
  }

  Future<void> sendMessage(String messageText, String rideId) async {
    try {
      await _initializeCurrentUserId();

      final currentUserId = _currentUserId ?? '';

      final optimisticTimestamp = DateTime.now();
      final optimisticMessage = MessageModels(
        messageText,
        currentUserId,
        optimisticTimestamp,
        rideId,
        null,
        null,
        null,
        status: MessageStatus.sending,
      );

      final cache = InAppMessageCache();
      await cache.addMessage(rideId, optimisticMessage);

      final currentMessages = await InAppMessageCache.getMessages(rideId);
      emit(InAppMessageLoaded(inAppMessages: currentMessages));

      log('Sending message to server...');
      final response = await messageRemoteDataSource.sendMessage(
        messageText,
        rideId,
      );

      if (response) {
        log('Message sent successfully, updating status to sent');
        await _updateMessageStatus(
          rideId,
          optimisticMessage,
          MessageStatus.sent,
          cache,
        );
      } else {
        log('Failed to send message, updating status to failed');
        await _updateMessageStatus(
          rideId,
          optimisticMessage,
          MessageStatus.failed,
          cache,
        );
        emit(const InAppMessageError(error: 'Failed to send message'));
      }
    } catch (e) {
      log('Exception in sendMessage: $e');
      emit(InAppMessageError(error: 'Failed to send message: $e'));
    }
  }

  Future<void> _updateMessageStatus(
    String rideId,
    MessageModels originalMessage,
    MessageStatus newStatus,
    InAppMessageCache cache,
  ) async {
    try {
      final updatedMessages = await InAppMessageCache.getMessages(rideId);

      final messageIndex = updatedMessages.indexWhere(
        (msg) =>
            msg.message == originalMessage.message &&
            msg.senderId == originalMessage.senderId &&
            msg.timestamp?.millisecondsSinceEpoch ==
                originalMessage.timestamp?.millisecondsSinceEpoch &&
            msg.status == MessageStatus.sending,
      );

      if (messageIndex != -1) {
        updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
          status: newStatus,
        );

        await cache.updateConversationMessages(rideId, updatedMessages);
        emit(InAppMessageLoaded(inAppMessages: updatedMessages));
        log('Successfully updated message status to $newStatus');
      } else {
        log('Message not found for status update');
        await _fallbackUpdateRecentSendingMessage(
          rideId,
          originalMessage,
          newStatus,
          cache,
        );
      }
    } catch (e) {
      log('Error updating message status: $e');
    }
  }

  Future<void> _fallbackUpdateRecentSendingMessage(
    String rideId,
    MessageModels originalMessage,
    MessageStatus newStatus,
    InAppMessageCache cache,
  ) async {
    try {
      final updatedMessages = await InAppMessageCache.getMessages(rideId);

      int messageIndex = -1;
      for (int i = updatedMessages.length - 1; i >= 0; i--) {
        final msg = updatedMessages[i];
        if (msg.senderId == originalMessage.senderId &&
            msg.status == MessageStatus.sending &&
            msg.message == originalMessage.message) {
          messageIndex = i;
          break;
        }
      }

      if (messageIndex != -1) {
        updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
          status: newStatus,
        );

        await cache.updateConversationMessages(rideId, updatedMessages);
        emit(InAppMessageLoaded(inAppMessages: updatedMessages));
        log('Fallback: Successfully updated message status to $newStatus');
      } else {
        log('Fallback: No sending message found to update');
      }
    } catch (e) {
      log('Error in fallback update: $e');
    }
  }

  Future<void> retrieveMessagFromCache() async {
    try {
      emit(InAppMessageLoading());

      const rideStatus = true;
      if (rideStatus) {
        final rideId = await AppPreferences.getRideId();
        final messages = await InAppMessageCache.getMessages(rideId);
        log('Retrieved ${messages.length} messages from cache');
        emit(InAppMessageLoaded(inAppMessages: messages));
      }
    } catch (e) {
      log('Error retrieving messages: $e');
      emit(InAppMessageError(error: e.toString()));
    }
  }

  void stopListeningToDriverMessages() {
    _driverMessageSubscription?.cancel();
    _driverMessageSubscription = null;
  }

  @override
  Future<void> close() {
    stopListeningToDriverMessages();
    return super.close();
  }
}
