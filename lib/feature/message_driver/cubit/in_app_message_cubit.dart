import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/services/push_notification_service/socket_ride_models.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/core/services/unified_driver_message.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/message_driver/cache/in_app_message_cache.dart';
import 'package:freedom/feature/message_driver/models/message_models.dart';
import 'package:freedom/feature/message_driver/remote_data_source/message_remote_data_source.dart';

part 'in_app_message_state.dart';

enum MessageContext { ride, delivery }

class InAppMessageCubit extends Cubit<InAppMessageState> {
  InAppMessageCubit({
    required this.messageRemoteDataSource,
    required this.socketService,
  }) : super(InAppMessageInitial());

  final MessageRemoteDataSource messageRemoteDataSource;
  final SocketService socketService;
  StreamSubscription<UnifiedDriverMessage>? _unifiedMessageSubscription;
  String? _currentUserId;
  String? _currentContextId;
  MessageContext? _currentContext;

  Future<void> _initializeCurrentUserId() async {
    _currentUserId ??= await RegisterLocalDataSource().getUser().then(
      (user) => user?.userId,
    );
  }

  void startListeningToDriverMessages(
    String contextId,
    MessageContext context,
  ) {
    _currentContextId = contextId;
    _currentContext = context;
    _unifiedMessageSubscription?.cancel();

    log(
      'Starting to listen for driver messages for ${context.name}: $contextId',
    );

    final unifiedStream = UnifiedMessageStream.create(socketService);

    _unifiedMessageSubscription = unifiedStream.listen(
      (unifiedMessage) async {
        log(
          'Received unified message: ${unifiedMessage.messageBody} (context: ${unifiedMessage.context.name})',
        );
        await _handleIncomingUnifiedMessage(unifiedMessage, contextId, context);
      },
      onError: (error) {
        log('Error listening to unified messages: $error');
        emit(InAppMessageError(error: 'Connection error: $error'));
      },
    );
  }

  Future<void> _handleIncomingUnifiedMessage(
    UnifiedDriverMessage unifiedMessage,
    String currentContextId,
    MessageContext context,
  ) async {
    try {
      if (unifiedMessage.context != context) {
        log(
          'Skipping message - context mismatch: ${unifiedMessage.context.name} != ${context.name}',
        );
        return;
      }

      // Check if message belongs to current context ID
      if (unifiedMessage.contextId != currentContextId) {
        log(
          'Skipping message - ${context.name} ID mismatch: ${unifiedMessage.contextId} != $currentContextId',
        );
        return;
      }

      await _initializeCurrentUserId();

      if (_currentUserId != null && unifiedMessage.senderId == _currentUserId) {
        log('Skipping own message to avoid duplicate');
        return;
      }

      final existingMessages = await InAppMessageCache.getMessages(
        currentContextId,
      );

      final messageAlreadyExists = existingMessages.any(
        (msg) =>
            msg.message == unifiedMessage.messageBody &&
            msg.senderId == unifiedMessage.senderId,
      );

      if (messageAlreadyExists) {
        log('Message already exists, skipping duplicate');
        return;
      }

      final messageTimestamp = _parseTimestampSafely(unifiedMessage.timeStamp);

      final incomingMessage = MessageModels(
        unifiedMessage.messageBody,
        unifiedMessage.senderId,
        messageTimestamp,
        unifiedMessage.contextId,
        null,
        null,
        unifiedMessage.notificationId,
        status: MessageStatus.delivered,
      );

      log(
        'Adding new message to cache: ${incomingMessage.message} at $messageTimestamp',
      );

      final cache = InAppMessageCache();
      await cache.addMessage(currentContextId, incomingMessage);

      final updatedMessages = await InAppMessageCache.getMessages(
        currentContextId,
      );
      log('Updated messages count: ${updatedMessages.length}');

      emit(InAppMessageLoaded(inAppMessages: updatedMessages));
    } catch (e) {
      log('Error handling incoming unified message: $e');
      emit(InAppMessageError(error: 'Failed to process message: $e'));
    }
  }

  DateTime _parseTimestampSafely(String timestampString) {
    log('Raw timestamp from driver: "$timestampString"');
    log('Current local time: ${DateTime.now()}');

    try {
      final parsedTimestamp = DateTime.tryParse(timestampString);
      if (parsedTimestamp != null) {
        final localTimestamp = parsedTimestamp.toLocal();
        log('Parsed as ISO timestamp: $parsedTimestamp');
        log('Converted to local time: $localTimestamp');
        return localTimestamp;
      }

      final milliseconds = int.tryParse(timestampString);
      if (milliseconds != null) {
        DateTime timestamp;
        if (milliseconds.toString().length == 10) {
          timestamp =
              DateTime.fromMillisecondsSinceEpoch(
                milliseconds * 1000,
                isUtc: true,
              ).toLocal();
          log('Parsed as Unix seconds and converted to local: $timestamp');
        } else {
          timestamp =
              DateTime.fromMillisecondsSinceEpoch(
                milliseconds,
                isUtc: true,
              ).toLocal();
          log('Parsed as milliseconds and converted to local: $timestamp');
        }
        return timestamp;
      }

      log('Could not parse timestamp, using current time');
      return DateTime.now();
    } catch (e) {
      log('Error parsing timestamp: $e, using current time');
      return DateTime.now();
    }
  }

  Future<void> sendMessage(
    String messageText,
    String contextId,
    MessageContext context,
  ) async {
    try {
      await _initializeCurrentUserId();

      final currentUserId = _currentUserId ?? '';
      log('Sending message: $messageText for ${context.name}: $contextId');

      final optimisticTimestamp = DateTime.now();
      final optimisticMessage = MessageModels(
        messageText,
        currentUserId,
        optimisticTimestamp,
        contextId,
        null,
        null,
        null,
        status: MessageStatus.sending,
      );

      final cache = InAppMessageCache();
      await cache.addMessage(contextId, optimisticMessage);

      final currentMessages = await InAppMessageCache.getMessages(contextId);
      emit(InAppMessageLoaded(inAppMessages: currentMessages));

      log('Sending message to server...');
      final response = await _sendMessageToServer(
        messageText,
        contextId,
        context,
      );

      if (response) {
        log('Message sent successfully, updating status to sent');
        await _updateMessageStatus(
          contextId,
          optimisticMessage,
          MessageStatus.sent,
          cache,
        );
      } else {
        log('Failed to send message, updating status to failed');
        await _updateMessageStatus(
          contextId,
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

  Future<bool> _sendMessageToServer(
    String messageText,
    String contextId,
    MessageContext context,
  ) async {
    switch (context) {
      case MessageContext.ride:
        return await messageRemoteDataSource.sendMessage(
          messageText,
          contextId,
        );
      case MessageContext.delivery:
        return await messageRemoteDataSource.sendDeliveryMessage(
          messageText,
          contextId,
        );
    }
  }

  Future<void> retrieveMessagesFromCache(
    String? contextId,
    MessageContext context,
  ) async {
    try {
      emit(InAppMessageLoading());

      final effectiveContextId =
          contextId ?? await _getContextIdFromPreferences(context);
      if (effectiveContextId.isEmpty) {
        emit(const InAppMessageError(error: 'No active context found'));
        return;
      }

      _currentContextId = effectiveContextId;
      _currentContext = context;

      final messages = await InAppMessageCache.getMessages(effectiveContextId);
      log(
        'Retrieved ${messages.length} messages from cache for ${context.name}: $effectiveContextId',
      );
      emit(InAppMessageLoaded(inAppMessages: messages));
    } catch (e) {
      log('Error retrieving messages: $e');
      emit(InAppMessageError(error: e.toString()));
    }
  }

  Future<String> _getContextIdFromPreferences(MessageContext context) async {
    switch (context) {
      case MessageContext.ride:
        return await AppPreferences.getRideId();
      case MessageContext.delivery:
        return await AppPreferences.getRideId();
    }
  }

  Future<void> refreshMessages() async {
    try {
      if (_currentContextId != null && _currentContext != null) {
        final messages = await InAppMessageCache.getMessages(
          _currentContextId!,
        );
        log('Refreshed messages count: ${messages.length}');
        emit(InAppMessageLoaded(inAppMessages: messages));
      }
    } catch (e) {
      log('Error refreshing messages: $e');
      emit(InAppMessageError(error: 'Failed to refresh messages: $e'));
    }
  }

  Future<void> _updateMessageStatus(
    String contextId,
    MessageModels originalMessage,
    MessageStatus newStatus,
    InAppMessageCache cache,
  ) async {
    try {
      final updatedMessages = await InAppMessageCache.getMessages(contextId);

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

        await cache.updateConversationMessages(contextId, updatedMessages);
        emit(InAppMessageLoaded(inAppMessages: updatedMessages));
        log('Successfully updated message status to $newStatus');
      } else {
        log('Message not found for status update');
        await _fallbackUpdateRecentSendingMessage(
          contextId,
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
    String contextId,
    MessageModels originalMessage,
    MessageStatus newStatus,
    InAppMessageCache cache,
  ) async {
    try {
      final updatedMessages = await InAppMessageCache.getMessages(contextId);

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

        await cache.updateConversationMessages(contextId, updatedMessages);
        emit(InAppMessageLoaded(inAppMessages: updatedMessages));
        log('Fallback: Successfully updated message status to $newStatus');
      } else {
        log('Fallback: No sending message found to update');
      }
    } catch (e) {
      log('Error in fallback update: $e');
    }
  }

  void stopListeningToDriverMessages() {
    _unifiedMessageSubscription?.cancel();
    _unifiedMessageSubscription = null;
    log('Stopped listening to driver messages');
  }

  @override
  Future<void> close() {
    stopListeningToDriverMessages();
    return super.close();
  }
}
