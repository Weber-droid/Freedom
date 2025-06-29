part of 'message_driver_cubit.dart';

abstract class MessageDriverState extends Equatable {
  const MessageDriverState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends MessageDriverState {}

class ChatLoading extends MessageDriverState {}

class ChatConnected extends MessageDriverState {

  const ChatConnected(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class ChatChannelLoaded extends MessageDriverState {

  const ChatChannelLoaded({
    required this.channel,
    required this.messages,
  });
  final Channel channel;
  final List<Message> messages;

  @override
  List<Object?> get props => [channel, messages];
}

class ChatError extends MessageDriverState {

  const ChatError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}