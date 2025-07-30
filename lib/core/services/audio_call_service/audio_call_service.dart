// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:freedom/app_preference.dart';
// import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
// import 'package:stream_video_flutter/stream_video_flutter.dart';

// abstract class CallServiceInterface {
//   Future<void> initialize({required String userId, required String userName});

//   Future<void> makeCall({required String callId});

//   Future<void> endCall();

//   Future<void> toggleMicrophone();

//   String? getCurrentCallId();

//   bool isInCall();
// }

// class StreamCallService implements CallServiceInterface {
//   static final String _apiKey = dotenv.env['STREAM_CALL_API_KEY'] ?? '';

//   late StreamVideo _client;
//   Call? _currentCall;
//   bool _isInitialized = false;

//   @override
//   Future<void> initialize({
//     required String userId,
//     required String userName,
//   }) async {
//     if (_isInitialized) return;
//     try {
//       final userTokenRaw = await AppPreferences.getToken();

//       final parts = userTokenRaw.split('.');
//       if (parts.length != 3) throw Exception('Invalid JWT token format');

//       final header = parts[0];
//       final payload = parts[1];
//       final signature = parts[2];

//       final normalizedPayload = base64Url.normalize(payload);
//       final jsonPayload = utf8.decode(base64Url.decode(normalizedPayload));
//       final decodedPayload = jsonDecode(jsonPayload) as Map<String, dynamic>;

//       log('Original payload: $decodedPayload');

//       decodedPayload['user_id'] = decodedPayload['id'];

//       log('Patched payload: $decodedPayload');

//       final patchedPayloadJson = jsonEncode(decodedPayload);
//       final patchedPayloadBase64 = base64Url
//           .encode(utf8.encode(patchedPayloadJson))
//           .replaceAll('=', '');

//       final patchedToken = '$header.$patchedPayloadBase64.$signature';

//       _client = StreamVideo(
//         _apiKey,
//         user: User.regular(userId: userId, name: userName),
//         userToken: patchedToken,
//       );
//       _isInitialized = true;

//       debugPrint('Stream call service initialized for user: $userId');
//     } catch (e) {
//       _isInitialized = false;
//       debugPrint('Error initializing Stream call service: $e');
//       rethrow;
//     }
//   }

//   @override
//   Future<void> makeCall({required String callId}) async {
//     try {
//       if (!_isInitialized) {
//         throw Exception(
//           'Stream client not initialized. Call initialize() first.',
//         );
//       }

//       if (_currentCall != null) {
//         await endCall();
//       }

//       final callType = StreamCallType.defaultType();

//       _currentCall = _client.makeCall(callType: callType, id: callId);

//       await _currentCall!.getOrCreate(
//         ringing: true,
//         notify: true,
//         limits: const StreamLimitsSettings(maxParticipants: 2),
//       );

//       debugPrint('Audio call created or joined: $callId');
//     } catch (e) {
//       debugPrint('Error creating or joining call: $e');
//       rethrow;
//     }
//   }

//   @override
//   Future<void> endCall() async {
//     try {
//       if (_currentCall != null) {
//         await _currentCall!.leave();
//         _currentCall = null;
//         debugPrint('Call ended');
//       }
//     } catch (e) {
//       debugPrint('Error ending call: $e');
//       rethrow;
//     }
//   }

//   @override
//   Future<void> toggleMicrophone() async {
//     try {
//       if (_currentCall != null) {
//         final localParticipant = _currentCall!.state.value.localParticipant;
//         if (localParticipant != null) {
//           final audioEnabled = localParticipant.isAudioEnabled;
//           debugPrint('Microphone toggled: ${!audioEnabled}');
//         }
//       }
//     } catch (e) {
//       debugPrint('Error toggling microphone: $e');
//       rethrow;
//     }
//   }

//   @override
//   String? getCurrentCallId() {
//     return _currentCall?.id;
//   }

//   @override
//   bool isInCall() {
//     return _currentCall != null;
//   }

//   StreamVideo get client => _client;

//   Call? get currentCall => _currentCall;
// }
