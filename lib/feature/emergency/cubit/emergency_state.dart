part of 'emergency_cubit.dart';

// Define message owner enum
enum MessageOwner { sender, receiver }

// Define message class with additional metadata
class EmergencyMessage {
  const EmergencyMessage({
    required this.message,
    required this.owner,
    required this.timestamp,
    this.isRead = false,
  });

  final String message;
  final MessageOwner owner;
  final DateTime timestamp;
  final bool isRead;

  EmergencyMessage copyWith({
    String? message,
    MessageOwner? owner,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return EmergencyMessage(
      message: message ?? this.message,
      owner: owner ?? this.owner,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Define state
class EmergencyState extends Equatable {
  const EmergencyState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  final List<EmergencyMessage> messages;
  final bool isLoading;
  final String? error;

  EmergencyState copyWith({
    List<EmergencyMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return EmergencyState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error];
}
