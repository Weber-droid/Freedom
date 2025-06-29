import 'package:flutter/material.dart';

double getBaseHeight(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 400; // Desktop
    if (constraints.maxWidth > 600) return 375;  // Tablet
    return constraints.maxHeight < 600 ? 300 : 349; // Mobile
  }

  double getMinHeight(BoxConstraints constraints) {
    return constraints.maxHeight < 600 ? 250 : 300;
  }

  double getContentTopOffset(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 45; // Desktop
    if (constraints.maxWidth > 600) return 42;  // Tablet
    return constraints.maxHeight < 600 ? 35 : 39; // Mobile
  }

  double getTimerTopOffset(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 12; // Desktop
    if (constraints.maxWidth > 600) return 10;  // Tablet
    return constraints.maxHeight < 600 ? 6 : 9; // Mobile
  }

  double getHorizontalPadding(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 32; // Desktop
    if (constraints.maxWidth > 600) return 24;  // Tablet
    return 15; // Mobile
  }

  double getSpacing(BoxConstraints constraints, double baseSpacing) {
    final scaleFactor = getScaleFactor(constraints);
    return baseSpacing * scaleFactor;
  }

  double getFontSize(BoxConstraints constraints, double baseFontSize) {
    final scaleFactor = getScaleFactor(constraints);
    return (baseFontSize * scaleFactor).clamp(baseFontSize * 0.8, baseFontSize * 1.3);
  }

  double getIconSize(BoxConstraints constraints, double baseIconSize) {
    final scaleFactor = getScaleFactor(constraints);
    return (baseIconSize * scaleFactor).clamp(baseIconSize * 0.8, baseIconSize * 1.4);
  }

  double getButtonHeight(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 56; // Desktop
    if (constraints.maxWidth > 600) return 52;  // Tablet
    return constraints.maxHeight < 600 ? 44 : 48; // Mobile
  }

  double getScaleFactor(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 1.2; // Desktop
    if (constraints.maxWidth > 600) return 1.1;  // Tablet
    return constraints.maxHeight < 600 ? 0.9 : 1.0; // Mobile
  }