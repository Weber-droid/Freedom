import 'package:flutter/material.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/view/widget/cancel_ride_sheet.dart';
import 'package:freedom/feature/home/view/widget/rider_time_line.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/shared/responsive_helpers.dart';

class RiderFoundBottomSheet2 extends StatelessWidget {
  const RiderFoundBottomSheet2({super.key});

  @override
  Widget build(BuildContext context) {
    final isMuliStop = context.select<RideCubit, bool>(
      (cubit) => cubit.state.isMultiDestination,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final baseHeight = getBaseHeight(constraints);
        final horizontalPadding = getHorizontalPadding(constraints);
        final borderRadius = isTablet ? 24.0 : 20.0;

        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight * 0.85,
            minHeight: getMinHeight(constraints),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: baseHeight,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                ),
              ),
              Positioned(
                top: getContentTopOffset(constraints),
                left: 0,
                right: 0,
                child: Container(
                  height: baseHeight - getContentTopOffset(constraints),
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    gradient: whiteAmberGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: getSpacing(constraints, 13)),

                        Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),

                        SizedBox(height: getSpacing(constraints, 15)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: const RiderContainerAndRideActions(),
                        ),

                        SizedBox(height: getSpacing(constraints, 14)),

                        // Route container
                        Container(
                          decoration: BoxDecoration(
                            color: fillColor2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            getSpacing(constraints, 10),
                            horizontalPadding * 0.4,
                            getSpacing(constraints, 17.78),
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Route',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: getFontSize(constraints, 11.51),
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),

                              SizedBox(height: getSpacing(constraints, 8)),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.3,
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  child: BlocBuilder<RideCubit, RideState>(
                                    builder: (context, state) {
                                      if (state
                                                  .rideRequestModel
                                                  ?.pickupLocation !=
                                              null &&
                                          state
                                                  .rideRequestModel
                                                  ?.dropoffLocation !=
                                              null &&
                                          !isMuliStop) {
                                        return RiderTimeLine(
                                          destinationLocation: [],
                                          pickUpDetails:
                                              ' ${state.rideRequestModel?.pickupLocation.address}',
                                          destinationDetails:
                                              '${state.rideRequestModel?.dropoffLocation.address}',
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: getSpacing(constraints, 30)),

                        // Cancel button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: getButtonHeight(constraints),
                            child: FreedomButton(
                              onPressed: () {
                                _showCancelRideSheet(context);
                              },
                              useGradient: true,
                              gradient: gradient,
                              title: 'Cancel Ride',
                              buttonTitle: Text(
                                'Cancel Ride',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: getFontSize(constraints, 16),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom padding for safe area
                        SizedBox(height: getSpacing(constraints, 20)),
                      ],
                    ),
                  ),
                ),
              ),

              // Top timer section
              Positioned(
                top: getTimerTopOffset(constraints),
                left: horizontalPadding,
                right: horizontalPadding,
                child: Row(
                  children: [
                    Image(
                      image: const AssetImage(
                        'assets/images/jump-time_icon.png',
                      ),
                      width: getIconSize(constraints, 24),
                      height: getIconSize(constraints, 24),
                    ),
                    SizedBox(width: getSpacing(constraints, 8)),
                    Expanded(
                      child: Text(
                        'The rider will arrive in ....',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getFontSize(constraints, 14),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getSpacing(constraints, 8),
                        vertical: getSpacing(constraints, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/clock_icon.svg',
                            width: getIconSize(constraints, 16),
                            height: getIconSize(constraints, 16),
                          ),
                          SizedBox(width: getSpacing(constraints, 4)),
                          Text(
                            '08:12 Mins',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: getFontSize(constraints, 11.76),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelRideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return BlocConsumer<RideCubit, RideState>(
          listener: (context, state) {
            if (state.cancellationStatus == RideCancellationStatus.cancelled) {
              Navigator.of(context).pop();
              context.showToast(
                message: state.message ?? '',
                position: ToastPosition.top,
              );
            }
          },
          builder: (context, state) {
            if (state.cancellationStatus == RideCancellationStatus.canceling) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return CancelRideSheet(
              onConfirmCancel: (reason, comment) {
                context.read<RideCubit>().cancelRide(
                  reason:
                      comment == null || comment.isEmpty
                          ? reason
                          : '$reason : $comment',
                );
              },
            );
          },
        );
      },
    );
  }
}
