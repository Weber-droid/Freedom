import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/custom_dropdown_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const LatLng sanFrancisco = LatLng(37.774546, -122.433523);

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(),
      ),
      body: Stack(
        children: [
          const GoogleMap(
            initialCameraPosition: CameraPosition(
              target: sanFrancisco,
              zoom: 13,
            ),
          ),
          Positioned(
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
                        SvgPicture.asset('assets/images/map_user.svg'),
                        const HSpace(5),
                        SvgPicture.asset('assets/images/map_location_icon.svg'),
                        const HSpace(6),
                        Flexible(
                          child: Text(
                            'Kumasi ,Ghana Kuwama',
                            maxLines: 2,
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
          ),
          stackedBottomSheet(
            context,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VSpace(17),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const VSpace(13),
                  Text(
                    'Where would you like to go?',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 10.89,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const VSpace(8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xA3FFFCF8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEBECEB),
                      ),
                    ),
                    child: TextField(
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        fillColor: const Color(0xfffffaf0),
                        filled: true,
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.transparent,
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
                                _showCalenderPicker(context);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VSpace(6),
                  Text(
                    'Select what you want?',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 10.89,
                      fontWeight: FontWeight.w600,
                      height: 0,
                    ),
                  ),
                  const VSpace(10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          trackSelectedIndex =
                              (trackSelectedIndex == 1) ? 0 : 1;
                        }),
                        child: ChooseServiceBox(
                          isSelected: trackSelectedIndex == 1,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 7,
                              left: 7,
                              bottom: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                    'assets/images/choose_bike.svg'),
                                const VSpace(9),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                          colors: [gradient1, gradient2])
                                      .createShader(
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
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const HSpace(10),
                      GestureDetector(
                        onTap: () => setState(() {
                          trackSelectedIndex =
                              (trackSelectedIndex == 2) ? 0 : 2;
                        }),
                        child: ChooseServiceBox(
                          isSelected: trackSelectedIndex == 2,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 7, left: 7, bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                    'assets/images/choose_logistics.svg'),
                                const VSpace(9),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                          colors: [gradient1, gradient2])
                                      .createShader(Rect.fromLTWH(
                                          0, 0, bounds.width, bounds.height)),
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
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const VSpace(13),
                  const _ChoosePayMentMethod(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalenderPicker(BuildContext context) async {
    if (Platform.isAndroid) {
      final selectedDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
    } else {
      _showCuperTinoDialog(
        context,
        child: CupertinoDatePicker(
          initialDateTime: DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          use24hFormat: true,
          showDayOfWeek: true,
          onDateTimeChanged: (DateTime newDate) {
            // setState(());
          },
        ),
      );
    }
  }
}

class _ChoosePayMentMethod extends StatelessWidget {
  const _ChoosePayMentMethod({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 359,
      height: 70,
      decoration: ShapeDecoration(
        color: const Color(0xA3FFFCF8),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
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
                top: 8.98, left: 9.88, bottom: 9.01, right: 9.88),
            decoration: ShapeDecoration(
              color: const Color(0x38F4950D),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1.76, color: Colors.white),
                borderRadius: BorderRadius.circular(12.35),
              ),
            ),
            child: SvgPicture.asset('assets/images/pay_with_cash.svg'),
          ),
        ],
      ),
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

Widget stackedBottomSheet(
  BuildContext context,
  Widget child,
) {
  return DraggableScrollableSheet(
    initialChildSize: 0.47,
    minChildSize: 0.47,
    maxChildSize: 0.8,
    builder: (context, scrollController) {
      return SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF2DD), Color(0xFFFCFCFC)],
            ),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.60,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: Colors.white,
              ),
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

void _showCuperTinoDialog(BuildContext context, {required Widget child}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system
        // navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      );
    },
  );
}
