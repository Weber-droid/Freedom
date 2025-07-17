import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/view/widget/cancel_ride_sheet.dart';
import 'package:freedom/feature/home/view/widget/logistics_bottomsheet_content.dart';
import 'package:freedom/feature/home/view/widget/rider_time_line.dart';
import 'package:freedom/feature/home/view/widget/search_sheet.dart';
import 'package:freedom/feature/home/widgets/audio_call_widget.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/message_driver/view/message_driver_screen.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';
import 'package:freedom/shared/responsive_helpers.dart';
import 'package:freedom/shared/widgets/custom_dropdown_button.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class ChoosePayMentMethod extends StatefulWidget {
  const ChoosePayMentMethod({super.key});

  @override
  State<ChoosePayMentMethod> createState() => ChoosePayMentMethodState();
}

class ChoosePayMentMethodState extends State<ChoosePayMentMethod> {
  String defaultValue = 'card';

  final items = <String>['cash', 'card'];

  @override
  Widget build(BuildContext context) {
    final logWallets = context.select<WalletCubit, List<PaymentMethod>>((
      WalletCubit c,
    ) {
      final state = c.state;
      if (state is WalletLoaded) {
        return state.paymentMethods;
      }
      return [];
    });

    log('logWallets: ${logWallets.map((e) => e.toJson()).toList()}');
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.08,
      margin: EdgeInsets.symmetric(horizontal: 2),
      padding: EdgeInsets.only(left: 5),
      decoration: ShapeDecoration(
        color: const Color(0xA3FFFCF8),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 49.39,
            height: 47.62,
            padding: const EdgeInsets.only(
              top: 8.98,
              left: 9.88,
              bottom: 9.01,
              right: 9.88,
            ),
            decoration: ShapeDecoration(
              color: const Color(0x38F4950D),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1.76, color: Colors.white),
                borderRadius: BorderRadius.circular(12.35),
              ),
            ),
            child: SvgPicture.asset('assets/images/pay_with_cash.svg'),
          ),
          const HSpace(8.98),
          DropdownButton<String>(
            elevation: 0,
            dropdownColor: Colors.white,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
            ),
            value: defaultValue,
            items:
                items.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                  );
                }).toList(),
            onChanged: (val) {
              if (val == 'card' && logWallets.isEmpty) {
                context.showToast(
                  message: 'Go to profile to add a card first',
                  type: ToastType.error,
                  position: ToastPosition.top,
                );
                return;
              }
              if (val != null) {
                context.read<RideCubit>().setPayMentMethod(val);
              }
              if (val != null) {
                setState(() {
                  defaultValue = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class LocationSearchTextField extends StatefulWidget {
  const LocationSearchTextField({
    required this.onTap,
    required this.onSearch,
    super.key,
  });

  final VoidCallback onTap;
  final VoidCallback onSearch;

  @override
  State<LocationSearchTextField> createState() =>
      _LocationSearchTextFieldState();
}

class _LocationSearchTextFieldState extends State<LocationSearchTextField> {
  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: Colors.black,
      onTap: widget.onSearch,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
        ),
        fillColor: const Color(0xfffffaf0),
        filled: true,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: SvgPicture.asset(
            'assets/images/search_field_icon.svg',
            height: 24,
            width: 24,
          ),
        ),
        hintText: 'Your Destination, Send item',
        hintStyle: GoogleFonts.poppins(
          color: Colors.black.withValues(alpha: 0.34),
          fontSize: 10.89,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(top: 10, right: 12, bottom: 9),
          child: CustomDropDown(
            items: dropdownItems,
            initialValue: defaultValue,
            onChanged: (value) {
              setState(() {
                defaultValue = value;
              });
              if (value == 'Later') {
                widget.onTap();
              }
            },
          ),
        ),
      ),
    );
  }
}

class ChooseServiceTextDetailsUi2 extends StatelessWidget {
  const ChooseServiceTextDetailsUi2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 27,
          width: 27,
          child: SvgPicture.asset('assets/images/choose_bike.svg'),
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [gradient1, gradient2],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Okada (motor)',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            'Ride with your favourite Motorcycle',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 10.89,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

class ChooseServiceTextDetailsUi extends StatelessWidget {
  const ChooseServiceTextDetailsUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 27,
          width: 27,
          child: SvgPicture.asset('assets/images/choose_logistics.svg'),
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [gradient1, gradient2],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Delivery',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            'Deliver your goods and services nationwide',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 10.89,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

class ChooseServiceBox extends StatelessWidget {
  const ChooseServiceBox({super.key, this.isSelected = false, this.child});
  final bool isSelected;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 159,
      height: MediaQuery.of(context).size.height * 0.15,
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            isSelected
                ? GradientBoxBorder(gradient: redLinearGradient)
                : Border.all(color: const Color(0xFFfeebca)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class LogisticsDetailContainer extends StatelessWidget {
  const LogisticsDetailContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 53,
      padding: const EdgeInsets.only(left: 15, right: 13),
      width: double.infinity,
      decoration: BoxDecoration(
        color: fillColor2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/logistics_filter_icon.svg'),
          const HSpace(8),
          Text(
            'Delivery Details',
            style: GoogleFonts.poppins(
              color: hintTextColor,
              fontSize: 10.89,
              fontWeight: FontWeight.w500,
              height: 0,
            ),
          ),
          const Spacer(),
          SvgPicture.asset('assets/images/right-triangle_icon.svg'),
        ],
      ),
    );
  }
}

class LogisticsPrefixIcon extends StatelessWidget {
  const LogisticsPrefixIcon({super.key, this.imageName});
  final String? imageName;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      margin: const EdgeInsets.only(top: 10, left: 4, bottom: 10, right: 5),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: SvgPicture.asset('assets/images/$imageName.svg'),
    );
  }
}

Future<void> showLogisticsBottomSheet(
  BuildContext context, {
  required TextEditingController pickUpController,
  required TextEditingController destinationController,
  required TextEditingController houseNumberController,
  required TextEditingController phoneNumberController,
  required TextEditingController itemDestinationController,
  required TextEditingController itemDestinationHomeNumberController,
}) {
  return showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return LogisticsBottomSheetContent(
        pickUpController: pickUpController,
        destinationController: destinationController,
        houseNumberController: houseNumberController,
        phoneNumberController: phoneNumberController,
        itemDestinationController: itemDestinationController,
        itemDestinationHomeNumberController:
            itemDestinationHomeNumberController,
      );
    },
  );
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(12),
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }
}

int trackSelectedIndex = 0;

Future<void> showMotorCycleBottomSheet(
  BuildContext context, {
  required TextEditingController destinationController,
  required TextEditingController pickUpLocationController,
  required List<TextEditingController> destinationControllers,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return SearchSheet(
        destinationController: destinationController,
        pickUpLocationController: pickUpLocationController,
        destinationControllers: destinationControllers,
        clearRecentLocations: getIt(),
        getPlaceDetails: getIt(),
        getPlacePredictions: getIt(),
        getRecentLocations: getIt(),
        getSavedLocations: getIt(),
      );
    },
  );
}

// Build section header widget
Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 11.68,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    ),
  );
}

// Build location item widget
Widget buildLocationItem({
  required IconData iconData,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(iconData, color: Colors.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10.13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void showCuperTinoDialog(BuildContext context, {required Widget child}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(top: false, child: child),
      );
    },
  );
}

Future<void> showAlertDialog(
  BuildContext context, {
  required String title,
  required String message,
  required void Function() confirm,
  required void Function() cancel,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  return showAdaptiveDialog(
    context: context,
    barrierDismissible: false,
    builder: (builder) {
      return AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(13.8, 19.23, 12.26, 50.9),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/images/emergency_icon.svg'),
              const VSpace(13),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const VSpace(9.66),
              SizedBox(
                width: 261.38,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.460),
                    fontSize: 15.44,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    onPressed: cancel,
                    child: Text(
                      cancelText,
                      style: GoogleFonts.poppins(
                        fontSize: 12.06,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const HSpace(8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(gradient: gradient),
                  child: TextButton(
                    onPressed: confirm,
                    style: TextButton.styleFrom(),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.poppins(
                        fontSize: 12.06,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class RiderFoundBottomSheet extends StatelessWidget {
  const RiderFoundBottomSheet({super.key});

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

class RiderContainerAndRideActions extends StatefulWidget {
  const RiderContainerAndRideActions({super.key});

  @override
  State<RiderContainerAndRideActions> createState() =>
      _RiderContainerAndRideActionsState();
}

class _RiderContainerAndRideActionsState
    extends State<RiderContainerAndRideActions> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideCubit, RideState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
            decoration: BoxDecoration(
              color: fillColor2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      padding: const EdgeInsets.only(left: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(7),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/rider_image.png'),
                        ),
                      ),
                    ),
                    const HSpace(6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.driverAccepted?.driverName ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 10.89,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Logistic',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF939393),
                            fontSize: 10.89,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(MessageDriverScreen.routeName);
                      },
                      child: Container(
                        height: 35.49,
                        width: 35.49,
                        padding: const EdgeInsets.fromLTRB(
                          6.37,
                          8.19,
                          6.37,
                          5.46,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(7.28),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/user_message_icon.svg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 7.4), // Space between icons
                    // Second Icon
                    GestureDetector(
                      onTap: () {
                        final callId =
                            '${DateTime.now().millisecondsSinceEpoch}';
                        Navigator.of(context).push(
                          MaterialPageRoute<dynamic>(
                            builder:
                                (context) => AudioCallScreen(
                                  callId: callId,
                                  driverName:
                                      state.driverAccepted?.driverName ?? '',
                                  driverPhoto: 'assets/images/rider_image.png',
                                ),
                          ),
                        );
                      },
                      child: Container(
                        height: 35.49,
                        width: 35.49,
                        padding: const EdgeInsets.fromLTRB(
                          7.28,
                          6.38,
                          7.28,
                          7.74,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(7.28),
                        ),
                        child: SvgPicture.asset('assets/images/call_icon.svg'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UserFloatingAccessBar extends StatelessWidget {
  const UserFloatingAccessBar({
    required GlobalKey<ScaffoldState> scaffoldKey,
    required this.state,
    super.key,
  }) : _scaffoldKey = scaffoldKey;
  final GlobalKey<ScaffoldState> _scaffoldKey;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              icon: SvgPicture.asset('assets/images/menu_icon.svg'),
            ),
            const HSpace(28.91),
            Container(
              width: 206,
              padding: const EdgeInsets.only(top: 5, left: 5, bottom: 5),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Color(0x23B0B0B0),
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  const BuildProfileImage(),
                  const HSpace(5),
                  Stack(
                    children: [
                      if (state.serviceStatus ==
                              LocationServiceStatus.serviceDisabled ||
                          state.serviceStatus ==
                              LocationServiceStatus.permissionDenied)
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                log('Requesting permission');
                                context.read<HomeCubit>().checkPermissionStatus(
                                  requestPermissions: true,
                                );
                              },
                              child: SvgPicture.asset(
                                'assets/images/map_location_icon.svg',
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                height: 10,
                                width: 10,
                                decoration: const ShapeDecoration(
                                  color: Colors.red,
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/error_line.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  height: 10,
                                  width: 10,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (state.serviceStatus ==
                              LocationServiceStatus.located ||
                          state.serviceStatus ==
                              LocationServiceStatus.permissionGranted)
                        SvgPicture.asset('assets/images/map_location_icon.svg'),
                    ],
                  ),
                  const HSpace(6),
                  Flexible(
                    child: Text(
                      state.userAddress ?? 'Loading...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 10.89,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const HSpace(27),
            Container(
              width: 47,
              height: 47,
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 10),
              decoration: const ShapeDecoration(
                color: Color(0xFFEBECEB),
                shape: OvalBorder(
                  side: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Colors.white,
                  ),
                ),
              ),
              child: SvgPicture.asset('assets/images/user_position.svg'),
            ),
          ],
        ),
      ),
    );
  }
}

class BuildProfileImage extends StatelessWidget {
  const BuildProfileImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profileImage',
      child: GestureDetector(
        onTap: () {
          context.read<MainActivityCubit>().navigateToScreen(3);
        },
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoaded) {
              log('Profile image loaded: ${state.user?.data.profilePicture}');
            }
            switch (state) {
              case ProfileError():
                return _buildEmptyImage();
              case ProfileLoaded():
                return CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(
                    state.user?.data.profilePicture ?? '',
                  ),
                );
              case ProfileLoading():
                return _buildEmptyImage();
              default:
                return _buildEmptyImage();
            }
          },
        ),
      ),
    );
  }
}

Widget _buildEmptyImage() {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: thickFillColor),
      borderRadius: BorderRadius.circular(50),
    ),
    child: CircleAvatar(
      radius: 10,
      backgroundColor: Colors.white,
      child: SvgPicture.asset(
        'assets/images/user.svg',
        height: 15,
        width: 15,
        fit: BoxFit.contain,
      ),
    ),
  );
}
