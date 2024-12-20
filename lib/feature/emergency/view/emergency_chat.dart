import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/emergency/cubit/emergency_cubit.dart';
import 'package:freedom/feature/emergency/view/emergency_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyChat extends StatefulWidget {
  const EmergencyChat({super.key});
  static const routeName = '/emergencyChat';

  @override
  State<EmergencyChat> createState() => _EmergencyChatState();
}

class _EmergencyChatState extends State<EmergencyChat> {
  final TextEditingController controller = TextEditingController();
  String message = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<EmergencyCubit, EmergencyState>(
        listener: (context, state) {
          if (state.messages.isNotEmpty) {
            controller.clear();
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EmergencyAppBar(
                title: 'In-App Chat with Emergency Services',
                decoratedImageSource: 'assets/images/decorated_image4.png',
                titleHorizontalSpace: 50,
              ),
              const VSpace(31),
              if (state.messages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Communicate securely with emergency responders',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14.24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const VSpace(12),
                      Text(
                        'Use the in-app chat to provide additional details or updates to emergency services. Stay connected for important instructions.',
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 14.24,
                          fontWeight: FontWeight.w300,
                          height: 1.54,
                          letterSpacing: -0.39,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(child: buildChatBubble(state.messages)),
              if (state.messages.isNotEmpty)
                const VSpace(0)
              else
                const Spacer(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.only(
                    top: 17, bottom: 25, right: 11, left: 10),
                width: double.infinity,
                height: 165,
                decoration: ShapeDecoration(
                  color: const Color(0x4CD9D9D9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                child: Column(
                  children: [
                    TextFieldFactory.name(
                      controller: controller,
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
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: SvgPicture.asset(
                            'assets/images/emergency_chat_icon.svg'),
                      ),
                      suffixIcon: Container(
                        width: 21,
                        height: 21,
                        margin: const EdgeInsets.all(11),
                        child: SvgPicture.asset(
                            'assets/images/emergency_camera_icon.svg'),
                      ),
                      onChanged: (message) {
                        setState(() {
                          this.message = message;
                        });
                      },
                    ),
                    const Spacer(),
                    FreedomButton(
                      onPressed: () {
                        if (message.isNotEmpty) {
                          context.read<EmergencyCubit>().sendMessage(message);
                          setState(() {
                            message = '';
                            controller.clear();
                          });
                        }
                      },
                      useGradient: true,
                      gradient: gradient,
                      title: 'Send Message',
                    )
                  ],
                ),
              ),
              const VSpace(28)
            ],
          );
        },
      ),
    );
  }
}

Widget buildChatBubble(List<EmergencyMessage> messages) {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    reverse: true,
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[messages.length - 1 - index];
      final isSender = message.owner == MessageOwner.sender;
      return Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: ShapeDecoration(
            color: isSender ? const Color(0xFF4A90E2) : const Color(0x4CD9D9D9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: GoogleFonts.poppins(
                  color: isSender ? Colors.white : Colors.black,
                  fontSize: 14.24,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(message.timestamp),
                style: GoogleFonts.poppins(
                  color: isSender
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatTimestamp(DateTime timestamp) {
  return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
}
