// import 'dart:async';

// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:freedom/core/services/message_service/mesage_service.dart';

// part 'message_driver_state.dart';



// class MessageDriverCubit extends Cubit<MessageDriverState> {

//   MessageDriverCubit({
//     required IMessageService chatService,
//   }) : _chatService = chatService,
//         super(ChatInitial());
//   final IMessageService _chatService;
//   StreamSubscription<dynamic>? _channelSubscription;

//   Future<void> initialize({
//     required String userId,
//     required String userName,
//   }) async {
//     emit(ChatLoading());

//     try {
//       await _chatService.initializeChat(
//         userId: userId,
//         userName: userName,
//       );

//       await _chatService.connectUser(
//         userId: userId,
//         userName: userName,
//       );

//       final user = _chatService.client!.state.currentUser!;
//       emit(ChatConnected(user));
//     } catch (e) {
//       emit(ChatError('Failed to initialize chat: ${e.toString()}'));
//     }
//   }

//   Future<void> createOrJoinChannel({
//     required String channelId,
//     required String channelName,
//     List<String>? members,
//     String? imageUrl,
//   }) async {
//     if (state is! ChatConnected) {
//       emit(const ChatError('User not connected. Please initialize first.'));
//       return;
//     }

//     emit(ChatLoading());

//     try {
//       // Create or join channel
//       final channel = await _chatService.createChannel(
//         channelId: channelId,
//         name: channelName,
//         members: members,
//         imageUrl: imageUrl,
//       );

//       // Get messages
//       final messages = await channel.getMessagesById([channelId]);

//       emit(ChatChannelLoaded(
//         channel: channel,
//         messages: messages.messages,
//       ));

//       _listenToChannel(channel);
//     } catch (e) {
//       emit(ChatError('Failed to create or join channel: ${e.toString()}'));
//     }
//   }

//   Future<void> loadChannel(String channelId) async {
//     if (state is! ChatConnected) {
//       emit(const ChatError('User not connected. Please initialize first.'));
//       return;
//     }

//     emit(ChatLoading());

//     try {
//       final channel = await _chatService.getChannel(channelId: channelId);

//       // Get messages
//       final messages = await channel.getMessagesById([channelId]);

//       emit(ChatChannelLoaded(
//         channel: channel,
//         messages: messages.messages,
//       ));

//       // Listen for channel updates
//       _listenToChannel(channel);
//     } catch (e) {
//       emit(ChatError('Failed to load channel: ${e.toString()}'));
//     }
//   }

//   Future<void> sendMessage(String text) async {
//     if (state is! ChatChannelLoaded) {
//       emit(const ChatError('No active channel. Please join a channel first.'));
//       return;
//     }

//     try {
//       final channelState = state as ChatChannelLoaded;
//       await _chatService.sendMessage(
//         channelId: channelState.channel.id!,
//         text: text,
//       );
//     } catch (e) {
//       emit(ChatError('Failed to send message: ${e.toString()}'));
//     }
//   }

//   Future<void> markChannelRead() async {
//     if (state is! ChatChannelLoaded) return;

//     try {
//       final channelState = state as ChatChannelLoaded;
//       await _chatService.markChannelRead(channelId: channelState.channel.id!);
//     } catch (e) {
//       // Handle error silently or show a toast
//       print('Failed to mark channel as read: ${e.toString()}');
//     }
//   }

//   void _listenToChannel(Channel channel) {
//     // Cancel previous subscription if any
//     _channelSubscription?.cancel();

//     // Listen for new messages
//     _channelSubscription = channel.state!.messagesStream.listen((event) {
//       if (state is ChatChannelLoaded) {
//         final currentState = state as ChatChannelLoaded;
//         emit(ChatChannelLoaded(
//           channel: channel,
//           messages: event,
//         ));
//       }
//     });
//   }

//   Future<void> disconnect() async {
//     try {
//       await _chatService.disconnect();
//       _cleanUp();
//       emit(ChatInitial());
//     } catch (e) {
//       emit(ChatError('Failed to disconnect: ${e.toString()}'));
//     }
//   }

//   void _cleanUp() {
//     _channelSubscription?.cancel();
//     _channelSubscription = null;
//   }

//   @override
//   Future<void> close() {
//     _cleanUp();
//     return super.close();
//   }
// }