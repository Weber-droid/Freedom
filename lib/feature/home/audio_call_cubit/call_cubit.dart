import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/core/services/audio_call_service/audio_call_service.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream_video;

part 'call_state.dart';

class CallCubit extends Cubit<AudioCallState> {
  final CallServiceInterface _callService;
  StreamSubscription? _callStateSubscription;

  CallCubit({
    required CallServiceInterface callService,
  })  : _callService = callService,
        super(const AudioCallState());

  Future<void> initialize({
    required String userId,
    required String userName,
  }) async {
    emit(state.copyWith(status: CustomCallStatus.initializing));
    try {
      await _callService.initialize(
        userId: userId,
        userName: userName,
      );
      emit(state.copyWith(status: CustomCallStatus.idle));
    } catch (e) {
      emit(state.copyWith(
        status: CustomCallStatus.error,
        errorMessage: 'Failed to initialize call service: $e',
      ));
    }
  }

  Future<void> startCall({required String callId}) async {
    emit(state.copyWith(
      status: CustomCallStatus.connecting,
      callId: callId,
    ));

    try {
      await _callService.makeCall(callId: callId);

      // Access the current call and subscribe to its state changes
      if (_callService is StreamCallService) {
        final streamCallService = _callService;
        final call = streamCallService.currentCall;

        if (call != null) {
          _subscribeToCallState(call);
          emit(state.copyWith(
            status: CustomCallStatus.connected,
            participants: call.state.value.callParticipants.toList(),
            isMicEnabled:
                call.state.value.localParticipant?.isAudioEnabled ?? true,
          ));
        }
      }
    } catch (e) {
      emit(state.copyWith(
        status: CustomCallStatus.error,
        errorMessage: 'Failed to start call: $e',
      ));
    }
  }

  Future<void> endCall() async {
    emit(state.copyWith(status: CustomCallStatus.disconnecting));

    try {
      await _callService.endCall();
      await _callStateSubscription?.cancel();
      _callStateSubscription = null;

      emit(const AudioCallState());
    } catch (e) {
      emit(state.copyWith(
        status: CustomCallStatus.error,
        errorMessage: 'Failed to end call: $e',
      ));
    }
  }

  Future<void> toggleMicrophone() async {
    try {
      await _callService.toggleMicrophone();
      emit(state.copyWith(isMicEnabled: !state.isMicEnabled));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to toggle microphone: $e',
      ));
    }
  }

  void _subscribeToCallState(Call call) {
    _callStateSubscription?.cancel();
    _callStateSubscription = call.state.listen((callState) {
      emit(state.copyWith(
        participants: callState.callParticipants.toList(),
        isMicEnabled:
            callState.localParticipant?.isAudioEnabled ?? state.isMicEnabled,
      ));
    });
  }

  @override
  Future<void> close() {
    _callStateSubscription?.cancel();
    return super.close();
  }
}
