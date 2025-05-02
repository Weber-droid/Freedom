import 'dart:ui';

import 'package:flutter/material.dart';

class AudioCallControls extends StatelessWidget {
  const AudioCallControls({
    required this.isMicEnabled,
    required this.onToggleMic,
    required this.onEndCall,
    super.key,
  });
  final bool isMicEnabled;
  final VoidCallback onToggleMic;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    // Getting screen dimensions for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust sizes based on screen dimensions
    final buttonSize = screenWidth * 0.15;
    final iconSize = screenWidth * 0.06;
    final paddingVertical = screenHeight * 0.04;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 23.7, sigmaY: 23.7),
        child: Container(
          width: screenWidth,
          padding: EdgeInsets.symmetric(
            vertical: paddingVertical,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(
                0x33363636), // Hex color from Figma with 20% opacity
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: const Color(0xFAFAFA2E).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Draggable handle
              Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Title for the controls
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Call Controls",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Stacked buttons with responsive sizing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Microphone toggle button
                  _buildControlButton(
                    context: context,
                    icon: Icon(
                      isMicEnabled ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    backgroundColor: Colors.grey.shade800.withOpacity(0.7),
                    onPressed: onToggleMic,
                    label: isMicEnabled ? "Mute" : "Unmute",
                    buttonSize: buttonSize,
                  ),

                  // End call button
                  _buildControlButton(
                    context: context,
                    icon: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    backgroundColor: Colors.red.withOpacity(0.8),
                    onPressed: onEndCall,
                    label: "End Call",
                    buttonSize: buttonSize,
                  ),
                ],
              ),

              // Add SafeArea padding at the bottom
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required Icon icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required String label,
    required double buttonSize,
  }) {
    final fontSize = MediaQuery.of(context).size.width * 0.035;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Center(child: icon),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
