import 'package:flutter/material.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

class ShowRiderSearch extends StatelessWidget {
  const ShowRiderSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return BlocConsumer<RideCubit, RideState>(
        listener: (context, state) {},
        buildWhen: (previous, current) =>
            previous.searchTimeElapsed != current.searchTimeElapsed ||
            previous.status != current.status,
        builder: (context, state) {
          if (state.searchTimeElapsed == 0) {
            return const SizedBox.shrink();
          }

          final remainingSeconds = 60 - state.searchTimeElapsed;
          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;
          final timeText = seconds > 0
              ? ' $seconds ${seconds == 1 ? 'second' : 'seconds'}'
              : ' $minutes ${minutes == 1 ? 'minute' : 'minutes'}';

          final rideData = state.rideResponse!.data;

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
                      _buildInfoItem(
                          context,
                          'Estimated Distance',
                          Text(
                            '${rideData.estimatedDistance?['text']}',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          )),
                      VSpace.md,
                      _buildInfoItem(
                          context,
                          'Estimated Time',
                          Text(
                            '${rideData.estimatedDuration?['text'] ?? ''} $timeText',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          )),
                      VSpace.md,
                      _buildInfoItem(
                          context,
                          'Fare',
                          Text(
                            '${rideData.fare} ${rideData.currency}',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          )),
                      const VSpace(20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: BlocConsumer<RideCubit, RideState>(
                          listener: (context, state) {
                            if (state.cancellationStatus ==
                                RideCancellationStatus.cancelled) {
                              context.showToast(
                                message: state.message ?? '',
                                position: ToastPosition.top,
                              );
                            }
                          },
                          builder: (context, state) {
                            return FreedomButton(
                              onPressed: () {
                                context
                                    .read<RideCubit>()
                                    .cancelRide(reason: 'User Cancelled');
                              },
                              useGradient: true,
                              gradient: gradient,
                              title: 'Cancel Ride',
                              useLoader: true,
                              buttonTitle: Text(
                                'Cancel Ride',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: state.cancellationStatus ==
                                      RideCancellationStatus.canceling
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
                    Text(
                      'Searching for driver in about $timeText',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      );
    });
  }

  Widget _buildInfoItem(BuildContext context, String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
        ),
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
          child
        ],
      ),
    );
  }
}
