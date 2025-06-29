import 'dart:async';
import 'package:flutter/material.dart';

class CallDurationTimer extends StatefulWidget {
  const CallDurationTimer({
    required this.startTime,
    this.style,
    super.key,
  });

  // The timestamp when the call started
  final DateTime startTime;
  // Optional text style for the timer
  final TextStyle? style;

  @override
  State<CallDurationTimer> createState() => _CallDurationTimerState();
}

class _CallDurationTimerState extends State<CallDurationTimer> {
  // Timer that triggers UI updates
  late Timer _timer;
  // Duration of the call
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.startTime);

    // Update the duration every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format duration as HH:MM:SS
    String formattedTime = _formatDuration(_duration);

    return Text(
      formattedTime,
      style: widget.style ??
          TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  // Formats the duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    // Only show hours if the call is more than an hour long
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
