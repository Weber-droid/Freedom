import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/location_cubit/location_cubit.dart';
import 'package:freedom/feature/home/models/home_history_model.dart';
import 'package:freedom/feature/home/view/welcome_screen.dart';
import 'package:freedom/feature/home/widgets/audio_call_widget.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/custom_dropdown_button.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class ChoosePayMentMethod extends StatefulWidget {
  const ChoosePayMentMethod({
    super.key,
  });

  @override
  State<ChoosePayMentMethod> createState() => ChoosePayMentMethodState();
}

class ChoosePayMentMethodState extends State<ChoosePayMentMethod> {
  String defaultValue = 'Personal Cash';

  final items = <String>[
    'Personal Cash',
    'Personal Card',
    'Company Cash',
    'Company Card',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 359,
      height: 70,
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
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
            ),
            value: defaultValue,
            items: items.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.poppins(color: Colors.black)),
              );
            }).toList(),
            onChanged: (val) {
              log(val.toString());
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
  const LocationSearchTextField({required this.onTap, super.key});

  final VoidCallback onTap;

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
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFFFFFF),
          ),
        ),
        fillColor: const Color(0xfffffaf0),
        filled: true,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            top: 10,
            bottom: 10,
          ),
          child: SvgPicture.asset(
            'assets/images/search_field_icon.svg',
            height: 24,
            width: 24,
          ),
        ),
        hintText: 'Your Destination, Send item',
        hintStyle: GoogleFonts.poppins(
          color: Colors.black.withOpacity(0.3499999940395355),
          fontSize: 10.89,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            right: 12,
            bottom: 9,
          ),
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
  const ChooseServiceTextDetailsUi2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/choose_bike.svg',
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [gradient1, gradient2],
          ).createShader(
            Rect.fromLTWH(
              0,
              0,
              bounds.width,
              bounds.height,
            ),
          ),
          child: Text(
            'Motorcycle',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        Text(
          'Ride with your favourite Motorcycle',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 10.89,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class ChooseServiceTextDetailsUi extends StatelessWidget {
  const ChooseServiceTextDetailsUi({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/choose_logistics.svg',
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [gradient1, gradient2],
          ).createShader(
            Rect.fromLTWH(
              0,
              0,
              bounds.width,
              bounds.height,
            ),
          ),
          child: Text(
            'Logistic',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        Text(
          'Ride with your favorite logistics',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 10.89,
            fontWeight: FontWeight.w300,
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
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isSelected
            ? GradientBoxBorder(gradient: redLinearGradient)
            : Border.all(
                color: const Color(0xFFfeebca),
              ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class LogisticsDetailContainer extends StatelessWidget {
  const LogisticsDetailContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 53,
      padding: const EdgeInsets.only(left: 15, right: 13),
      width: double.infinity,
      decoration: BoxDecoration(
        color: fillColor2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/logistics_filter_icon.svg',
          ),
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
          SvgPicture.asset(
            'assets/images/right-triangle_icon.svg',
          )
        ],
      ),
    );
  }
}

class LogisticsDetailsFields extends StatelessWidget {
  const LogisticsDetailsFields({
    required this.controller1,
    required this.controller2,
    required this.hintText,
    super.key,
  });
  final TextEditingController controller1;
  final TextEditingController controller2;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextFieldFactory.location(
              controller: controller1,
              fillColor: fillColor2,
              enabledBorderColor: Colors.white,
              hinText: hintText,
              enabledBorderRadius: const BorderRadius.all(Radius.circular(10)),
              hintTextStyle:
                  GoogleFonts.poppins(color: hintTextColor, fontSize: 11.50),
              prefixText: const LogisticsPrefixIcon(
                imageName: 'street_map',
              ),
            ),
          ),
          const HSpace(7),
          SizedBox(
            height: 53,
            width: 111,
            child: TextFieldFactory.location(
              controller: controller2,
              fillColor: fillColor2,
              enabledBorderRadius: const BorderRadius.all(Radius.circular(10)),
              enabledBorderColor: Colors.white,
              hinText: 'House Number',
              hintTextStyle: GoogleFonts.poppins(
                color: hintTextColor,
                fontSize: 11.50,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogisticsPrefixIcon extends StatelessWidget {
  const LogisticsPrefixIcon({
    super.key,
    this.imageName,
  });
  final String? imageName;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
      margin: const EdgeInsets.only(
        top: 10,
        left: 4,
        bottom: 10,
        right: 5,
      ),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          height: 547.h,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: whiteAmberGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VSpace(24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Details',
                      style: GoogleFonts.poppins(
                          fontSize: 13.22.sp, fontWeight: FontWeight.w500),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: Colors.white,
                        ),
                        child:
                            SvgPicture.asset('assets/images/cancel_icon.svg'),
                      ),
                    ),
                  ],
                ),
              ),
              const VSpace(15),
              Container(
                height: 11,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.37),
                ),
              ),
              const VSpace(15),
              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Text(
                  'Where to pick up',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 10.89,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const VSpace(7),
              LogisticsDetailsFields(
                controller1: pickUpController,
                controller2: houseNumberController,
                hintText: 'Enter Pickup Location',
              ),
              const VSpace(15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: TextFieldFactory.phone(
                  controller: phoneNumberController,
                  fillColor: fillColor2,
                  hintText: 'Enter Phone Number',
                  enabledColorBorder: Colors.white,
                  enabledBorderRadius:
                      const BorderRadius.all(Radius.circular(10)),
                  prefixText: const LogisticsPrefixIcon(
                    imageName: 'push_arrow',
                  ),
                  hintTextStyle: GoogleFonts.poppins(
                      color: hintTextColor, fontSize: 11.50),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: LogisticsPrefixIcon(
                      imageName: 'phone_icon',
                    ),
                  ),
                ),
              ),
              const VSpace(10),
              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Text(
                  'Where to deliver Item',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 10.89,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const VSpace(7),
              LogisticsDetailsFields(
                controller1: itemDestinationController,
                controller2: itemDestinationHomeNumberController,
                hintText: 'Enter Item Destination Address',
              ),
              const VSpace(12),
              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Text(
                  'Deliver What?',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 10.89,
                    fontWeight: FontWeight.w600,
                    height: 0,
                  ),
                ),
              ),
              const VSpace(4),
              Padding(
                padding: const EdgeInsets.only(left: 13, right: 20),
                child: TextFieldFactory.itemField(
                  controller: destinationController,
                  textAlignVertical: TextAlignVertical.center,
                  textAlign: TextAlign.center,
                  contentPadding: EdgeInsets.only(top: 10),
                  fillColor: fillColor2,
                  focusedBorderRadius: BorderRadius.circular(10),
                  hinText: 'Example:Big Sized Sneaker boxed nike -Red carton',
                  enabledBorderColor: Colors.white,
                  enabledBorderRadius:
                      const BorderRadius.all(Radius.circular(10)),
                  hintTextStyle: GoogleFonts.poppins(
                    color: hintTextColor,
                    fontSize: 10.18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const VSpace(25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: FreedomButton(
                  onPressed: () {},
                  buttonTitle: Text(
                    'Save Order Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  useGradient: true,
                  gradient: gradient,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

int trackSelectedIndex = 0;
bool _isDestinationFieldVisible = false;

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
      return BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
                gradient: whiteAmberGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14.32),
                  topRight: Radius.circular(14.32),
                )),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(right: 11, bottom: 11),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            strokeAlign: BorderSide.strokeAlignOutside,
                            color: Colors.black.withOpacity(0.059),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HSpace(6.4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 12, bottom: 4.62, top: 6.38),
                                child: Text(
                                  'Pickup Location',
                                  style: TextStyle(
                                    fontSize: 10.13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          PickupLocationFieldWidget(
                            state: state,
                            pickupController: pickUpLocationController,
                            hintText: 'Pickup Location',
                            iconPath: 'assets/images/location_pointer_icon.svg',
                            iconBaseColor: Colors.orange,
                            isPickUpLocation: true,
                            isInitialDestinationField: false,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: 12,
                                ),
                                child: Text(
                                  'Destination',
                                  style: TextStyle(
                                    fontSize: 10.13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  right: 9,
                                  bottom: 1,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    destinationControllers.add(
                                      TextEditingController(),
                                    );
                                    context.read<HomeCubit>().addDestination();
                                    _isDestinationFieldVisible = true;
                                  },
                                  child: Container(
                                    width: 23,
                                    height: 23,
                                    decoration: ShapeDecoration(
                                      color: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const VSpace(3),
                          DestinationLocationFieldWidget(
                            isPickUpLocation: false,
                            isInitialDestinationField: true,
                            state: state,
                            destinationController: destinationController,
                            hintText: 'Destination',
                            iconPath: 'assets/images/maps_icon.svg',
                            iconBaseColor: Colors.red,
                          ),
                          const VSpace(14),
                          if (_isDestinationFieldVisible)
                            Column(
                              children: List.generate(state.locations.length,
                                  (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: DestinationLocationFieldWidget(
                                    isPickUpLocation: false,
                                    isInitialDestinationField: false,
                                    state: state,
                                    destinationController:
                                        destinationControllers[index],
                                    hintText: 'Destination ${index + 1}',
                                    iconPath: 'assets/images/maps_icon.svg',
                                    iconBaseColor: Colors.red,
                                  ),
                                );
                              }),
                            )
                          else
                            const SizedBox(),
                        ],
                      ),
                    ),
                    const VSpace(19.65),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your last Trip',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 11.68,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SvgPicture.asset('assets/images/history_icon.svg'),
                      ],
                    ),
                    ...homeHistoryList.map((e) {
                      return Column(
                        children: [
                          Divider(
                            thickness: 2,
                            color: Colors.black.withOpacity(0.019),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                width: 30,
                                height: 30,
                                decoration: ShapeDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: e.image,
                              ),
                              SvgPicture.asset(
                                'assets/images/top-right_icon.svg',
                              )
                            ],
                          ),
                        ],
                      );
                    }),
                    Divider(
                      thickness: 2,
                      color: Colors.black.withOpacity(0.019),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
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
        child: SafeArea(
          top: false,
          child: child,
        ),
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
              SvgPicture.asset(
                'assets/images/emergency_icon.svg',
              ),
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
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        )),
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
                  decoration: BoxDecoration(
                    gradient: gradient,
                  ),
                  child: TextButton(
                    onPressed: confirm,
                    style: TextButton.styleFrom(),
                    child: Text(confirmText,
                        style: GoogleFonts.poppins(
                          fontSize: 12.06,
                          color: Colors.white,
                        )),
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
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(
            height: 349.h,
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
            top: 39.h,
            child: Container(
              height: 310.h,
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
                  const RiderContainerAndRideActions(),
                  const VSpace(14),
                  Container(
                    decoration: BoxDecoration(
                      color: fillColor2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 10, 6, 17.78),
                    margin: EdgeInsets.symmetric(horizontal: 13.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Route',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 11.51,
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                        // const Spacer(),
                        const RiderTimeLine(
                          pickUpDetails: 'Ghana, Kumasi',
                          destinationDetails: 'Chale ,Kumasi',
                        ),
                      ],
                    ),
                  ),
                  const VSpace(47),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: FreedomButton(
                      onPressed: () {
                        showAlertDialog(
                          context,
                          title: 'Cancel Ride',
                          cancel: () {
                            return Navigator.pop(context);
                          },
                          message: 'Are you sure you want to cancel the ride?',
                          confirm: () {
                            Navigator.pop(context);
                          },
                        );
                      },
                      useGradient: true,
                      gradient: gradient,
                      title: 'Cancel Ride',
                      buttonTitle: Text(
                        'Cancel Ride',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 9,
            left: 14,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 28,
              child: Row(
                children: [
                  const Image(
                    image: AssetImage('assets/images/jump-time_icon.png'),
                  ),
                  const HSpace(3),
                  const Text(
                    'The rider will arrive in ....',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/images/clock_icon.svg'),
                        const HSpace(4),
                        Text(
                          '08:12 Mins',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.76,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    });
  }
}

class RiderTimeLine extends StatelessWidget {
  const RiderTimeLine({
    super.key,
    this.destinationDetails = '',
    this.pickUpDetails = '',
  });
  final String destinationDetails;
  final String pickUpDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset('assets/images/distance_line.svg'),
        const VSpace(5),
        SizedBox(
          width: 200,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick up',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 8.78,
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return darkGoldGradient.createShader(bounds);
                        },
                        child: Text(
                          pickUpDetails,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF59E0B),
                            fontSize: 9.07,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const HSpace(41),
              Expanded(
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 8.78,
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return darkGoldGradient.createShader(bounds);
                        },
                        child: Text(
                          destinationDetails,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF59E0B),
                            fontSize: 9.07,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class RiderContainerAndRideActions extends StatefulWidget {
  const RiderContainerAndRideActions({
    super.key,
  });

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
        decoration: BoxDecoration(
          color: fillColor2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white,
          ),
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
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/rider_image.png',
                      ),
                    ),
                  ),
                ),
                const HSpace(6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Holland Chale ',
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
                Container(
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
                const SizedBox(width: 7.4), // Space between icons
                // Second Icon
                GestureDetector(
                  onTap: () {
                    final callId =
                        'call_MWCHb02GD5m6_${DateTime.now().millisecondsSinceEpoch}';
                    Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                        builder: (context) => AudioCallScreen(
                          callId: callId,
                          driverName: 'Holland Chale',
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
                    child: SvgPicture.asset(
                      'assets/images/call_icon.svg',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserFloatingAccessBar extends StatelessWidget {
  const UserFloatingAccessBar(
      {required GlobalKey<ScaffoldState> scaffoldKey,
      required this.state,
      super.key})
      : _scaffoldKey = scaffoldKey;
  final GlobalKey<ScaffoldState> _scaffoldKey;
  final LocationState state;

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
                                context
                                    .read<LocationCubit>()
                                    .checkPermissionStatus(
                                        requestPermissions: true);
                              },
                              child: SvgPicture.asset(
                                  'assets/images/map_location_icon.svg'),
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
                                      Colors.white, BlendMode.srcIn),
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
                      state?.userAddress ?? 'Loading...',
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
            switch (state) {
              case ProfileError():
                return _buildEmptyImage();
              case ProfileLoaded():
                return CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      NetworkImage(state.user?.data.profilePicture ?? ''),
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
      border: Border.all(
        color: thickFillColor,
      ),
      borderRadius: BorderRadius.circular(50),
    ),
    child: CircleAvatar(
      radius: 10,
      backgroundColor: Colors.white,
      child: SvgPicture.asset('assets/images/user.svg',
          height: 15, width: 15, fit: BoxFit.contain),
    ),
  );
}
