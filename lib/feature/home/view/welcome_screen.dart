import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 33),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSpace(164),
            Text(
              'Welcome to GoFreedom',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 35.80,
                fontWeight: FontWeight.w500,
              ),
            ),
            const VSpace(10),
            Text(
              'We are customising your Experience',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const VSpace(58),
            SvgPicture.asset('assets/images/location_icon.svg'),
          ],
        ),
      ),
    );
  }
}

class PickupLocationFieldWidget extends StatelessWidget {
  const PickupLocationFieldWidget({
    required this.state,
    required this.hintText,
    required this.iconPath,
    required this.iconBaseColor,
    required this.isPickUpLocation,
    required this.isInitialDestinationField,
    required this.pickupController,
    super.key,
  });

  final HomeState state;
  final TextEditingController pickupController;
  final String hintText;
  final String iconPath;
  final Color iconBaseColor;
  final bool isPickUpLocation;
  final bool isInitialDestinationField;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HSpace(8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: pickupController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: textFieldFillColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(6),
                    ),
                    borderSide: BorderSide(
                      color: textFieldFillColor,
                    ),
                  ),
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 10.13,
                    color: Color(0xFFBEBCBC),
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: isPickUpLocation || isInitialDestinationField
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            left: 15.5,
                            right: 7,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              context.read<HomeCubit>().removeLastDestination();
                            },
                            child: Container(
                              decoration: ShapeDecoration(
                                color: const Color(
                                  0xFFE61D2A,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/delete_field.svg',
                              ),
                            ),
                          ),
                        ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 5,
                      bottom: 7,
                      right: 10.8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: iconBaseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SvgPicture.asset(iconPath),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: thickFillColor),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DestinationLocationFieldWidget extends StatelessWidget {
  const DestinationLocationFieldWidget({
    required this.state,
    required this.destinationController,
    required this.hintText,
    required this.iconPath,
    required this.iconBaseColor,
    required this.isPickUpLocation,
    required this.isInitialDestinationField,
    super.key,
  });

  final HomeState state;
  final TextEditingController? destinationController;
  final String hintText;
  final String iconPath;
  final Color iconBaseColor;
  final bool isPickUpLocation;
  final bool isInitialDestinationField;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HSpace(8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: destinationController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: textFieldFillColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(6),
                    ),
                    borderSide: BorderSide(
                      color: textFieldFillColor,
                    ),
                  ),
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 10.13,
                    color: Color(0xFFBEBCBC),
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: isPickUpLocation || isInitialDestinationField
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            left: 15.5,
                            right: 7,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              context.read<HomeCubit>().removeLastDestination();
                            },
                            child: Container(
                              decoration: ShapeDecoration(
                                color: const Color(
                                  0xFFE61D2A,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/delete_field.svg',
                              ),
                            ),
                          ),
                        ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      left: 5,
                      bottom: 7,
                      right: 10.8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: iconBaseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SvgPicture.asset(iconPath),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: thickFillColor),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
