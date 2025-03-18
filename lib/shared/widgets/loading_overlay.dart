import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable loading overlay component with a blurred background
///
/// Wraps any widget with a loading state that shows a blurred overlay
/// and a circular progress indicator when isLoading is true.
class BlurredLoadingOverlay extends StatelessWidget {
  const BlurredLoadingOverlay({
    required this.child,
    required this.isLoading,
    super.key,
    this.blurAmount = 5.0,
    this.overlayColor = const Color(0x4D000000), // Black with 30% opacity
    this.indicatorBackgroundColor = Colors.white,
    this.loadingIndicator,
    this.indicatorPadding = const EdgeInsets.all(24),
    this.indicatorBorderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  /// The child widget to display
  final Widget child;

  /// Whether the loading overlay should be shown
  final bool isLoading;

  /// The blur amount for the background (default: 5.0)
  final double blurAmount;

  /// The color of the overlay (default: black with 30% opacity)
  final Color overlayColor;

  /// The background color of the loading indicator container
  final Color indicatorBackgroundColor;

  /// The loading indicator widget (default: CircularProgressIndicator.adaptive())
  final Widget? loadingIndicator;

  /// Padding around the loading indicator
  final EdgeInsets indicatorPadding;

  /// Border radius of the loading indicator container
  final BorderRadius indicatorBorderRadius;

  @override
  Widget build(BuildContext context) {
    // If not loading, just return the child
    if (!isLoading) {
      return child;
    }

    // If loading, return the child with the blurred overlay
    return Stack(
      children: [
        // The base content that will be blurred
        child,

        // Blurred overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            color: overlayColor,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Centered indicator with container
        Center(
          child: Container(
            padding: indicatorPadding,
            decoration: BoxDecoration(
              color: indicatorBackgroundColor,
              borderRadius: indicatorBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                loadingIndicator ?? const CircularProgressIndicator.adaptive(),
          ),
        ),
      ],
    );
  }
}
