// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:freedom/feature/home/widgets/audio_controls.dart';
// import 'package:freedom/feature/home/widgets/call_participants.dart';
// import 'package:freedom/feature/home/widgets/call_timer.dart';
// import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

// class AudioCallScreen extends StatefulWidget {
//   const AudioCallScreen({
//     required this.callId,
//     required this.driverName,
//     required this.driverPhoto,
//     super.key,
//   });
//   final String callId;
//   final String driverName;
//   final String driverPhoto;

//   @override
//   State<AudioCallScreen> createState() => _AudioCallScreenState();
// }

// class _AudioCallScreenState extends State<AudioCallScreen> {
//   DateTime? _callStartTime;

//   @override
//   void initState() {
//     super.initState();
//     context.read<CallCubit>().startCall(callId: widget.callId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Audio Call'),
//         centerTitle: true,
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () async {
//             await context.read<CallCubit>().endCall();
//             if (mounted) {
//               // Navigator.of(context).pop();
//             }
//           },
//         ),
//       ),
//       body: BlocConsumer<CallCubit, AudioCallState>(
//         listener: (context, state) {
//           if (state.status == CustomCallStatus.error) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.errorMessage ?? 'An error occurred'),
//               ),
//             );
//           }
//           if (state.status == CustomCallStatus.connected &&
//               _callStartTime == null) {
//             setState(() {
//               _callStartTime = DateTime.now();
//             });
//           }
//           // When call is ended or disconnected
//           if (state.status == CustomCallStatus.idle && state.callId == null) {
//             Navigator.of(context).popUntil((route) {
//               return route.isFirst ||
//                   route.settings.name == MainActivityScreen.routeName;
//             });
//           }
//         },
//         builder: (context, state) {
//           if (state.status == CustomCallStatus.connecting) {
//             return Container(
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/images/caller.jpg'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const VSpace(48),
//                     const CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                     const VSpace(16),
//                     Text(
//                       'Calling ${widget.driverName}...',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           return Stack(
//             children: [
//               // Main content
//               Container(
//                 decoration: const BoxDecoration(
//                   image: DecorationImage(
//                     image: AssetImage('assets/images/caller.jpg'),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 48),

//                         // Participants list (showing only remote participants)
//                         if (state.participants.isNotEmpty)
//                           AudioCallParticipantList(
//                             participants: state.participants,
//                           ),
//                       ],
//                     ),
//                     // Add padding at the bottom to account for the controls
//                     SizedBox(height: MediaQuery.of(context).size.height * 0.25),
//                   ],
//                 ),
//               ),

//               Positioned(
//                 top: 50,
//                 right: 40,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(13),
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 19.87, sigmaY: 19.87),
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           Text(
//                             widget.driverName,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Column(
//                             children: [
//                               if (state.status == CustomCallStatus.connected &&
//                                   _callStartTime != null) ...[
//                                 // Call duration timer
//                                 CallDurationTimer(
//                                   startTime: _callStartTime!,
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w700,
//                                     color: Colors.grey.shade300,
//                                   ),
//                                 ),
//                               ],
//                               Text(
//                                 _getCallStatusText(state.status),
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               // Positioned controls at the bottom
//               Positioned(
//                 left: 0,
//                 right: 0,
//                 bottom: 0,
//                 child: SafeArea(
//                   child: AudioCallControls(
//                     isMicEnabled: state.participants.any((p) => p.isLocal)
//                         ? state.participants
//                             .firstWhere((p) => p.isLocal)
//                             .isAudioEnabled
//                         : state.isMicEnabled,
//                     onToggleMic: () =>
//                         context.read<CallCubit>().toggleMicrophone(),
//                     onEndCall: () async {
//                       await context.read<CallCubit>().endCall();
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   String _getCallStatusText(CustomCallStatus status) {
//     switch (status) {
//       case CustomCallStatus.connecting:
//         return 'Connecting...';
//       case CustomCallStatus.connected:
//         return 'Connected';
//       case CustomCallStatus.disconnecting:
//         return 'Ending call...';
//       case CustomCallStatus.error:
//         return 'Connection error';
//       default:
//         return 'In call';
//     }
//   }
// }
