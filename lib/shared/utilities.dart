import 'package:flutter/material.dart';

class _Space extends StatelessWidget {
  const _Space(this.width, this.height);
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

class VSpace {
  const VSpace(this.height);
  VSpace.sm() : this(Insets.sm);
  VSpace.md() : this(Insets.m);

  VSpace.xs() : this(Insets.xs);
  final double height;
}

class HSpace {
  const HSpace(this.width);

  HSpace.xs() : this(Insets.xs);
  HSpace.sm() : this(Insets.sm);
  HSpace.md() : this(Insets.m);
  final double width;
}

class Insets {
  static double gutterScale = 1;

  static double scale = 1;

  /// Dynamic insets, may get scaled with the device size
  static double get mGutter => m * gutterScale;

  static double get lGutter => l * gutterScale;

  static double get xs => 2 * scale;

  static double get sm => 6 * scale;

  static double get m => 15 * scale;

  static double get l => 24 * scale;

  static double get xl => 34 * scale;
}
