import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/message_driver/cubit/in_app_message_cubit.dart';
import 'package:freedom/feature/message_driver/models/message_models.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/utils/context_helpers.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageDriverScreen extends StatefulWidget {
  const MessageDriverScreen({super.key, this.messageContext});

  final MessageContext? messageContext;
  static const routeName = '/message_driver_screen';

  @override
  State<MessageDriverScreen> createState() => _MessageDriverScreenState();
}

class _MessageDriverScreenState extends State<MessageDriverScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String message = '';
  late RideCubit rideCubit;
  late DeliveryCubit deliveryCubit;
  String? _currentUserId;
  MessageContextInfo? _contextInfo;

  @override
  void initState() {
    super.initState();
    rideCubit = context.read<RideCubit>();
    deliveryCubit = context.read<DeliveryCubit>();
    _initializeCurrentUserId();
    _determineContext();
    _initializeChat();
  }

  void _determineContext() {
    if (widget.messageContext != null) {
      _contextInfo = _getContextInfoForType(widget.messageContext!);
    } else {
      _contextInfo = MessageContextHelper.getCurrentContext(context);
    }

    if (_contextInfo == null) {
      log('❌ No active ride or delivery found');
    } else {
      log(
        '✅ Using context: ${_contextInfo!.context.name} with ID: ${_contextInfo!.contextId}',
      );
    }
  }

  MessageContextInfo? _getContextInfoForType(MessageContext contextType) {
    switch (contextType) {
      case MessageContext.ride:
        final rideId = rideCubit.state.driverAccepted?.rideId;
        if (rideId?.isNotEmpty == true) {
          return MessageContextInfo(
            context: MessageContext.ride,
            contextId: rideId!,
            driverName: rideCubit.state.driverAccepted?.driverName ?? 'Driver',
          );
        }
        break;
      case MessageContext.delivery:
        final deliveryId =
            deliveryCubit.state.deliveryDriverAccepted?.deliveryId ??
            deliveryCubit.state.currentDeliveryId;
        if (deliveryId?.isNotEmpty == true) {
          return MessageContextInfo(
            context: MessageContext.delivery,
            contextId: deliveryId!,
            driverName: 'Delivery Driver',
          );
        }
        break;
    }
    return null;
  }

  Future<void> _initializeChat() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_contextInfo == null) {
          log('❌ Cannot initialize chat: no context info');
          return;
        }

        log(
          'Initializing chat with ${_contextInfo!.context.name}: ${_contextInfo!.contextId}',
        );

        final messageCubit = context.read<InAppMessageCubit>();
        await messageCubit.retrieveMessagesFromCache(
          _contextInfo!.contextId,
          _contextInfo!.context,
        );
        messageCubit.startListeningToDriverMessages(
          _contextInfo!.contextId,
          _contextInfo!.context,
        );
        _scrollToBottom();
      } catch (e) {
        log('Error initializing chat: $e');
      }
    });
  }

  Future<void> _initializeCurrentUserId() async {
    _currentUserId = await RegisterLocalDataSource().getUser().then(
      (user) => user?.userId,
    );
    log('Current user ID: $_currentUserId');
    setState(() {});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _getContextTitle() {
    if (_contextInfo == null) return 'Message';

    switch (_contextInfo!.context) {
      case MessageContext.ride:
        return 'Communicate securely with Driver';
      case MessageContext.delivery:
        return 'Communicate securely with Delivery Driver';
    }
  }

  String _getNoActiveContextMessage() {
    if (_contextInfo == null) return 'No active ride or delivery found';

    switch (_contextInfo!.context) {
      case MessageContext.ride:
        return 'No active ride found';
      case MessageContext.delivery:
        return 'No active delivery found';
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error if no context
    if (_contextInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFF8B7CB6),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _getNoActiveContextMessage(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomChatAppBar(
        driverName: _contextInfo!.driverName,
        contextType: _contextInfo!.context,
      ),
      backgroundColor: Colors.white,
      body: BlocConsumer<InAppMessageCubit, InAppMessageState>(
        listener: (context, state) {
          if (state is InAppMessageError) {
            log('InAppMessageError: ${state.error}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is InAppMessageLoaded) {
            log('InAppMessageLoaded: ${state.inAppMessages.length} messages');
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is InAppMessageLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (state is InAppMessageError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_contextInfo != null) {
                        context
                            .read<InAppMessageCubit>()
                            .retrieveMessagesFromCache(
                              _contextInfo!.contextId,
                              _contextInfo!.context,
                            );
                      }
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InAppMessageCubit>().refreshMessages();
                    },
                    child: const Text('Refresh Messages'),
                  ),
                ],
              ),
            );
          } else if (state is InAppMessageLoaded) {
            return _chatView(context, state);
          } else {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
        },
      ),
    );
  }

  Widget _chatView(BuildContext context, InAppMessageState state) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSpace(31),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getContextTitle(),
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14.24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Debug info (remove in production)
                if (kDebugMode && _contextInfo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_contextInfo!.context.name}Id: ${_contextInfo!.contextId}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Messages: ${(state as InAppMessageLoaded).inAppMessages.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const VSpace(20),
          Expanded(
            child: _buildChatMessages(
              (state as InAppMessageLoaded).inAppMessages,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.only(
              top: 17,
              bottom: 25,
              right: 11,
              left: 10,
            ),
            width: double.infinity,
            decoration: ShapeDecoration(
              color: const Color(0x4CD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFieldFactory.name(
                  controller: messageController,
                  hinText: 'Type a message',
                  fillColor: Colors.white,
                  prefixText: Container(
                    width: 21,
                    height: 21,
                    margin: const EdgeInsets.all(11),
                    padding: const EdgeInsets.all(3),
                    decoration: ShapeDecoration(
                      color: const Color(0x87D9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/emergency_chat_icon.svg',
                    ),
                  ),
                  suffixIcon: Container(
                    width: 21,
                    height: 21,
                    margin: const EdgeInsets.all(11),
                    child: SvgPicture.asset(
                      'assets/images/emergency_camera_icon.svg',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      message = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FreedomButton(
                  onPressed:
                      message.trim().isEmpty
                          ? null
                          : () async {
                            if (_contextInfo == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_getNoActiveContextMessage()),
                                ),
                              );
                              return;
                            }

                            log(
                              'Sending message: $message for ${_contextInfo!.context.name}: ${_contextInfo!.contextId}',
                            );

                            await context.read<InAppMessageCubit>().sendMessage(
                              message.trim(),
                              _contextInfo!.contextId,
                              _contextInfo!.context,
                            );

                            // Clear the message after sending
                            messageController.clear();
                            setState(() {
                              message = '';
                            });

                            _scrollToBottom();
                          },
                  useGradient: true,
                  titleColor: Colors.white,
                  buttonTitle: Text(
                    'Send Message',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  gradient: redLinearGradient,
                  title: 'Send Message',
                ),
              ],
            ),
          ),
          const VSpace(28),
        ],
      ),
    );
  }

  Widget _buildChatMessages(List<MessageModels> messages) {
    log('Building chat messages: ${messages.length} messages');

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No messages yet. Start the conversation!',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<InAppMessageCubit>().refreshMessages();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final sortedMessages = List<MessageModels>.from(messages);
    sortedMessages.sort((a, b) {
      final timeA = a.timestamp ?? DateTime.now();
      final timeB = b.timestamp ?? DateTime.now();
      return timeA.compareTo(timeB); // Oldest first
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      reverse: true,
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final reversedIndex = sortedMessages.length - 1 - index;
        final message = sortedMessages[reversedIndex];

        final isSender =
            _currentUserId != null && message.senderId == _currentUserId;

        return Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: ShapeDecoration(
              color:
                  isSender ? const Color(0xFF4A90E2) : const Color(0x4CD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSender && message.driverName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.driverName ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Text(
                  message.message ?? '',
                  style: GoogleFonts.poppins(
                    color: isSender ? Colors.white : Colors.black,
                    fontSize: 14.24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.timestamp ?? DateTime.now()),
                      style: GoogleFonts.poppins(
                        color:
                            isSender
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    if (isSender) ...[
                      const SizedBox(width: 4),
                      _buildDeliveryStatus(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.7),
            ),
          ),
        );
      case MessageStatus.sent:
        return Icon(Icons.done_all, size: 12, color: Colors.blue[300]);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 12, color: Colors.blue[600]);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 12, color: Colors.red[300]);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String driverName;
  final MessageContext contextType;
  final VoidCallback? onBackPressed;
  final VoidCallback? onCallPressed;
  final bool isOnline;

  const CustomChatAppBar({
    super.key,
    required this.driverName,
    required this.contextType,
    this.onBackPressed,
    this.onCallPressed,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              contextType == MessageContext.delivery
                  ? [
                    const Color(0xFF6B7CB6),
                    const Color(0xFF4B5B95),
                    const Color(0xFF3A4A6A),
                  ]
                  : [
                    const Color(0xFF8B7CB6),
                    const Color(0xFF6B5B95),
                    const Color(0xFF4A4A6A),
                  ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildRoundedButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driverName.isNotEmpty ? driverName : _getDefaultTitle(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isOnline)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _buildRoundedButton(
                icon: Icons.phone,
                onPressed: onCallPressed ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDefaultTitle() {
    switch (contextType) {
      case MessageContext.ride:
        return 'Driver';
      case MessageContext.delivery:
        return 'Delivery Driver';
    }
  }

  Widget _buildRoundedButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(child: Icon(icon, color: Colors.white, size: 20)),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
