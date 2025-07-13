import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/message_driver/cubit/in_app_message_cubit.dart';
import 'package:freedom/feature/message_driver/models/message_models.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageDriverScreen extends StatefulWidget {
  const MessageDriverScreen({super.key});
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

  @override
  void initState() {
    super.initState();
    rideCubit = context.read<RideCubit>();
    deliveryCubit = context.read<DeliveryCubit>();
    _initializeCurrentUserId();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final rideId =
            rideCubit.state.driverAccepted?.driverId ??
            await AppPreferences.getRideId();
        final deliveryId =
            deliveryCubit.state.deliveryData?.deliveryId ??
            await AppPreferences.getDeliveryId() ??
            '';

        if (rideId.isNotEmpty) {
          final messageCubit = context.read<InAppMessageCubit>();
          await messageCubit.retrieveMessagFromCache();
          messageCubit.startListeningToDriverMessages(rideId);
          _scrollToBottom();
          log('Chat initialized for ride: $rideId');
        } else if (deliveryId.isNotEmpty) {
          final messageCubit = context.read<InAppMessageCubit>();
          await messageCubit.retrieveMessagFromCache();
          messageCubit.startListeningToDriverMessages(deliveryId);
        }
      } catch (e) {
        log('Error initializing chat: $e');
      }
    });
  }

  Future<void> _initializeCurrentUserId() async {
    _currentUserId = await RegisterLocalDataSource().getUser().then(
      (user) => user?.userId,
    );
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomChatAppBar(
        driverName: rideCubit.state.driverAccepted?.driverName ?? '',
      ),
      backgroundColor: Colors.white,
      body: BlocConsumer<InAppMessageCubit, InAppMessageState>(
        listener: (context, state) {
          if (state is InAppMessageError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is InAppMessageLoaded) {
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
                    onPressed:
                        context
                            .read<InAppMessageCubit>()
                            .retrieveMessagFromCache,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is InAppMessageLoaded) {
            return _chatView(context, state, rideCubit);
          } else {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
        },
      ),
    );
  }

  Widget _chatView(
    BuildContext context,
    InAppMessageState state,
    RideCubit rideCubit,
  ) {
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
                  'Communicate securely with Driver',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14.24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  onPressed: () async {
                    if (message.isNotEmpty) {
                      final deliveryId = await AppPreferences.getDeliveryId();
                      log('deliveryId: $deliveryId');
                      if (deliveryId != null) {
                        context.read<InAppMessageCubit>().sendDeliveryMessage(
                          message,
                          deliveryId,
                        );
                      } else {
                        context.read<InAppMessageCubit>().sendMessage(
                          message,
                          rideCubit.state.driverAccepted?.driverId ?? '',
                        );
                      }

                      setState(() {
                        message = '';
                        messageController.clear();
                      });
                      // Scroll to bottom after sending message
                      _scrollToBottom();
                    }
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
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Start the conversation!',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      );
    }

    // Sort messages by timestamp to ensure correct order
    final sortedMessages = List<MessageModels>.from(messages);
    sortedMessages.sort((a, b) {
      final timeA = a.timestamp ?? DateTime.now();
      final timeB = b.timestamp ?? DateTime.now();
      return timeA.compareTo(timeB); // Oldest first
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      reverse: true, // This makes newest messages appear at bottom
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        // Since reverse: true, we need to reverse the index
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
                // Show the sender's name for incoming messages
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
                    // Show delivery status for sent messages
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
  final VoidCallback? onBackPressed;
  final VoidCallback? onCallPressed;
  final bool isOnline;

  const CustomChatAppBar({
    super.key,
    required this.driverName,
    this.onBackPressed,
    this.onCallPressed,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B7CB6), // Light purple
            Color(0xFF6B5B95), // Medium purple
            Color(0xFF4A4A6A), // Darker purple
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Back Button
              _buildRoundedButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              ),

              // Driver Info (Centered)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driverName,
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

              // Call Button
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
