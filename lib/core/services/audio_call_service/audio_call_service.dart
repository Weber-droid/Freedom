// ignore_for_file: inference_failure_on_instance_creation

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

abstract class CallServiceInterface {
  /// Initialize the call service with user credentials
  Future<void> initialize({required String userId, required String userName});

  /// Create or join an audio call with the given ID
  Future<void> makeCall({required String callId});

  /// End the current call
  Future<void> endCall();

  /// Toggle the microphone state
  Future<void> toggleMicrophone();

  /// Get the current call ID if in a call
  String? getCurrentCallId();

  /// Check if currently in a call
  bool isInCall();
}

class StreamCallService implements CallServiceInterface {
  static const String _apiKey = 't3737j3jqbgn';

  late StreamVideo _client;
  Call? _currentCall;
  bool _isInitialized = false;

  @override
  Future<void> initialize(
      {required String userId, required String userName}) async {
    if (_isInitialized) return;
    try {
      // In a real app, you would get this token from your backend
      final userToken = await _getUserToken(userId);

      _client = StreamVideo(
        _apiKey,
        user: User.regular(
          userId: userId,
          name: userName,
        ),
        userToken: userToken,
      );
      _isInitialized = true;

      debugPrint('Stream call service initialized for user: $userId');
    } catch (e) {
      _isInitialized = false;
      debugPrint('Error initializing Stream call service: $e');
      rethrow;
    }
  }

  @override
  Future<void> makeCall({required String callId}) async {
    try {
      if (!_isInitialized) {
        throw Exception(
            'Stream client not initialized. Call initialize() first.');
      }

      if (_currentCall != null) {
        await endCall();
      }

      // Create a custom call type for audio-only
      final callType = StreamCallType.defaultType();

      _currentCall = _client.makeCall(
        callType: callType,
        id: callId,
      );

      // Configure call for audio only
      await _currentCall!.getOrCreate(
        ringing: true,
        notify: true,
        limits: const StreamLimitsSettings(
          maxParticipants: 2,
        ),
      );

      debugPrint('Audio call created or joined: $callId');
    } catch (e) {
      debugPrint('Error creating or joining call: $e');
      rethrow;
    }
  }

  @override
  Future<void> endCall() async {
    try {
      if (_currentCall != null) {
        await _currentCall!.leave();
        _currentCall = null;
        debugPrint('Call ended');
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleMicrophone() async {
    try {
      if (_currentCall != null) {
        final localParticipant = _currentCall!.state.value.localParticipant;
        if (localParticipant != null) {
          final audioEnabled = localParticipant.isAudioEnabled;
          debugPrint('Microphone toggled: ${!audioEnabled}');
        }
      }
    } catch (e) {
      debugPrint('Error toggling microphone: $e');
      rethrow;
    }
  }

  @override
  String? getCurrentCallId() {
    return _currentCall?.id;
  }

  @override
  bool isInCall() {
    return _currentCall != null;
  }

  /// Simulate getting a user token from a backend service
  /// Do not use this in production!
  Future<String> _getUserToken(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final header =
          base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
      final payload = base64Url.encode(utf8.encode(
          '{"user_id":"$userId","exp":${(DateTime.now().millisecondsSinceEpoch / 1000).round() + 3600}}'));
      final signature =
          base64Url.encode(utf8.encode('dummy_signature_for_development_only'));
      log('Generated token: $header.$payload.$signature');
      return '$header.$payload.$signature';
    } catch (e) {
      debugPrint('Error generating token: $e');
      rethrow;
    }
  }

  // Get the StreamVideo instance for advanced operations
  StreamVideo get client => _client;

  // Get the current call if any
  Call? get currentCall => _currentCall;
}
