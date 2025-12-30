import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/view/widget/logistics_bottomsheet_content.dart';
import 'package:freedom/feature/home/view/widget/search_sheet.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/message_driver/view/message_driver_screen.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

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
        color: Theme.of(context).cardColor,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.surface),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/logistics_filter_icon.svg',
            colorFilter: ColorFilter.mode(
              Theme.of(context).iconTheme.color!,
              BlendMode.srcIn,
            ),
          ),
          const HSpace(8),
          Text(
            'Delivery Details',
            style: GoogleFonts.poppins(
              color: Theme.of(context).hintColor,
              fontSize: 10.89,
              fontWeight: FontWeight.w500,
              height: 0,
            ),
          ),
          const Spacer(),
          SvgPicture.asset(
            'assets/images/right-triangle_icon.svg',
            colorFilter: ColorFilter.mode(
              Theme.of(context).iconTheme.color!,
              BlendMode.srcIn,
            ),
          ),
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
        color: Theme.of(context).cardColor,
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
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
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
// Build section header widget
Widget buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 11.68,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    ),
  );
}

// Build location item widget
Widget buildLocationItem(
  BuildContext context, {
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              iconData,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
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
                    style: TextStyle(
                      fontSize: 10.13,
                      color: Theme.of(context).hintColor,
                    ),
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
        backgroundColor: Theme.of(context).dialogBackgroundColor,
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
                  color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.46),
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
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.surface),
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
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                        ),
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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 10.89,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Logistic',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).hintColor,
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
                          color: Theme.of(context).colorScheme.secondary,
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
                            builder: (context) => SizedBox(),
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
                          color: Theme.of(context).colorScheme.secondary,
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
                backgroundColor: Theme.of(context).colorScheme.secondary,
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
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Theme.of(context).dividerColor,
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
                              onTap: () {},
                              child: SvgPicture.asset(
                                'assets/images/map_location_icon.svg',
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  log('Requesting permission');
                                  context
                                      .read<HomeCubit>()
                                      .checkPermissionStatus(
                                        requestPermissions: true,
                                      );
                                },
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
                        color: Theme.of(context).colorScheme.onSurface,
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
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: OvalBorder(
                  side: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: Theme.of(context).cardColor,
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
                return _buildEmptyImage(context);
              case ProfileLoaded():
                final profilePicture = state.user?.data.profilePicture;

                if (profilePicture == null || profilePicture.trim().isEmpty) {
                  return const SizedBox.shrink();
                }

                return CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(profilePicture),
                  onBackgroundImageError: (exception, stackTrace) {
                    log('Error loading profile image: $exception');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: thickFillColor),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Theme.of(context).cardColor,
                      child: SvgPicture.asset(
                        'assets/images/user.svg',
                        height: 15,
                        width: 15,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              case ProfileLoading():
                return _buildEmptyImage(context);
              default:
                return _buildEmptyImage(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: thickFillColor),
        borderRadius: BorderRadius.circular(50),
      ),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: Theme.of(context).cardColor,
        child: SvgPicture.asset(
          'assets/images/user.svg',
          height: 15,
          width: 15,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
