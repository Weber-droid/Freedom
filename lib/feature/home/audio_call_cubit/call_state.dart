part of 'call_cubit.dart';

enum CustomCallStatus {
  idle,
  initializing,
  connecting,
  connected,
  disconnecting,
  error,
}

class AudioCallState extends Equatable {
  const AudioCallState({
    this.status = CustomCallStatus.idle,
    this.callId,
    this.errorMessage,
    this.isMicEnabled = true,
    this.participants = const [],
    this.callStats,
  });
  final CustomCallStatus status;
  final String? callId;
  final String? errorMessage;
  final bool isMicEnabled;
  final List<stream_video.CallParticipantState> participants;
  final stream_video.CallStats? callStats;

  AudioCallState copyWith({
    CustomCallStatus? status,
    String? callId,
    String? errorMessage,
    bool? isMicEnabled,
    List<CallParticipantState>? participants,
  }) {
    return AudioCallState(
      status: status ?? this.status,
      callId: callId ?? this.callId,
      errorMessage: errorMessage,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      participants: participants ?? this.participants,
    );
  }

  @override
  List<Object?> get props => [
        status,
        callId,
        errorMessage,
        isMicEnabled,
        participants,
      ];
}
