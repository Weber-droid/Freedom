import 'dart:developer';

import 'package:freedom/feature/message_driver/models/message_models.dart';
import 'package:hive/hive.dart';

class InAppMessageCache {
  static String boxName = 'in_app_message';
  static Box<Conversation>? _box;

  static Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        _box = await Hive.openBox<Conversation>(boxName);
      } else {
        _box = Hive.box<Conversation>(boxName);
      }
    } catch (e) {
      _box = Hive.box<Conversation>(boxName);
    }
  }

  static Box<Conversation> get _getBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('Box not initialized. Call init() first.');
    }
    return _box!;
  }

  void saveMessage(Conversation message) {
    _getBox.put(
        message.rideId,
        Conversation(
          message.rideId,
          message.messages,
          message.driverId,
          message.userId,
        ));
  }

  Future<void> addMessage(String rideId, MessageModels message) async {
    final box = _getBox;
    final convo = box.get(rideId);
    if (convo != null) {
      // Create new list to ensure Hive detects the change
      final updatedMessages = List<MessageModels>.from(convo.messages)
        ..add(message);
      final updatedConvo = Conversation(
        convo.rideId,
        updatedMessages,
        convo.driverId,
        convo.userId,
      );
      await box.put(rideId, updatedConvo);
      log('Added new message to conversation. Total messages: ${updatedMessages.length}');
    } else {
      // Create new conversation if it doesn't exist
      final newConvo = Conversation(
        rideId,
        [message],
        '', // You might want to pass driverId here
        message.senderId ?? '',
      );
      await box.put(rideId, newConvo);
      log('Created new conversation with first message');
    }
  }

  // Optimized method to update entire conversation messages
  Future<void> updateConversationMessages(
      String rideId, List<MessageModels> updatedMessages) async {
    final box = _getBox;
    final convo = box.get(rideId);

    if (convo != null) {
      // Create completely new conversation object to ensure Hive detects changes
      final updatedConvo = Conversation(
        convo.rideId,
        List<MessageModels>.from(updatedMessages), // Create new list
        convo.driverId,
        convo.userId,
      );
      await box.put(rideId, updatedConvo);
      log('Successfully updated conversation with ${updatedMessages.length} messages');
    } else {
      log('No conversation found for rideId: $rideId');
    }
  }

  // Optimized method to update a specific message by exact match
  Future<bool> updateSpecificMessage(String rideId,
      MessageModels originalMessage, MessageModels updatedMessage) async {
    final box = _getBox;
    final convo = box.get(rideId);

    if (convo != null) {
      final messages = List<MessageModels>.from(convo.messages);

      // Find exact message match
      final messageIndex = messages.indexWhere((msg) =>
          msg.message == originalMessage.message &&
          msg.senderId == originalMessage.senderId &&
          msg.timestamp?.millisecondsSinceEpoch ==
              originalMessage.timestamp?.millisecondsSinceEpoch &&
          msg.status == originalMessage.status);

      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;

        final updatedConvo = Conversation(
          convo.rideId,
          messages,
          convo.driverId,
          convo.userId,
        );

        await box.put(rideId, updatedConvo);
        log('Successfully updated specific message at index $messageIndex');
        return true;
      } else {
        log('Specific message not found for update');
        return false;
      }
    } else {
      log('No conversation found for rideId: $rideId');
      return false;
    }
  }

  // Legacy update methods (keep for backward compatibility)
  Future<void> updateMessageById(
      String rideId, String tempId, MessageModels updatedMessage) async {
    final box = _getBox;
    final convo = box.get(rideId);

    if (convo != null) {
      final messages = List<MessageModels>.from(convo.messages);
      final messageIndex = messages.indexWhere((msg) =>
          msg.timestamp?.millisecondsSinceEpoch.toString() == tempId ||
          (msg.message == updatedMessage.message &&
              msg.senderId == updatedMessage.senderId &&
              msg.status == MessageStatus.sending));

      if (messageIndex != -1) {
        log('Found message at index $messageIndex, updating status to ${updatedMessage.status}');
        messages[messageIndex] = updatedMessage;

        final updatedConvo = Conversation(
          convo.rideId,
          messages,
          convo.driverId,
          convo.userId,
        );
        await box.put(rideId, updatedConvo);
        log('Successfully updated message status');
      } else {
        log('Message not found for update. Current messages count: ${messages.length}');
      }
    } else {
      log('No conversation found for rideId: $rideId');
    }
  }

  Future<void> updateMessage(
      String rideId, String messageId, MessageModels updatedMessage) async {
    await updateMessageById(rideId, messageId, updatedMessage);
  }

  static Future<List<MessageModels>> getMessages(String rideId) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    final box = _getBox;
    final convo = box.get(rideId);
    final messages = convo?.messages ?? [];
    return List<MessageModels>.from(
        messages); // Return new list to avoid reference issues
  }

  static Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}
