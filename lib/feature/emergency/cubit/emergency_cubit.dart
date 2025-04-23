import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'emergency_state.dart';

class EmergencyCubit extends Cubit<EmergencyState> {
  EmergencyCubit() : super(const EmergencyState());

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;

    final newMessage = EmergencyMessage(
      message: message,
      owner: MessageOwner.sender,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, newMessage];
    emit(state.copyWith(messages: updatedMessages));
    simulateEmergencyResponse();
  }

  // Simulate receiving a message from emergency services
  void receiveMessage(String message) {
    final receivedMessage = EmergencyMessage(
      message: message,
      owner: MessageOwner.receiver,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, receivedMessage];
    emit(state.copyWith(messages: updatedMessages));
  }

  // Mark messages as read
  void markMessagesAsRead() {
    final updatedMessages = state.messages.map((message) {
      if (!message.isRead) {
        return message.copyWith(isRead: true);
      }
      return message;
    }).toList();

    emit(state.copyWith(messages: updatedMessages));
  }

  // Clear all messages
  void clearMessages() {
    emit(state.copyWith(messages: []));
  }

  void simulateEmergencyResponse() {
    // Simulate a slight delay before response
    Future.delayed(const Duration(seconds: 2), () {
      final responses = [
        "Emergency services have received your message. Please stay calm.",
        "Can you provide your exact location?",
        "Help is on the way. Stay on the line.",
        "Are there any immediate medical concerns we should be aware of?",
      ];

      // Get random response
      final random = Random();
      final response = responses[random.nextInt(responses.length)];

      receiveMessage(response);
    });
  }

  // Method to simulate a specific response
  void simulateSpecificResponse(String response) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      receiveMessage(response);
    });
  }
}
