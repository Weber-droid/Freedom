import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/models/home_history_model.dart';
import 'package:freedom/feature/home/view/welcome_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/custom_dropdown_button.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
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

Widget stackedBottomSheet(
  BuildContext context,
  Widget child,
) {
  return DraggableScrollableSheet(
    minChildSize: 0.5,
    builder: (context, scrollController) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF2DD), Color(0xFFFCFCFC)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.32),
                topRight: Radius.circular(14.32),
              ),
            ),
            child: IntrinsicHeight(child: child),
          ),
        ),
      );
    },
  );
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
                  title: 'Save Order Details',
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
