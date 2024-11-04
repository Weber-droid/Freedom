import 'package:flutter/material.dart';

class FreedomButton extends StatelessWidget {
  const FreedomButton(
      {required this.onPressed, this.style, required this.title, super.key});
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Widget title;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: TextButton(
        onPressed: () {},
        child: title,
      ),
    );
  }
}
