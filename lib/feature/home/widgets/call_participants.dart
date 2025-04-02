import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class AudioCallParticipantList extends StatelessWidget {
  final List<CallParticipantState> participants;

  const AudioCallParticipantList({
    Key? key,
    required this.participants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter to only show remote participants
    final remoteParticipants = participants.where((p) => !p.isLocal).toList();

    if (remoteParticipants.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants (${remoteParticipants.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          ...remoteParticipants.map(_buildParticipantItem),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(CallParticipantState participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: participant.connectionQuality == SfuConnectionQuality.good
                  ? Colors.green
                  : (participant.connectionQuality == SfuConnectionQuality.poor
                      ? Colors.amber
                      : Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            participant.name ?? 'Unknown',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          if (participant.isAudioEnabled == false)
            const Icon(
              Icons.mic_off,
              color: Colors.white54,
              size: 14,
            ),
        ],
      ),
    );
  }
}
