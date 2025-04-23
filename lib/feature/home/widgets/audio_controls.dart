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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Microphone toggle button
          _buildControlButton(
            icon: Icon(
              isMicEnabled ? Icons.mic : Icons.mic_off,
              color: Colors.white,
              size: 28,
            ),
            backgroundColor: Colors.grey.shade800,
            onPressed: onToggleMic,
          ),

          // End call button
          _buildControlButton(
            icon: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 28,
            ),
            backgroundColor: Colors.red,
            onPressed: onEndCall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required Icon icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: icon,
          ),
        ),
      ),
    );
  }
}
