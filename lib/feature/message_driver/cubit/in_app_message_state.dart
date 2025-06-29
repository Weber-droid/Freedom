part of 'in_app_message_cubit.dart';

sealed class InAppMessageState extends Equatable {
  const InAppMessageState();
  @override
  List<Object> get props => [];
}

class InAppMessageInitial extends InAppMessageState {}

class InAppMessageLoading extends InAppMessageState {}
class InAppMessageLoaded extends InAppMessageState {
  const InAppMessageLoaded({required this.inAppMessages});
  final List<MessageModels> inAppMessages;
  @override
  List<Object> get props => [inAppMessages];
}

class InAppMessageSent extends InAppMessageState {
  const InAppMessageSent({required this.sent});
  final bool sent;
  @override
  List<Object> get props => [sent];
}

class InAppMessageSending extends InAppMessageState {}

class InAppMessageError extends InAppMessageState {
  const InAppMessageError({required this.error});
  final String error;
  @override
  List<Object> get props => [error];
}
