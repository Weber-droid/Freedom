import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/widgets/audio_controls.dart';
import 'package:freedom/feature/home/widgets/call_participants.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({
    required this.callId,
    required this.driverName,
    required this.driverPhoto,
    super.key,
  });
  final String callId;
  final String driverName;
  final String driverPhoto;

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  @override
  void initState() {
    super.initState();
    // Start the call when the screen is opened
    context.read<CallCubit>().startCall(callId: widget.callId);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await context.read<CallCubit>().endCall();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Audio Call'),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await context.read<CallCubit>().endCall();
              if (mounted) {
                Navigator.of(context).popUntil((route) {
                  return route.settings.name == '/';
                });
              }
            },
          ),
        ),
        body: BlocConsumer<CallCubit, AudioCallState>(
          listener: (context, state) {
            if (state.status == CustomCallStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred')),
              );
            }

            // When call is ended or disconnected
            if (state.status == CustomCallStatus.idle && state.callId == null) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state.status == CustomCallStatus.connecting) {
              return const Center(child: CircularProgressIndicator());
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.grey.shade900,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Driver/Rider image
                        const CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                AssetImage('assets/images/default_avatar.png')),
                        const SizedBox(height: 24),

                        // Driver/Rider name
                        Text(
                          widget.driverName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Call status
                        Text(
                          _getCallStatusText(state.status),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade300,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Participants list (showing only remote participants)
                        if (state.participants.isNotEmpty)
                          AudioCallParticipantList(
                            participants: state.participants,
                          ),
                      ],
                    ),
                  ),

                  // Call controls
                  // In your AudioCallScreen
                  AudioCallControls(
                    isMicEnabled: state.participants.any((p) => p.isLocal)
                        ? state.participants
                            .firstWhere((p) => p.isLocal)
                            .isAudioEnabled
                        : state.isMicEnabled,
                    onToggleMic: () =>
                        context.read<CallCubit>().toggleMicrophone(),
                    onEndCall: () async {
                      await context.read<CallCubit>().endCall();
                      if (mounted) {
                        Navigator.of(context).popUntil((route) {
                          return route.settings.name == '/';
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getCallStatusText(CustomCallStatus status) {
    switch (status) {
      case CustomCallStatus.connecting:
        return 'Connecting...';
      case CustomCallStatus.connected:
        return 'Connected';
      case CustomCallStatus.disconnecting:
        return 'Ending call...';
      case CustomCallStatus.error:
        return 'Connection error';
      default:
        return 'In call';
    }
  }
}
