import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class RiderTimeLine extends StatelessWidget {
  const RiderTimeLine({
    required this.destinationLocation,
    this.destinationDetails = '',
    this.pickUpDetails = '',
    super.key,
  });

  final String destinationDetails;
  final String pickUpDetails;
  final List<Location> destinationLocation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance line and address positioning container
            _buildTimelineWithAddresses(constraints),
          ],
        );
      },
    );
  }

  Widget _buildTimelineWithAddresses(BoxConstraints constraints) {
    // Calculate responsive dimensions
    final lineWidth = _getLineWidth(constraints);
    final containerHeight = _getTimelineHeight(constraints);

    return SizedBox(
      width: lineWidth,
      height: containerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // SVG Distance line - positioned at the center
          Positioned(
            top: _getLineVerticalPosition(constraints),
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/distance_line.svg',
                width: lineWidth,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Pickup address - positioned at the left end of the line
          Positioned(
            top: _getAddressVerticalPosition(constraints),
            left: _getPickupHorizontalPosition(constraints),
            child: _buildAddressSection(
              constraints: constraints,
              title: 'Pick up',
              content: _buildPickupContent(constraints),
              isPickup: true,
              maxWidth: _getAddressMaxWidth(constraints, true),
            ),
          ),

          // Destination address - positioned at the right end of the line
          Positioned(
            top: _getAddressVerticalPosition(constraints),
            right: _getDestinationHorizontalPosition(constraints),
            child: _buildAddressSection(
              constraints: constraints,
              title: 'Destination',
              content: _buildDestinationContent(constraints),
              isPickup: false,
              maxWidth: _getAddressMaxWidth(constraints, false),
            ),
          ),

          // Multiple destinations - positioned along the line if needed
          if (destinationLocation.isNotEmpty)
            ..._buildMultipleDestinationMarkers(constraints),
        ],
      ),
    );
  }

  // Build individual address sections
  Widget _buildAddressSection({
    required BoxConstraints constraints,
    required String title,
    required Widget content,
    required bool isPickup,
    required double maxWidth,
  }) {
    return SizedBox(
      width: maxWidth,
      child: Column(
        crossAxisAlignment:
            isPickup ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: _getFontSize(constraints, 8.78),
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
            textAlign: isPickup ? TextAlign.left : TextAlign.right,
          ),
          SizedBox(height: _getSpacing(constraints, 4)),
          content,
        ],
      ),
    );
  }

  // Build pickup content
  Widget _buildPickupContent(BoxConstraints constraints) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return darkGoldGradient.createShader(bounds);
      },
      child: destinationLocation.isEmpty
          ? _buildAddressText(constraints, pickUpDetails, true)
          : _buildAddressText(constraints, pickUpDetails, true),
    );
  }

  // Build destination content
  Widget _buildDestinationContent(BoxConstraints constraints) {
    if (destinationDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return darkGoldGradient.createShader(bounds);
      },
      child: _buildAddressText(constraints, destinationDetails, false),
    );
  }

  // Build address text with proper alignment
  Widget _buildAddressText(
      BoxConstraints constraints, String text, bool isPickup) {
    if (text.isEmpty) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: _getMaxTextHeight(constraints),
      ),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: const Color(0xFFF59E0B),
            fontSize: _getFontSize(constraints, 9.07),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          textAlign: isPickup ? TextAlign.left : TextAlign.right,
          maxLines: _getMaxLines(constraints),
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ),
    );
  }

  // Build multiple destination markers along the line
  List<Widget> _buildMultipleDestinationMarkers(BoxConstraints constraints) {
    if (destinationLocation.isEmpty) return [];

    List<Widget> markers = [];
    final lineWidth = _getLineWidth(constraints);

    // Calculate positions along the line for multiple destinations
    for (int i = 0; i < destinationLocation.length; i++) {
      final position = _calculateDestinationPosition(
          i, destinationLocation.length, lineWidth);

      markers.add(
        Positioned(
          top: _getMultiDestinationVerticalPosition(constraints),
          left: position - (_getAddressMaxWidth(constraints, false) / 2),
          child: _buildMultiDestinationMarker(
              constraints, destinationLocation[i], i),
        ),
      );
    }

    return markers;
  }

  Widget _buildMultiDestinationMarker(
      BoxConstraints constraints, Location location, int index) {
    return SizedBox(
      width: _getAddressMaxWidth(constraints, false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),

          SizedBox(height: _getSpacing(constraints, 4)),

          Text(
            'Stop ${index + 1}',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: _getFontSize(constraints, 7),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: _getSpacing(constraints, 2)),

          ShaderMask(
            shaderCallback: (Rect bounds) {
              return darkGoldGradient.createShader(bounds);
            },
            child: Text(
              '${location.name}, ${location.address}',
              style: GoogleFonts.poppins(
                color: const Color(0xFFF59E0B),
                fontSize: _getFontSize(constraints, 8),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Position calculation methods
  double _getLineWidth(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return constraints.maxWidth * 0.85;
    if (constraints.maxWidth > 600) return constraints.maxWidth * 0.9;
    return constraints.maxWidth * 0.95;
  }

  double _getTimelineHeight(BoxConstraints constraints) {
    // Account for addresses above and below the line
    final baseHeight = _getSpacing(constraints, 80);
    final multiDestinationExtra =
        destinationLocation.isNotEmpty ? _getSpacing(constraints, 40) : 0;
    return baseHeight + multiDestinationExtra;
  }

  double _getLineVerticalPosition(BoxConstraints constraints) {
    // Position line in the middle-upper part of the container
    return _getSpacing(constraints, 35);
  }

  double _getAddressVerticalPosition(BoxConstraints constraints) {
    // Position addresses below the line
    return _getSpacing(constraints, 70);
  }

  double _getMultiDestinationVerticalPosition(BoxConstraints constraints) {
    // Position multi-destination markers above the line
    return _getSpacing(constraints, 5);
  }

  double _getPickupHorizontalPosition(BoxConstraints constraints) {
    // Align with the left end of the SVG line (accounting for SVG internal padding)
    return _getSpacing(constraints, 8);
  }

  double _getDestinationHorizontalPosition(BoxConstraints constraints) {
    // Align with the right end of the SVG line (accounting for SVG internal padding)
    return _getSpacing(constraints, 8);
  }

  double _getAddressMaxWidth(BoxConstraints constraints, bool isPickup) {
    final totalWidth = _getLineWidth(constraints);
    // Each address gets roughly 40% of the line width to prevent overlap
    return (totalWidth * 0.4).clamp(100, 200);
  }

  double _calculateDestinationPosition(int index, int total, double lineWidth) {
    // Distribute multiple destinations evenly along the line
    if (total == 1) return lineWidth * 0.5;

    final segmentWidth =
        lineWidth * 0.7; // Use 70% of line width for distribution
    final startOffset = lineWidth * 0.15; // Start 15% from the left

    return startOffset + (segmentWidth / (total - 1)) * index;
  }

  // Helper methods for responsive sizing
  double _getSpacing(BoxConstraints constraints, double baseSpacing) {
    return baseSpacing * _getScaleFactor(constraints);
  }

  double _getFontSize(BoxConstraints constraints, double baseFontSize) {
    final scaleFactor = _getScaleFactor(constraints);
    return (baseFontSize * scaleFactor).clamp(
      baseFontSize * 0.8,
      baseFontSize * 1.4,
    );
  }

  double _getMaxTextHeight(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 60;
    if (constraints.maxWidth > 600) return 50;
    return 40;
  }

  int _getMaxLines(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 4;
    if (constraints.maxWidth > 600) return 3;
    return 2;
  }

  double _getScaleFactor(BoxConstraints constraints) {
    if (constraints.maxWidth > 1024) return 1.2;
    if (constraints.maxWidth > 600) return 1.1;
    if (constraints.maxWidth < 350) return 0.9;
    return 1.0;
  }
}
