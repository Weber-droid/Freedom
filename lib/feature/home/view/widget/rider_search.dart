import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowRiderSearch<T extends StateStreamable<S>, S> extends StatelessWidget {
  const ShowRiderSearch({
    super.key,
    required this.searchTimeElapsedSelector,
    required this.statusSelector,
    required this.rideDataSelector,
    required this.cancellationStatusSelector,
    required this.messageSelector,
    required this.onCancelPressed,
    this.searchTimeDisplayText = 'Searching for driver in about',
    this.cancelButtonText = 'Cancel Ride',
    this.cancelReason = 'User Cancelled',
    this.estimatedDistanceLabel = 'Estimated Distance',
    this.estimatedTimeLabel = 'Estimated Time',
    this.fareLabel = 'Fare',
  });

  // State selectors
  final int Function(S state) searchTimeElapsedSelector;
  final dynamic Function(S state) statusSelector;
  final dynamic Function(S state) rideDataSelector;
  final dynamic Function(S state) cancellationStatusSelector;
  final String? Function(S state) messageSelector;

  // Callbacks
  final VoidCallback onCancelPressed;

  // Customizable text
  final String searchTimeDisplayText;
  final String cancelButtonText;
  final String cancelReason;
  final String estimatedDistanceLabel;
  final String estimatedTimeLabel;
  final String fareLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return BlocConsumer<T, S>(
          listener: (context, state) {
            // Handle cancellation status changes
            final cancellationStatus = cancellationStatusSelector(state);
            if (cancellationStatus.toString().contains('cancelled')) {
              final message = messageSelector(state);
              if (message != null) {
                context.showToast(
                  message: message,
                  position: ToastPosition.top,
                );
              }
            }
          },
          buildWhen:
              (previous, current) =>
                  searchTimeElapsedSelector(previous) !=
                      searchTimeElapsedSelector(current) ||
                  statusSelector(previous) != statusSelector(current),
          builder: (context, state) {
            final searchTimeElapsed = searchTimeElapsedSelector(state);
            if (searchTimeElapsed == 0) {
              return const SizedBox.shrink();
            }

            final remainingSeconds = 60 - searchTimeElapsed;
            final minutes = remainingSeconds ~/ 60;
            final seconds = remainingSeconds % 60;
            final timeText = seconds > 0 ? ' $seconds s' : ' $minutes min';

            final rideData = rideDataSelector(state);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: constraints.maxWidth,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  top: 39,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      gradient: whiteAmberGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const VSpace(13),
                        Container(height: 5, width: 50, color: Colors.white),
                        const VSpace(15),

                        // Estimated Distance
                        _buildInfoItem(
                          context,
                          estimatedDistanceLabel,
                          Text(
                            _getDistanceText(rideData),
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          ),
                        ),

                        VSpace.md,

                        // Estimated Time
                        _buildInfoItem(
                          context,
                          estimatedTimeLabel,
                          Text(
                            '${_getDurationText(rideData)} $timeText',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          ),
                        ),

                        VSpace.md,

                        // Fare
                        _buildInfoItem(
                          context,
                          fareLabel,
                          Text(
                            _getFareText(rideData),
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          ),
                        ),

                        const VSpace(20),

                        // Cancel Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: BlocBuilder<T, S>(
                            builder: (context, state) {
                              final cancellationStatus =
                                  cancellationStatusSelector(state);
                              final isCanceling = cancellationStatus
                                  .toString()
                                  .contains('canceling');

                              return FreedomButton(
                                onPressed: onCancelPressed,
                                useGradient: true,
                                gradient: gradient,
                                title: cancelButtonText,
                                useLoader: true,
                                buttonTitle: Text(
                                  cancelButtonText,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child:
                                    isCanceling
                                        ? const CircularProgressIndicator.adaptive(
                                          backgroundColor: Colors.white,
                                        )
                                        : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      const Image(
                        image: AssetImage('assets/images/jump-time_icon.png'),
                      ),
                      const HSpace(3),
                      Expanded(
                        child: Text(
                          '$searchTimeDisplayText $timeText',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      padding: const EdgeInsets.fromLTRB(15, 10, 6, 17.78),
      margin: const EdgeInsets.symmetric(horizontal: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 11.51,
              fontWeight: FontWeight.w600,
              height: 0,
            ),
          ),
          child,
        ],
      ),
    );
  }

  // Helper methods to extract data from different state structures
  String _getDistanceText(dynamic rideData) {
    if (rideData == null) return '';

    // Handle different data structures
    if (rideData is Map) {
      return rideData['estimatedDistance']?['text']?.toString() ??
          rideData['distance']?.toString() ??
          '';
    }

    // Handle object with properties
    try {
      return rideData.estimatedDistance?['text']?.toString() ??
          rideData.distance?.toString() ??
          '';
    } catch (e) {
      return '';
    }
  }

  String _getDurationText(dynamic rideData) {
    if (rideData == null) return '';

    // Handle different data structures
    if (rideData is Map) {
      return rideData['estimatedDuration']?['text']?.toString() ??
          rideData['duration']?.toString() ??
          '';
    }

    // Handle object with properties
    try {
      return rideData.estimatedDuration?['text']?.toString() ??
          rideData.duration?.toString() ??
          '';
    } catch (e) {
      return '';
    }
  }

  String _getFareText(dynamic rideData) {
    if (rideData == null) return '';

    // Handle different data structures
    if (rideData is Map) {
      final fare =
          rideData['fare']?.toString() ?? rideData['price']?.toString() ?? '';
      final currency = rideData['currency']?.toString() ?? '';
      return '$fare $currency'.trim();
    }

    // Handle object with properties
    try {
      final fare =
          rideData.fare?.toString() ?? rideData.price?.toString() ?? '';
      final currency = rideData.currency?.toString() ?? '';
      return '$fare $currency'.trim();
    } catch (e) {
      return '';
    }
  }
}
