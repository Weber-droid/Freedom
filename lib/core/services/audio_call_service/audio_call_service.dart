// ignore_for_file: inference_failure_on_instance_creation

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freedom/app_preference.dart';
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
  static final String _apiKey = dotenv.env['STREAM_CALL_API_KEY'] ?? '';

  late StreamVideo _client;
  Call? _currentCall;
  bool _isInitialized = false;

  @override
  Future<void> initialize(
      {required String userId, required String userName}) async {
    log('show id $userId');
    if (_isInitialized) return;
    try {
      final userTokenRaw = await AppPreferences.getToken();

      // Decode the token
      final parts = userTokenRaw.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT token format');

      // Get all three parts
      final header = parts[0];
      final payload = parts[1];
      final signature = parts[2];

      // Decode the payload
      final normalizedPayload = base64Url.normalize(payload);
      final jsonPayload = utf8.decode(base64Url.decode(normalizedPayload));
      final decodedPayload = jsonDecode(jsonPayload) as Map<String, dynamic>;

      // Create a new payload with user_id field
      final newPayload = {
        ...decodedPayload,
        'user_id': decodedPayload['id'],
      };

      // Re-encode the payload
      final encodedNewPayload =
          base64Url.encode(utf8.encode(jsonEncode(newPayload)));

      // Reconstruct the token with the original header and signature
      final newToken = '$header.$encodedNewPayload.$signature';
      log('new token $newToken');

      _client = StreamVideo(
        _apiKey,
        user: User.regular(
          userId: userId,
          name: userName,
        ),
        userToken: newToken,
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

  // Get the StreamVideo instance for advanced operations
  StreamVideo get client => _client;

  // Get the current call if any
  Call? get currentCall => _currentCall;
}
