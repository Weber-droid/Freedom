// import 'dart:convert';
// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:freedom/app_preference.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart';

// abstract class IMessageService{
//   Future<void> initializeChat({required String userId, required String userName});
//   Future<void> connectUser({required String userId, required String userName});
//   Future<Channel> createChannel({ required String channelId,
//     required String name,
//     String? imageUrl,
//     List<String>? members,});
//   Future<Channel> getChannel({required String channelId});
//   Future<void> sendMessage({required String channelId, required String text});
//   Future<void> markChannelRead({required String channelId});
//   Future<void> disconnect();
//   bool isInitialized();
//   StreamChatClient? get client;

// }

// class MessageService implements IMessageService{
//   static final String _apiKey = dotenv.env['STREAM_CHAT_API_KEY'] ?? '';
// StreamChatClient? _client;
// late bool _isInitialized = false;


//   @override
//   Future<void> connectUser({required String userId, required String userName}) async{
//     if (!_isInitialized) {
//       throw Exception('Stream client not initialized. Call initialize() first.');
//     }
//     try {
//       final patchedToken = await _patchUserTokenWithUserId();
//       await _client?.connectUser( User(id: userId, name: userName), 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidHV0b3JpYWwtZmx1dHRlciJ9.S-MJpoSwDiqyXpUURgO5wVqJ4vKlIVFLSEyrFYCOE1c');

//     } catch (e) {
//       debugPrint('Error connecting user: $e');
//       rethrow;
//     }

//   }

//   @override
//   Future<Channel> createChannel({
//     required String channelId,
//     required String name,
//     String? imageUrl,
//     List<String>? members,
//   }) async {
//     if (!_isInitialized || _client == null) {
//       throw Exception('Stream client not initialized or user not connected.');
//     }

//     try {
//       final channel = _client!.channel(
//         'messaging',
//         id: channelId,
//         extraData: {
//           'name': name,
//           'image': imageUrl,
//           'members': members ?? [],
//         },
//       );
//       await channel.watch();
//       debugPrint('Channel created: $channelId');

//       return channel;
//     } catch (e) {
//       debugPrint('Error creating channel: $e');
//       rethrow;
//     }
//   }

//   @override
//   Future<void> disconnect() {
//     if (_client != null) {
//       _client!.disconnectUser();
//       _client!.dispose();
//       _client = null;
//       _isInitialized = false;
//     }
//     return Future.value();
//   }

//   @override
//   Future<Channel> getChannel({required String channelId}) async{
//     try{
//       if (!_isInitialized || _client == null) {
//         throw Exception('Stream client not initialized or user not connected.');
//       }

//       final channel = _client!.channel('messaging', id: channelId);
//       await channel.watch();
//       debugPrint('Channel retrieved: $channelId');

//       return channel;

//     } catch (e) {
//       debugPrint('Error getting channel: $e');
//       rethrow;
//     }
//   }

//   @override
//   Future<void> initializeChat({required String userId, required String userName}) async{
//    try {
//      if(_isInitialized) return;
//      _client = StreamChatClient(
//        'b67pax5b2wdq',
//        logLevel: Level.INFO,
//      );
//      _isInitialized = true;
//      debugPrint('Stream chat service initialized');
//    } catch (e) {
//      _isInitialized = false;
//      debugPrint('Error initializing Stream chat service: $e');
//      rethrow;
//    }
//   }

//   @override
//   bool isInitialized() {
//     if(_isInitialized) return true;
//     return false;
//   }

//   @override
//   Future<void> markChannelRead({required String channelId}) async{
//     if(!_isInitialized || _client == null) {
//       throw Exception('Stream client not initialized or user not connected.');
//     }
//     try {
//       final channel = _client!.channel('messaging', id: channelId);
//       await channel.markRead();
//       debugPrint('Channel marked as read: $channelId');
//     } catch (e) {
//       debugPrint('Error marking channel as read: $e');
//       rethrow;
//     }
//   }

//   @override
//   Future<void> sendMessage({
//     required String channelId,
//     required String text,
//   }) async {
//     if (!_isInitialized || _client == null) {
//       throw Exception('Stream client not initialized or user not connected.');
//     }

//     try {
//       final channel = _client!.channel('messaging', id: channelId);
//       final message = Message(
//         text: text,
//       );

//       await channel.sendMessage(message);
//       debugPrint('Message sent to channel: $channelId');
//     } catch (e) {
//       debugPrint('Error sending message: $e');
//       rethrow;
//     }
//   }

//   Future<String> _patchUserTokenWithUserId() async {
//     final userTokenRaw = await AppPreferences.getToken();

//     // Split JWT into 3 parts: header.payload.signature
//     final parts = userTokenRaw.split('.');
//     if (parts.length != 3) throw Exception('Invalid JWT token format');

//     final header = parts[0];
//     final payload = parts[1];
//     final signature = parts[2]; // We'll leave signature as-is (invalid)

//     // Decode payload
//     final normalizedPayload = base64Url.normalize(payload);
//     final jsonPayload = utf8.decode(base64Url.decode(normalizedPayload));
//     final decodedPayload = jsonDecode(jsonPayload) as Map<String, dynamic>;

//     log('Original payload: $decodedPayload');

//     // Inject user_id
//     decodedPayload['user_id'] = decodedPayload['id'];

//     log('Patched payload: $decodedPayload');

//     // Re-encode payload
//     final patchedPayloadJson = jsonEncode(decodedPayload);
//     final patchedPayloadBase64 = base64Url.encode(utf8.encode(patchedPayloadJson)).replaceAll('=', '');

//     // Reconstruct token with original header and signature (even though sig is now invalid)
//     final patchedToken = '$header.$patchedPayloadBase64.$signature';

//     return patchedToken;
//   }
//   @override
//   StreamChatClient? get client => _client;
// }