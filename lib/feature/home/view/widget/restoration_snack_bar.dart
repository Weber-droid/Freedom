import 'package:flutter/material.dart';

Future<void> showRestorationSnackBar(
  BuildContext context,
  String message, {
  bool isSuccess = false,

  bool isError = false,
}) async {
  if (context.mounted) return;

  Color backgroundColor = Colors.blue;
  IconData icon = Icons.info_outline;

  if (isSuccess) {
    backgroundColor = Colors.green;
    icon = Icons.check_circle_outline;
  } else if (isError) {
    backgroundColor = Colors.orange;
    icon = Icons.warning_outlined;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: isError ? 4 : 3),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
