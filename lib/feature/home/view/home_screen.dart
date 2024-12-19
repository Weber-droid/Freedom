import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/stacked_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const LatLng sanFrancisco = LatLng(37.774546, -122.433523);
  final TextEditingController _pickUpLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final List<TextEditingController> _destinationControllers =
      <TextEditingController>[];
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _itemDestinationController =
      TextEditingController();
  final TextEditingController _itemDestinationHomeNumberController =
      TextEditingController();

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  double _containerHeight = 53;
  double _spacing = 13;
  bool hideStackedBottomSheet = false;
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
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) => print(state.locations),
        builder: (context, state) {
          return Stack(
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
                        padding:
                            const EdgeInsets.only(top: 5, left: 5, bottom: 5),
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
                            SvgPicture.asset(
                                'assets/images/map_location_icon.svg'),
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
                        child:
                            SvgPicture.asset('assets/images/user_position.svg'),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: hideStackedBottomSheet == false,
                child: Positioned(
                  top: MediaQuery.of(context).size.height * 0.47,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: stackedBottomSheet(
                      context,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
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
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                      child: LocationSearchTextField(
                                        onTap: () {
                                          _showCalenderPicker(context);
                                        },
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      height: _spacing,
                                    ),
                                    Visibility(
                                      visible: trackSelectedIndex == 2,
                                      child: AnimatedContainer(
                                        height: _containerHeight,
                                        duration:
                                            const Duration(milliseconds: 500),
                                        child: InkWell(
                                          onTap: () async {
                                            if (trackSelectedIndex == 2) {
                                              await showLogisticsBottomSheet(
                                                context,
                                                pickUpController:
                                                    _pickUpLocationController,
                                                destinationController:
                                                    _destinationController,
                                                houseNumberController:
                                                    _houseNumberController,
                                                phoneNumberController:
                                                    _phoneNumberController,
                                                itemDestinationController:
                                                    _itemDestinationController,
                                                itemDestinationHomeNumberController:
                                                    _itemDestinationHomeNumberController,
                                              );
                                            }
                                          },
                                          child:
                                              const LogisticsDetailContainer(),
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      height:
                                          trackSelectedIndex == 2 ? 4.0 : 6.0,
                                    ),
                                    Text(
                                      'Select what you want?',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 10.89,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const VSpace(10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            setState(() {
                                              trackSelectedIndex =
                                                  (trackSelectedIndex == 1)
                                                      ? 1
                                                      : 1;
                                              _containerHeight =
                                                  trackSelectedIndex == 1
                                                      ? 0
                                                      : _containerHeight;
                                              _spacing = trackSelectedIndex == 1
                                                  ? 4.0
                                                  : 13.0;
                                            });
                                            if (trackSelectedIndex == 1) {
                                              await showMotorCycleBottomSheet(
                                                context,
                                                destinationController:
                                                    _destinationController,
                                                pickUpLocationController:
                                                    _pickUpLocationController,
                                                destinationControllers:
                                                    _destinationControllers,
                                              );
                                            }
                                          },
                                          child: ChooseServiceBox(
                                            isSelected: trackSelectedIndex == 1,
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                top: 7,
                                                left: 7,
                                                bottom: 12,
                                              ),
                                              child:
                                                  ChooseServiceTextDetailsUi2(),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            setState(
                                              () {
                                                trackSelectedIndex =
                                                    (trackSelectedIndex == 2)
                                                        ? 0
                                                        : 2;
                                                _containerHeight =
                                                    trackSelectedIndex == 2
                                                        ? 53.0
                                                        : 0;
                                                _spacing =
                                                    trackSelectedIndex == 2
                                                        ? 13
                                                        : 4.0;
                                              },
                                            );
                                          },
                                          child: ChooseServiceBox(
                                            isSelected: trackSelectedIndex == 2,
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                top: 7,
                                                left: 7,
                                                bottom: 12,
                                              ),
                                              child:
                                                  ChooseServiceTextDetailsUi(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const VSpace(13),
                                    const ChoosePayMentMethod(),
                                    const VSpace(14),
                                    FreedomButton(
                                      onPressed: () {
                                        setState(() {
                                          hideStackedBottomSheet = true;
                                        });
                                        _showRiderFoundBottomSheet(context)
                                            .then((_) {
                                          if (hideStackedBottomSheet == true) {
                                            setState(() {
                                              hideStackedBottomSheet = false;
                                            });
                                          }
                                        });
                                      },
                                      title: 'Find Rider',
                                      useGradient: true,
                                      gradient: gradient,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCalenderPicker(BuildContext context) async {
    if (Platform.isAndroid) {
      final selectedDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
    } else {
      showCuperTinoDialog(
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

Future<void> _showRiderFoundBottomSheet(BuildContext context) async {
  await showModalBottomSheet<dynamic>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return const RiderFoundBottomSheet();
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

class RiderContainerAndRideActions extends StatelessWidget {
  const RiderContainerAndRideActions({
    super.key,
  });

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
                Container(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
