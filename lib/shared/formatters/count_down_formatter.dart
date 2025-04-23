String formatTimeLeft(int start) {
  final minutes = start ~/ 60;
  final seconds = start % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
