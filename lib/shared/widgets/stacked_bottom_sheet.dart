import 'package:flutter/material.dart';

Widget stackedBottomSheet(
  BuildContext context,
  Widget child, {
  bool useOnlyBackgroundColor = false,
  double topLeftRadius = 14.32,
  double topRightRadius = 14.32,
}) {
  return Container(
    decoration: BoxDecoration(
      color: useOnlyBackgroundColor ? Colors.white : null,
      gradient: useOnlyBackgroundColor
          ? null
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF2DD), Color(0xFFFCFCFC)],
            ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeftRadius),
        topRight: Radius.circular(topRightRadius),
      ),
    ),
    child: child,
  );
}
